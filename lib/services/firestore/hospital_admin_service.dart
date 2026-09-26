import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/appointment.dart';
import '../../models/asha_worker.dart';
import '../../models/awareness_campaign.dart';
import '../../models/community_health_alert.dart';
import '../../models/hospital_doctor.dart';
import '../../models/opd_appointment.dart';
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
  HospitalAdminService({
    AshaDataService? ashaDataService,
    FirebaseFirestore? firestore,
  })  : _ashaInstance = ashaDataService,
        _firestore = firestore;

  final AshaDataService? _ashaInstance;
  AshaDataService get _asha => _ashaInstance ?? AshaDataService();
  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

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

  /// Standard and hospital specialty categories for OPD slips.
  static const List<String> defaultDoctorCategories = [
    'General Medicine',
    'Pediatrics',
    'Orthopedics',
    'Gynecology',
    'Cardiology',
    'Dermatology',
    'ENT',
    'Dentistry',
    'Ophthalmology',
    'General Surgery',
  ];

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

  // ─── OPD Appointment Slips ───────────────────────────────────────────
  Future<OpdAppointment> createOpdAppointment(OpdAppointment appointment) async {
    if (localDemoMode) {
      return localStore.createOpdAppointment(appointment);
    }

    try {
      final hospitalId = appointment.hospitalId.isEmpty ? 'ADMIN001' : appointment.hospitalId;
      final apptId = appointment.appointmentId.isEmpty
          ? 'OPD-${DateTime.now().millisecondsSinceEpoch}'
          : appointment.appointmentId;
      final savedAppt = appointment.copyWith(appointmentId: apptId, hospitalId: hospitalId);

      // Save to /hospitals/{hospitalId}/opdAppointments/{appointmentId}
      await _guard(
        _db
            .collection('hospitals')
            .doc(hospitalId)
            .collection('opdAppointments')
            .doc(apptId)
            .set(savedAppt.toFirestore(useServerTimestamp: true)),
        'create OPD slip',
      );

      // Also mirror to /appointments/{appointmentId} for queue & doctor dashboard
      final assignedDoctorId = savedAppt.doctorId ?? 'DOC001';
      final assignedDoctorName = savedAppt.doctorName ?? savedAppt.doctorCategory;
      final generalApt = Appointment(
        appointmentId: apptId,
        patientId: savedAppt.patientId ?? 'WALK_IN_${DateTime.now().millisecondsSinceEpoch}',
        patientName: savedAppt.patientName,
        doctorId: assignedDoctorId,
        doctorName: assignedDoctorName,
        scheduledAt: savedAppt.appointmentDate,
        status: savedAppt.status,
        type: 'opd_slip',
        notes: savedAppt.doctorCategory,
        createdAt: savedAppt.createdAt,
      );

      try {
        await _guard(
          _db.collection('appointments').doc(apptId).set(
                generalApt.toFirestore(useServerTimestamp: true),
              ),
          'sync appointment to queue',
        );
      } catch (e) {
        debugPrint('[HospitalAdminService] Mirroring appointment non-fatal error: $e');
      }

      return savedAppt;
    } catch (e) {
      debugPrint('[HospitalAdminService] Firestore error in createOpdAppointment, saving to local store: $e');
      localDemoMode = true;
      return localStore.createOpdAppointment(appointment);
    }
  }

  Future<List<OpdAppointment>> getOpdAppointments({String hospitalId = 'ADMIN001'}) async {
    if (localDemoMode) return localStore.allOpdAppointments();
    try {
      final snap = await _guard(
        _db
            .collection('hospitals')
            .doc(hospitalId)
            .collection('opdAppointments')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get(),
        'fetch OPD appointments',
      );
      return snap.docs.map((d) => OpdAppointment.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('[HospitalAdminService] getOpdAppointments fallback: $e');
      return localStore.allOpdAppointments();
    }
  }

  Future<List<OpdAppointment>> getTodayOpdAppointments({String hospitalId = 'ADMIN001'}) async {
    final all = await getOpdAppointments(hospitalId: hospitalId);
    final now = DateTime.now();
    return all.where((a) {
      return a.appointmentDate.year == now.year &&
          a.appointmentDate.month == now.month &&
          a.appointmentDate.day == now.day;
    }).toList();
  }

  Future<List<String>> getDoctorCategories() async {
    final doctors = await getDoctors();
    final categories = <String>{};
    for (final d in doctors) {
      if (d.specialization.trim().isNotEmpty) {
        categories.add(d.specialization.trim());
      }
    }
    // Add standard categories to ensure full hospital department options
    categories.addAll(defaultDoctorCategories);
    return categories.toList();
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
    try {
      final snap = await _guard(
        _db.collection('patients').limit(200).get(),
        'fetch patients',
      );
      return snap.docs.map((d) => Patient.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('[HospitalAdminService] getAllPatients error: $e');
      return List.of(localStore.patients);
    }
  }

  Future<List<Patient>> searchPatients(String query) async {
    final all = await getAllPatients();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    final cleanQ = q.replaceAll(' ', '');
    return all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.patientId.toLowerCase().contains(q) ||
            p.phoneNumber.replaceAll(' ', '').contains(cleanQ))
        .toList();
  }

  /// Searches registered patients from Firebase or local demo store.
  ///
  /// Matches on patient name, patient ID, or phone number.
  /// Works for both live Firestore registered patients (with patientId and QR)
  /// and local demo patients (fallback).
  Future<List<Patient>> searchRegisteredPatients(String query) async {
    final q = query.trim().toLowerCase();
    List<Patient> list = [];

    // ALWAYS query Firestore first — even if localDemoMode was set as a dashboard fallback,
    // real registered patients must always be searchable.
    try {
      final snap = await _db
          .collection('patients')
          .limit(200)
          .get()
          .timeout(const Duration(seconds: 4));
      list = snap.docs
          .map((d) => Patient.fromFirestore(d))
          .where((p) => p.status == 'active' || p.status.isEmpty)
          .toList();
    } catch (e) {
      debugPrint('[HospitalAdminService] Firestore server fetch failed, checking cache: $e');
      try {
        final cacheSnap = await _db
            .collection('patients')
            .limit(200)
            .get(const GetOptions(source: Source.cache));
        list = cacheSnap.docs
            .map((d) => Patient.fromFirestore(d))
            .where((p) => p.status == 'active' || p.status.isEmpty)
            .toList();
      } catch (cacheErr) {
        debugPrint('[HospitalAdminService] Cache read error: $cacheErr');
      }
    }

    // Only load demo store if Firestore returned NO patients at all AND in localDemoMode
    if (list.isEmpty && localDemoMode) {
      final demoList = localStore.patients
          .where((p) => p.status == 'active' || p.status.isEmpty)
          .toList();
      list.addAll(demoList);
    }

    if (q.isEmpty) return list;
    final cleanQ = q.replaceAll(' ', '');
    return list
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.patientId.toLowerCase().contains(q) ||
            p.phoneNumber.replaceAll(' ', '').contains(cleanQ))
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
