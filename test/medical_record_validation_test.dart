import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/storage/medical_record_storage.dart';

void main() {
  group('MedicalRecordStorage validation tests', () {
    test('buildStoragePath constructs correct isolated path', () {
      final path = MedicalRecordStorage.buildStoragePath(
        patientId: 'P-1234567890',
        recordId: 'MR-ABC123XYZ0',
        fileName: 'prescription.pdf',
      );

      expect(
        path,
        'patients/P-1234567890/medicalRecords/MR-ABC123XYZ0/prescription.pdf',
      );
    });

    test('sanitizeFileName removes invalid and traversal characters', () {
      expect(
        MedicalRecordStorage.sanitizeFileName('my report (1).pdf'),
        'my_report_(1).pdf',
      );
      expect(
        MedicalRecordStorage.sanitizeFileName('../../../etc/passwd'),
        'etc_passwd',
      );
      expect(
        MedicalRecordStorage.sanitizeFileName('test:file*name?.jpg'),
        'test_file_name_.jpg',
      );
      expect(
        MedicalRecordStorage.sanitizeFileName('   '),
        'document.bin',
      );
    });

    test('resolveMimeType detects correct MIME from extensions', () {
      expect(
        MedicalRecordStorage.resolveMimeType('scan.pdf'),
        'application/pdf',
      );
      expect(
        MedicalRecordStorage.resolveMimeType('photo.jpg'),
        'image/jpeg',
      );
      expect(
        MedicalRecordStorage.resolveMimeType('photo.jpeg'),
        'image/jpeg',
      );
      expect(
        MedicalRecordStorage.resolveMimeType('xray.png'),
        'image/png',
      );
      expect(
        MedicalRecordStorage.resolveMimeType('scan.PDF'),
        'application/pdf',
      );
      expect(
        MedicalRecordStorage.resolveMimeType('unknown.docx'),
        'application/octet-stream',
      );
    });

    test('isValidMimeType checks whitelisted types accurately', () {
      expect(MedicalRecordStorage.isValidMimeType('application/pdf'), isTrue);
      expect(MedicalRecordStorage.isValidMimeType('image/jpeg'), isTrue);
      expect(MedicalRecordStorage.isValidMimeType('image/jpg'), isTrue);
      expect(MedicalRecordStorage.isValidMimeType('image/png'), isTrue);

      // Disallowed types
      expect(MedicalRecordStorage.isValidMimeType('application/zip'), isFalse);
      expect(MedicalRecordStorage.isValidMimeType('application/x-msdownload'), isFalse);
      expect(MedicalRecordStorage.isValidMimeType('text/plain'), isFalse);
      expect(MedicalRecordStorage.isValidMimeType('application/octet-stream'), isFalse);
    });

    test('isValidFileSize enforces 10 MB maximum limit', () {
      const tenMB = 10 * 1024 * 1024; // 10,485,760 bytes

      expect(MedicalRecordStorage.isValidFileSize(1), isTrue);
      expect(MedicalRecordStorage.isValidFileSize(1024), isTrue);
      expect(
        MedicalRecordStorage.isValidFileSize(5 * 1024 * 1024),
        isTrue,
      );
      expect(MedicalRecordStorage.isValidFileSize(tenMB), isTrue);

      // Out of bounds
      expect(MedicalRecordStorage.isValidFileSize(0), isFalse);
      expect(MedicalRecordStorage.isValidFileSize(-1), isFalse);
      expect(MedicalRecordStorage.isValidFileSize(tenMB + 1), isFalse);
      expect(
        MedicalRecordStorage.isValidFileSize(20 * 1024 * 1024),
        isFalse,
      );
    });
  });
}
