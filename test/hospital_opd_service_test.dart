import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/opd_appointment.dart';
import 'package:healthcare_app/services/firestore/hospital_admin_service.dart';
import 'package:healthcare_app/services/firestore/hospital_local_demo_store.dart';
import 'package:healthcare_app/services/printing/opd_slip_print_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hospital OPD Service & Store Tests', () {
    late HospitalLocalDemoStore store;
    late HospitalAdminService service;

    setUp(() {
      store = HospitalLocalDemoStore()..reset();
      service = HospitalAdminService()..enableLocalDemo();
    });

    test('1. Search existing patient by name finds matching patient', () {
      final results = store.searchPatients('Harshil');
      expect(results.length, greaterThanOrEqualTo(2));
      for (final p in results) {
        expect(p.name.toLowerCase(), contains('harshil'));
      }
    });

    test('2. Multiple patients with same name are returned separately with distinct mobile numbers', () {
      final results = store.searchPatients('Harshil Jain');
      expect(results.length, 2);
      expect(results[0].name, 'Harshil Jain');
      expect(results[1].name, 'Harshil Jain');
      // Differentiated by mobile number & ID
      expect(results[0].phoneNumber, isNot(equals(results[1].phoneNumber)));
      expect(results[0].patientId, isNot(equals(results[1].patientId)));
    });

    test('3. Selecting an existing patient preserves name, age, and existing QR token', () {
      final patient = store.patients.firstWhere((p) => p.name == 'Harshil Jain');
      expect(patient.name, 'Harshil Jain');
      expect(patient.age, isNotNull);
      expect(patient.qrToken, isNotNull);
      expect(patient.qrToken, contains('QRT-'));
    });

    test('4. Existing patient QR is reused and linked, not randomly regenerated', () {
      final patient = store.patients.firstWhere((p) => p.patientId == 'P-1002938479');
      final originalQr = patient.qrToken;

      final opd = OpdAppointment(
        appointmentId: 'OPD-001',
        hospitalId: 'ADMIN001',
        patientId: patient.patientId,
        patientName: patient.name,
        patientAge: patient.age,
        doctorCategory: 'General Medicine',
        appointmentDate: DateTime.now(),
        appointmentTime: '04:20 PM',
        patientType: 'registered',
        qrLinked: true,
        qrPayload: originalQr,
        createdAt: DateTime.now(),
      );

      final created = store.createOpdAppointment(opd);
      expect(created.patientId, patient.patientId);
      expect(created.qrPayload, originalQr);
      expect(created.qrLinked, isTrue);
    });

    test('5. Doctor categories are retrieved from hospital specializations and standard departments', () async {
      final categories = await service.getDoctorCategories();
      expect(categories, contains('General Medicine'));
      expect(categories, contains('Cardiology'));
      expect(categories, contains('Pediatrics'));
      expect(categories, contains('Orthopedics'));
      expect(categories, contains('Gynecology'));
      expect(categories, contains('Dermatology'));
      expect(categories, contains('ENT'));
      expect(categories, contains('Dentistry'));
      expect(categories, contains('Ophthalmology'));
      expect(categories, contains('General Surgery'));
    });

    test('6. OPD appointment record is saved and mirrored to queue', () async {
      final beforeQueue = store.todayQueue().length;
      final beforeOpd = store.allOpdAppointments().length;

      final appt = OpdAppointment(
        appointmentId: 'OPD-TEST-123',
        hospitalId: 'ADMIN001',
        patientId: 'P-1002938471',
        patientName: 'Rahul Kumar',
        patientAge: 34,
        doctorCategory: 'General Medicine',
        appointmentDate: DateTime.now(),
        appointmentTime: '04:30 PM',
        patientType: 'registered',
        qrLinked: true,
        qrPayload: 'P-1002938471',
        createdAt: DateTime.now(),
      );

      final created = await service.createOpdAppointment(appt);
      expect(created.appointmentId, 'OPD-TEST-123');

      final afterQueue = store.todayQueue().length;
      final afterOpd = store.allOpdAppointments().length;

      expect(afterOpd, beforeOpd + 1);
      expect(afterQueue, beforeQueue + 1);
    });

    test('7. Walk-in patient appointment is created without patientId and qrLinked = false', () async {
      final walkIn = OpdAppointment(
        appointmentId: 'OPD-WALKIN-1',
        hospitalId: 'ADMIN001',
        patientId: null,
        patientName: 'New Walkin Patient',
        patientAge: 42,
        patientGender: 'Female',
        doctorCategory: 'Dermatology',
        appointmentDate: DateTime.now(),
        appointmentTime: '04:45 PM',
        patientType: 'walk_in',
        qrLinked: false,
        qrPayload: null,
        createdAt: DateTime.now(),
      );

      final created = await service.createOpdAppointment(walkIn);
      expect(created.patientId, isNull);
      expect(created.qrLinked, isFalse);
      expect(created.isWalkIn, isTrue);
      expect(created.patientGender, 'Female');
    });

    test('8. OpdSlipPrintService generates PDF bytes for registered patient with QR', () async {
      const printService = OpdSlipPrintService();
      final appt = OpdAppointment(
        appointmentId: 'OPD-PRINT-1',
        hospitalId: 'ADMIN001',
        patientId: 'P-1002938471',
        patientName: 'Harshil Jain',
        patientAge: 22,
        doctorCategory: 'Cardiology',
        appointmentDate: DateTime.now(),
        appointmentTime: '04:20 PM',
        patientType: 'registered',
        qrLinked: true,
        qrPayload: 'P-1002938471',
        createdAt: DateTime.now(),
      );

      final bytes = await printService.generateSlipPdf(appt);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('9. OpdSlipPrintService generates PDF bytes for walk-in patient without QR', () async {
      const printService = OpdSlipPrintService();
      final walkIn = OpdAppointment(
        appointmentId: 'OPD-PRINT-2',
        hospitalId: 'ADMIN001',
        patientId: null,
        patientName: 'Walkin Test',
        patientAge: 30,
        patientGender: 'Male',
        doctorCategory: 'Orthopedics',
        appointmentDate: DateTime.now(),
        appointmentTime: '04:30 PM',
        patientType: 'walk_in',
        qrLinked: false,
        qrPayload: null,
        createdAt: DateTime.now(),
      );

      final bytes = await printService.generateSlipPdf(walkIn);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });
  });
}
