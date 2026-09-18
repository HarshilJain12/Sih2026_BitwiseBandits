import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/medical_record.dart';

void main() {
  group('MedicalRecord model tests', () {
    final testDate = DateTime(2026, 9, 18, 14, 30);

    final sampleRecord = MedicalRecord(
      recordId: 'MR-ABC123XYZ0',
      patientId: 'P-1234567890',
      ownerUid: 'uid_test_123',
      originalFileName: 'blood_test.pdf',
      storagePath:
          'patients/P-1234567890/medicalRecords/MR-ABC123XYZ0/blood_test.pdf',
      storageType: 'local',
      downloadUrl: 'https://firebasestorage.googleapis.com/test',
      mimeType: 'application/pdf',
      fileSizeBytes: 2048576,
      uploadedAt: testDate,
      updatedAt: testDate,
      status: 'uploaded',
      category: 'lab_report',
      notes: 'Fasting blood glucose report',
    );

    test('toFirestore creates correct Map structure with Timestamp and storageType', () {
      final map = sampleRecord.toFirestore();

      expect(map['recordId'], 'MR-ABC123XYZ0');
      expect(map['patientId'], 'P-1234567890');
      expect(map['ownerUid'], 'uid_test_123');
      expect(map['originalFileName'], 'blood_test.pdf');
      expect(
        map['storagePath'],
        'patients/P-1234567890/medicalRecords/MR-ABC123XYZ0/blood_test.pdf',
      );
      expect(map['storageType'], 'local');
      expect(map['downloadUrl'], 'https://firebasestorage.googleapis.com/test');
      expect(map['mimeType'], 'application/pdf');
      expect(map['fileSizeBytes'], 2048576);
      expect(map['status'], 'uploaded');
      expect(map['category'], 'lab_report');
      expect(map['notes'], 'Fasting blood glucose report');
      expect(map['uploadedAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('toFirestore handles null optional fields gracefully and defaults storageType', () {
      final minimalRecord = MedicalRecord(
        recordId: 'MR-MIN1234567',
        patientId: 'P-MIN1234567',
        ownerUid: 'uid_min',
        originalFileName: 'scan.jpg',
        storagePath:
            'patients/P-MIN1234567/medicalRecords/MR-MIN1234567/scan.jpg',
        mimeType: 'image/jpeg',
        fileSizeBytes: 102400,
        uploadedAt: testDate,
        updatedAt: testDate,
      );

      final map = minimalRecord.toFirestore();

      expect(map.containsKey('downloadUrl'), isFalse);
      expect(map.containsKey('category'), isFalse);
      expect(map.containsKey('notes'), isFalse);
      expect(map['recordId'], 'MR-MIN1234567');
      expect(map['storageType'], 'local');
      expect(map['mimeType'], 'image/jpeg');
    });

    test('fromMap parses map correctly with ISO strings and storageType', () {
      final map = <String, dynamic>{
        'recordId': 'MR-ABC123XYZ0',
        'patientId': 'P-1234567890',
        'ownerUid': 'uid_test_123',
        'originalFileName': 'prescription.png',
        'storagePath': 'patients/P-1234567890/medicalRecords/MR-ABC123XYZ0/prescription.png',
        'storageType': 'local',
        'downloadUrl': null,
        'mimeType': 'image/png',
        'fileSizeBytes': 512000,
        'uploadedAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
        'status': 'uploaded',
        'category': 'prescription',
      };

      final record = MedicalRecord.fromMap(map);

      expect(record.recordId, 'MR-ABC123XYZ0');
      expect(record.patientId, 'P-1234567890');
      expect(record.storageType, 'local');
      expect(record.mimeType, 'image/png');
      expect(record.fileSizeBytes, 512000);
      expect(record.category, 'prescription');
      expect(record.downloadUrl, isNull);
      expect(record.notes, isNull);
    });

    test('fromMap parses map correctly with Firestore Timestamps', () {
      final map = <String, dynamic>{
        'recordId': 'MR-ABC123XYZ0',
        'patientId': 'P-1234567890',
        'ownerUid': 'uid_test_123',
        'originalFileName': 'prescription.png',
        'storagePath': 'patients/P-1234567890/medicalRecords/MR-ABC123XYZ0/prescription.png',
        'storageType': 'firebase',
        'mimeType': 'image/png',
        'fileSizeBytes': 512000,
        'uploadedAt': Timestamp.fromDate(testDate),
        'updatedAt': Timestamp.fromDate(testDate),
        'status': 'uploaded',
      };

      final record = MedicalRecord.fromMap(map);

      expect(record.uploadedAt, testDate);
      expect(record.updatedAt, testDate);
      expect(record.storageType, 'firebase');
    });

    test('copyWith updates specified fields only', () {
      final updated = sampleRecord.copyWith(
        status: 'archived',
        notes: 'Updated notes',
        storageType: 'firebase',
      );

      expect(updated.status, 'archived');
      expect(updated.notes, 'Updated notes');
      expect(updated.storageType, 'firebase');
      expect(updated.recordId, sampleRecord.recordId);
      expect(updated.patientId, sampleRecord.patientId);
      expect(updated.storagePath, sampleRecord.storagePath);
    });

    test('equality operator compares all core fields', () {
      final duplicate = sampleRecord.copyWith();
      expect(duplicate, equals(sampleRecord));
      expect(duplicate.hashCode, equals(sampleRecord.hashCode));

      final different = sampleRecord.copyWith(recordId: 'MR-DIFFERENT1');
      expect(different, isNot(equals(sampleRecord)));
    });
  });
}
