import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/appointment.dart';

/// Service for managing appointments in `/appointments/{appointmentId}`.
///
/// Provides real Firestore-backed data for the Doctor Dashboard.
class AppointmentService {
  AppointmentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _prefix = 'APT-';
  static const int _suffixLength = 10;
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _firestore.collection('appointments');

  /// Generates a unique appointment ID.
  String _generateId() {
    final rng = Random.secure();
    final suffix = String.fromCharCodes(
      Iterable.generate(
        _suffixLength,
        (_) => _chars.codeUnitAt(rng.nextInt(_chars.length)),
      ),
    );
    return '$_prefix$suffix';
  }

  /// Retrieves all appointments for a specific doctor.
  Future<List<Appointment>> getAppointmentsForDoctor(String doctorId) async {
    try {
      if (kDebugMode) {
        final auth = FirebaseAuth.instance.currentUser;
        debugPrint('[AppointmentService] Current user: ${auth?.uid}');
        if (auth != null) {
          try {
            final acc = await _firestore.collection('accounts').doc(auth.uid).get();
            debugPrint('[AppointmentService] Account doc exists: ${acc.exists}, role: ${acc.data()?['role']}');
          } catch (e) {
            debugPrint('[AppointmentService] Failed to read account doc: $e');
          }
        }
      }

      final snapshot = await _appointmentsRef
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final list = snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
          
      // Sort locally to avoid requiring a Firestore composite index
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      
      return list;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppointmentService] Error fetching appointments: $e');
      }
      rethrow;
    }
  }

  /// Returns only appointments for today that are upcoming or current.
  Future<List<Appointment>> getCurrentAppointments(String doctorId) async {
    final all = await getAppointmentsForDoctor(doctorId);
    return all.where((a) => a.isCurrent).toList();
  }

  /// Returns the total count of all appointments for a doctor.
  Future<int> getTotalAppointmentCount(String doctorId) async {
    final all = await getAppointmentsForDoctor(doctorId);
    return all.length;
  }

  /// Seeds realistic appointment data if the doctor has none yet.
  ///
  /// This ensures the dashboard shows real Firestore data from the first login.
  /// Only creates appointments if none exist for this doctor.
  Future<void> seedDefaultAppointmentsIfEmpty({
    required String doctorId,
    required String doctorName,
  }) async {
    try {
      final existing = await _appointmentsRef
          .where('doctorId', isEqualTo: doctorId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) return; // Already has appointments

      // Fetch actual patients from Firestore to create realistic appointments
      final patientsSnapshot = await _firestore
          .collection('patients')
          .limit(10)
          .get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final batch = _firestore.batch();

      // If real patients exist, create appointments for them
      if (patientsSnapshot.docs.isNotEmpty) {
        for (var i = 0; i < patientsSnapshot.docs.length && i < 8; i++) {
          final patientData = patientsSnapshot.docs[i].data();
          final patientId = patientData['patientId'] as String? ?? patientsSnapshot.docs[i].id;
          final patientName = patientData['name'] as String? ?? 'Patient';

          final hour = 9 + i; // 9 AM, 10 AM, etc.
          final scheduledAt = today.add(Duration(hours: hour));

          final status = i < 2 ? 'completed' : (i < 5 ? 'current' : 'upcoming');
          final types = ['consultation', 'follow_up', 'routine_checkup'];

          final apt = Appointment(
            appointmentId: _generateId(),
            patientId: patientId,
            patientName: patientName,
            doctorId: doctorId,
            doctorName: doctorName,
            scheduledAt: scheduledAt,
            status: status,
            type: types[i % types.length],
            createdAt: now,
          );

          batch.set(
            _appointmentsRef.doc(apt.appointmentId),
            apt.toFirestore(useServerTimestamp: true),
          );
        }
      } else {
        // No real patients — create minimal sample appointments
        final sampleNames = ['Rahul Kumar', 'Anjali Singh', 'Priya Patil', 'Suresh Jadhav', 'Meena Deshmukh'];
        for (var i = 0; i < sampleNames.length; i++) {
          final hour = 9 + i;
          final scheduledAt = today.add(Duration(hours: hour));
          final status = i < 1 ? 'completed' : (i < 3 ? 'current' : 'upcoming');

          final patientId = 'P-SAMPLE${i.toString().padLeft(5, '0')}';
          
          // Seed the fake patient so search works!
          final patientData = {
            'patientId': patientId,
            'ownerUid': 'demo-owner',
            'name': sampleNames[i],
            'phoneNumber': '999999999$i',
            'age': 30 + i,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          batch.set(
            _firestore.collection('patients').doc(patientId),
            patientData,
          );

          final apt = Appointment(
            appointmentId: _generateId(),
            patientId: patientId,
            patientName: sampleNames[i],
            doctorId: doctorId,
            doctorName: doctorName,
            scheduledAt: scheduledAt,
            status: status,
            type: 'consultation',
            createdAt: now,
          );

          batch.set(
            _appointmentsRef.doc(apt.appointmentId),
            apt.toFirestore(useServerTimestamp: true),
          );
        }
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint('[AppointmentService] Seeded default appointments for doctor $doctorId.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppointmentService] Error seeding appointments: $e');
      }
      // Non-fatal: dashboard will show "No appointments" instead
    }
  }
}
