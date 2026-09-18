import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/account.dart';

void main() {
  group('Account model tests', () {
    test('toFirestore creates correct Map structure', () {
      final now = DateTime(2026, 9, 18, 2, 30);
      final account = Account(
        firebaseUid: 'test_uid_123',
        phoneNumber: '+919876543210',
        createdAt: now,
        updatedAt: now,
        accountType: 'patient',
      );

      final map = account.toFirestore();
      expect(map['firebaseUid'], equals('test_uid_123'));
      expect(map['phoneNumber'], equals('+919876543210'));
      expect(map['accountType'], equals('patient'));
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), equals(now));
    });

    test('copyWith updates specified fields only', () {
      final now = DateTime(2026, 9, 18, 2, 30);
      final account = Account(
        firebaseUid: 'test_uid_123',
        phoneNumber: '+919876543210',
        createdAt: now,
        updatedAt: now,
      );

      final updated = account.copyWith(phoneNumber: '+919999999999');
      expect(updated.firebaseUid, equals('test_uid_123'));
      expect(updated.phoneNumber, equals('+919999999999'));
      expect(updated.createdAt, equals(now));
    });

    test('equality operator compares firebaseUid', () {
      final now = DateTime.now();
      final account1 = Account(
        firebaseUid: 'uid_1',
        phoneNumber: '+919876543210',
        createdAt: now,
        updatedAt: now,
      );
      final account2 = Account(
        firebaseUid: 'uid_1',
        phoneNumber: '+911111111111',
        createdAt: now,
        updatedAt: now,
      );
      final account3 = Account(
        firebaseUid: 'uid_2',
        phoneNumber: '+919876543210',
        createdAt: now,
        updatedAt: now,
      );

      expect(account1, equals(account2));
      expect(account1, isNot(equals(account3)));
    });
  });
}
