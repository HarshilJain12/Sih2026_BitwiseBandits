import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/appointment.dart';
import '../../models/asha_worker.dart';
import '../../models/awareness_campaign.dart';
import '../../models/community_health_alert.dart';
import '../../models/hospital_doctor.dart';
import '../../models/patient.dart';
import 'asha_data_service.dart';
import 'hospital_local_demo_store.dart';

/// Aggregates hospital-wide data for the Hospital Admin dashboard:
/// patients, doctors, OPD queue/appointments, field staff and alerts.
///
/// Mirrors [AshaDataService]: when Firestore is unreachable or denies access
/// (hospital admin signs in via mock auth, so it often has no Firebase user),
/// every method transparently serves the built-in [HospitalLocalDemoStore].
class HospitalAdminService {
  HospitalAdminService({AshaDataService? ashaDataService})
      : _asha = ashaDataService ?? AshaDataService();

  final AshaDataService _asha;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool localDemoMode = false;
  final HospitalLocalDemoStore localStore = HospitalLocalDemoStore();

  /// In-memory day-duty toggles (there is no `/doctors` collection).
  final Map<String, bool> _dutyOverrides = {};

  void enableLocalDemo() {
    localDemoMode = true;
    localStore.reset();
  }

  void disableLocalDemo() {
    localDemoMode = false;
  }

  /// Static staff directory (mirrors the mock auth staff list).
  static const List<HospitalDoctor> staffDirectory = [
    HospitalDoctor(
        doctorId: 'DOC001', name: 'Rajesh Sharma',
        specialization: 'General Medicine', phone: '+91 9810010011'),
    HospitalDoctor(
        doctorId: 'DOC002', name: 'Priya Mehta',
        specialization: 'Pediatrics', phone: '+91 9810010012'),
    HospitalDoctor(
        doctorId: 'DOC003', name: 'Amit Deshmukh',
        specialization: 'Orthopedics', phone: '+91 9810010013'),
    HospitalDoctor(
        doctorId: 'DOC004', name: 'Sneha Kulkarni',
        specialization: 'Gynecology', phone: '+91 9810010014'),
  ];

