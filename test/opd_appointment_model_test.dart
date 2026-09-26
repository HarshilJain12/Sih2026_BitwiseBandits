import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/opd_appointment.dart';

void main() {
  group('OpdAppointment Model Unit Tests', () {
    final now = DateTime(2026, 9, 26, 16, 20);

    test('1. Creates registered patient OPD appointment correctly with patientId and qrLinked = true', () {
      final appt = OpdAppointment(
        appointmentId: 'OPD-1002938471',
        hospitalId: 'ADMIN001',
        patientId: 'P-1002938471',
        patientName: 'Harshil Jain',
        patientAge: 22,
        doctorCategory: 'Cardiology',
        appointmentDate: now,
        appointmentTime: '04:20 PM',
        patientType: 'registered',
        qrLinked: true,
        qrPayload: 'P-1002938471',
        createdAt: now,
      );

      expect(appt.appointmentId, 'OPD-1002938471');
      expect(appt.hospitalId, 'ADMIN001');
      expect(appt.patientId, 'P-1002938471');
      expect(appt.patientName, 'Harshil Jain');
      expect(appt.patientAge, 22);
      expect(appt.doctorCategory, 'Cardiology');
      expect(appt.patientType, 'registered');
      expect(appt.qrLinked, isTrue);
      expect(appt.isRegistered, isTrue);
      expect(appt.isWalkIn, isFalse);
      expect(appt.qrPayload, 'P-1002938471');
    });

    test('2. Creates walk-in OPD appointment with no patientId and qrLinked = false', () {
      final walkIn = OpdAppointment(
        appointmentId: 'OPD-1002938499',
        hospitalId: 'ADMIN001',
        patientId: null,
        patientName: 'Rahul Walkin',
        patientAge: 34,
        patientGender: 'Male',
        doctorCategory: 'General Medicine',
        appointmentDate: now,
        appointmentTime: '04:25 PM',
        patientType: 'walk_in',
        qrLinked: false,
        qrPayload: null,
        createdAt: now,
      );

      expect(walkIn.patientId, isNull);
      expect(walkIn.qrLinked, isFalse);
      expect(walkIn.isWalkIn, isTrue);
      expect(walkIn.isRegistered, isFalse);
      expect(walkIn.qrPayload, isNull);
      expect(walkIn.patientGender, 'Male');
    });

    test('3. Serializes to and from Firestore map seamlessly', () {
      final original = OpdAppointment(
        appointmentId: 'OPD-888',
        hospitalId: 'ADMIN001',
        patientId: 'P-12345',
        patientName: 'Sunita Patil',
        patientAge: 28,
        patientGender: 'Female',
        doctorCategory: 'Gynecology',
        appointmentDate: now,
        appointmentTime: '11:00 AM',
        patientType: 'registered',
        qrLinked: true,
        qrPayload: 'P-12345',
        createdAt: now,
      );

      final map = original.toFirestore();
      expect(map['appointmentId'], 'OPD-888');
      expect(map['patientName'], 'Sunita Patil');
      expect(map['doctorCategory'], 'Gynecology');
      expect(map['patientType'], 'registered');
      expect(map['qrLinked'], isTrue);

      final parsed = OpdAppointment.fromMap(map);
      expect(parsed.appointmentId, original.appointmentId);
      expect(parsed.patientName, original.patientName);
      expect(parsed.doctorCategory, original.doctorCategory);
      expect(parsed.patientAge, original.patientAge);
      expect(parsed.qrLinked, original.qrLinked);
    });

    test('4. copyWith updates fields properly without mutating original', () {
      final original = OpdAppointment(
        appointmentId: 'OPD-1',
        hospitalId: 'ADMIN001',
        patientName: 'Initial',
        doctorCategory: 'Pediatrics',
        appointmentDate: now,
        appointmentTime: '10:00 AM',
        createdAt: now,
      );

      final updated = original.copyWith(
        doctorCategory: 'Orthopedics',
        patientAge: 40,
        doctorId: 'DOC003',
      );

      expect(updated.doctorCategory, 'Orthopedics');
      expect(updated.patientAge, 40);
      expect(updated.doctorId, 'DOC003');
      expect(original.doctorCategory, 'Pediatrics');
    });
  });
}
