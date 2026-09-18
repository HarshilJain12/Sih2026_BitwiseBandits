import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/patient.dart';
import 'package:healthcare_app/models/patient_location.dart';

void main() {
  group('Patient model tests', () {
    test('toFirestore creates correct Map structure with location', () {
      final now = DateTime(2026, 9, 18, 2, 30);
      final patient = Patient(
        patientId: 'P-1234567890',
        ownerUid: 'uid_test_999',
        name: 'Ramesh Sharma',
        phoneNumber: '+919876543210',
        age: 35,
        weightKg: 72.5,
        heightCm: 175.0,
        location: const PatientLocation(
          source: 'gps',
          latitude: 18.5204,
          longitude: 73.8567,
        ),
        createdAt: now,
        updatedAt: now,
        status: 'active',
      );

      final map = patient.toFirestore();
      expect(map['patientId'], equals('P-1234567890'));
      expect(map['ownerUid'], equals('uid_test_999'));
      expect(map['name'], equals('Ramesh Sharma'));
      expect(map['phoneNumber'], equals('+919876543210'));
      expect(map['age'], equals(35));
      expect(map['weightKg'], equals(72.5));
      expect(map['heightCm'], equals(175.0));
      expect(map['status'], equals('active'));
      expect(map['location'], isA<Map<String, dynamic>>());
      expect(map['location']['source'], equals('gps'));
      expect(map['location']['latitude'], equals(18.5204));
      expect(map['location']['longitude'], equals(73.8567));
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), equals(now));
    });

    test(
      'toFirestore omits optional fields when null (backward compatibility)',
      () {
        final now = DateTime(2026, 9, 18, 2, 30);
        final patient = Patient(
          patientId: 'P-1234567890',
          ownerUid: 'uid_test_999',
          name: 'Ramesh Sharma',
          phoneNumber: '+919876543210',
          createdAt: now,
          updatedAt: now,
        );

        final map = patient.toFirestore();
        expect(map.containsKey('age'), isFalse);
        expect(map.containsKey('weightKg'), isFalse);
        expect(map.containsKey('heightCm'), isFalse);
        expect(map.containsKey('location'), isFalse);
      },
    );

    test('copyWith updates new and existing fields including location', () {
      final now = DateTime(2026, 9, 18, 2, 30);
      final patient = Patient(
        patientId: 'P-1234567890',
        ownerUid: 'uid_test_999',
        name: 'Ramesh Sharma',
        phoneNumber: '+919876543210',
        age: 30,
        weightKg: 65.0,
        heightCm: 170.0,
        createdAt: now,
        updatedAt: now,
      );

      const location = PatientLocation(
        source: 'manual',
        village: 'Baramati',
        district: 'Pune',
        state: 'Maharashtra',
        pincode: '413102',
      );

      final updated = patient.copyWith(
        name: 'Ramesh Kumar',
        age: 31,
        weightKg: 68.0,
        location: location,
      );
      expect(updated.patientId, equals('P-1234567890'));
      expect(updated.name, equals('Ramesh Kumar'));
      expect(updated.ownerUid, equals('uid_test_999'));
      expect(updated.age, equals(31));
      expect(updated.weightKg, equals(68.0));
      expect(updated.heightCm, equals(170.0));
      expect(updated.location, equals(location));
    });

    test('equality operator compares patientId', () {
      final now = DateTime.now();
      final p1 = Patient(
        patientId: 'P-1111111111',
        ownerUid: 'uid_1',
        name: 'User 1',
        phoneNumber: '+919876543210',
        createdAt: now,
        updatedAt: now,
      );
      final p2 = Patient(
        patientId: 'P-1111111111',
        ownerUid: 'uid_2',
        name: 'User 2',
        phoneNumber: '+911111111111',
        createdAt: now,
        updatedAt: now,
      );
      final p3 = Patient(
        patientId: 'P-2222222222',
        ownerUid: 'uid_1',
        name: 'User 1',
        phoneNumber: '+919876543210',
        createdAt: now,
        updatedAt: now,
      );

      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });
  });
}