  static Future<T> _guard<T>(Future<T> operation, String opName) {
    return operation.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception(
        'Firestore "$opName" timed out. Check internet connection and Firestore rules.',
      ),
    );
  }

  // ─── Overview ────────────────────────────────────────────────────────
  Future<Map<String, int>> getOverviewStats() async {
    if (localDemoMode) return localStore.overview();
    final appointments = await getAllAppointments();
    final patients = await getAllPatients();
    final doctors = await getDoctors();
    final queue = appointments
        .where((a) =>
            a.isToday && (a.status == 'upcoming' || a.status == 'current'))
        .toList();
    final completedToday = appointments
        .where((a) => a.isToday && a.status == 'completed')
        .length;
    final alerts = await getPendingAlerts();
    final workers = await getWorkers();
    final campaigns = await getCampaigns();
    return {
      'totalPatients': patients.length,
      'totalDoctors': doctors.length,
      'doctorsOnDuty': doctors.where((d) => d.onDuty).length,
      'todayAppointments': queue.length + completedToday,
      'opdWaiting': queue.where((a) => a.status == 'upcoming').length,
      'opdInConsultation': queue.where((a) => a.status == 'current').length,
      'completedToday': completedToday,
      'pendingAlerts': alerts.length,
      'activeAshaWorkers': workers.length,
      'publishedCampaigns':
          campaigns.where((c) => c.status == 'published').length,
    };
  }

  // ─── Appointments / OPD queue ────────────────────────────────────────
  Future<List<Appointment>> getAllAppointments() async {
    if (localDemoMode) return localStore.allAppointments();
    final snap = await _guard(
      _db.collection('appointments').get(),
      'fetch appointments',
    );
    final list =
        snap.docs.map((d) => Appointment.fromFirestore(d)).toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  Future<List<Appointment>> getTodayQueue() async {
    final all = await getAllAppointments();
    final queue = all
        .where((a) =>
            a.isToday && (a.status == 'upcoming' || a.status == 'current'))
        .toList();
    queue.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return queue;
  }

  Future<List<Appointment>> getTodayCompleted() async {
    final all = await getAllAppointments();
    return all.where((a) => a.isToday && a.status == 'completed').toList();
  }

  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    if (localDemoMode) {
      localStore.updateStatus(appointmentId, status);
      return;
    }
    await _guard(
      _db.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
      'update appointment status',
    );
  }

  /// Moves the next waiting token into consultation (one "current" per doctor).
  Future<void> callNext(String doctorId) async {
    if (localDemoMode) {
      localStore.callNext(doctorId);
      return;
    }
    final queue = await getTodayQueue();
    final waiting = queue
        .where((a) => a.doctorId == doctorId && a.status == 'upcoming')
        .toList();
    if (waiting.isEmpty) return;
    await updateAppointmentStatus(waiting.first.appointmentId, 'current');
  }

  // ─── Doctors ─────────────────────────────────────────────────────────
  Future<List<HospitalDoctor>> getDoctors() async {
    if (localDemoMode) return localStore.roster();
    final roster = {for (final d in staffDirectory) d.doctorId: d};
    try {
      final appointments = await getAllAppointments();
      final today = DateTime.now();
      final load = <String, int>{};
      for (final a in appointments) {
        if (a.scheduledAt.year == today.year &&
            a.scheduledAt.month == today.month &&
            a.scheduledAt.day == today.day) {
          load[a.doctorId] = (load[a.doctorId] ?? 0) + 1;
        }
        roster.putIfAbsent(
          a.doctorId,
          () => HospitalDoctor(
            doctorId: a.doctorId,
            name: a.doctorName.isEmpty ? a.doctorId : a.doctorName,
            specialization: 'General Medicine',
          ),
        );
      }
      return roster.values
          .map((d) => d.copyWith(
                onDuty: _dutyOverrides[d.doctorId] ?? true,
                todayLoad: load[d.doctorId] ?? 0,
              ))
          .toList();
    } catch (e) {
      debugPrint('[HospitalAdminService] doctor roster fallback: $e');
      return roster.values
          .map((d) => d.copyWith(
              onDuty: _dutyOverrides[d.doctorId] ?? true))
          .toList();
    }
  }

  Future<void> setDoctorDuty(String doctorId, bool onDuty) async {
    _dutyOverrides[doctorId] = onDuty;
    if (localDemoMode) localStore.setDuty(doctorId, onDuty);
  }

  // ─── Patients ────────────────────────────────────────────────────────
  Future<List<Patient>> getAllPatients() async {
    if (localDemoMode) return List.of(localStore.patients);
    final snap = await _guard(
      _db.collection('patients').limit(200).get(),
      'fetch patients',
    );
    return snap.docs.map((d) => Patient.fromFirestore(d)).toList();
  }

  Future<List<Patient>> searchPatients(String query) async {
    final all = await getAllPatients();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.patientId.toLowerCase().contains(q) ||
            p.phoneNumber.contains(q))
        .toList();
  }

  // ─── Field staff / alerts / campaigns ────────────────────────────────
  Future<List<AshaWorker>> getWorkers() async {
    if (localDemoMode) return List.of(localStore.workers);
    final snap = await _guard(
      _db.collection('asha_workers').limit(100).get(),
      'fetch ASHA workers',
    );
    return snap.docs.map((d) => AshaWorker.fromFirestore(d)).toList();
  }

  Future<List<CommunityHealthAlert>> getPendingAlerts() async {
    if (localDemoMode) return localStore.pendingAlerts();
    return _asha.getPendingAlerts();
  }

  Future<List<CommunityHealthAlert>> getAllAlerts() async {
    if (localDemoMode) return localStore.allAlerts();
    return _asha.getAllAlerts();
  }

  Future<void> updateAlertStatus(String alertId, String status) async {
    if (localDemoMode) {
      localStore.updateAlertStatus(alertId, status);
      return;
    }
    return _asha.updateAlertStatus(alertId, status);
  }

  Future<List<AwarenessCampaign>> getCampaigns() async {
    if (localDemoMode) return List.of(localStore.campaigns);
    try {
      return await _asha.getPublishedCampaigns();
    } catch (e) {
      debugPrint('[HospitalAdminService] campaigns fallback: $e');
      return [];
    }
  }
}
