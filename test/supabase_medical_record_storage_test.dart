import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/record_id_generator.dart';
import 'package:healthcare_app/services/storage/medical_record_storage.dart';

void main() {
  group('SupabaseMedicalRecordStorage & MedicalRecordStorage Path/Validation Tests', () {
    const testUid = 'P5CeG63YI8UQ4BRQs8MfTGGJ9sX2';
    const testPatientId = 'P-1G9I7YHB2H';
    const testRecordId = 'MR-ABC123XYZ0';

    test('1. Canonical Storage Path format: {firebaseUid}/{patientId}/{recordId}/{fileName}', () {
      final path = MedicalRecordStorage.buildStoragePath(
        ownerUid: testUid,
        patientId: testPatientId,
        recordId: testRecordId,
        fileName: 'blood_report.pdf',
      );

      expect(
        path,
        equals('P5CeG63YI8UQ4BRQs8MfTGGJ9sX2/P-1G9I7YHB2H/MR-ABC123XYZ0/blood_report.pdf'),
      );

      // Verify Firebase UID is top-level folder
      final segments = path.split('/');
      expect(segments.length, equals(4));
      expect(segments[0], equals(testUid));
      expect(segments[1], equals(testPatientId));
      expect(segments[2], equals(testRecordId));
      expect(segments[3], equals('blood_report.pdf'));
    });

    test('2. Two different Firebase UIDs produce completely isolated top-level namespaces', () {
      const uidA = 'UID_ALICE_1111111111111111111';
      const uidB = 'UID_BOB_22222222222222222222';
      const patientId = 'P-COMMON1234';
      const recordId = 'MR-REC9999999';

      final pathA = MedicalRecordStorage.buildStoragePath(
        ownerUid: uidA,
        patientId: patientId,
        recordId: recordId,
        fileName: 'report.pdf',
      );

      final pathB = MedicalRecordStorage.buildStoragePath(
        ownerUid: uidB,
        patientId: patientId,
        recordId: recordId,
        fileName: 'report.pdf',
      );

      expect(pathA.startsWith(uidA), isTrue);
      expect(pathB.startsWith(uidB), isTrue);
      expect(pathA.startsWith(uidB), isFalse);
      expect(pathB.startsWith(uidA), isFalse);
    });

    test('3. Sanitize file names against path traversal and special characters', () {
      expect(
        MedicalRecordStorage.sanitizeFileName('my report (1).pdf'),
        equals('my_report_(1).pdf'),
      );
      expect(
        MedicalRecordStorage.sanitizeFileName('../../../etc/passwd.pdf'),
        equals('etc_passwd.pdf'),
      );
      expect(
        MedicalRecordStorage.sanitizeFileName('..\\..\\secret.png'),
        equals('secret.png'),
      );
      expect(
        MedicalRecordStorage.sanitizeFileName('test:file*name?.jpg'),
        equals('test_file_name_.jpg'),
      );
      expect(
        MedicalRecordStorage.sanitizeFileName('   '),
        equals('document.bin'),
      );
      expect(
        MedicalRecordStorage.sanitizeFileName(''),
        equals('document.bin'),
      );
    });

    test('4. Resolve and validate allowed MIME types (PDF, JPG, JPEG, PNG)', () {
      expect(MedicalRecordStorage.resolveMimeType('scan.pdf'), equals('application/pdf'));
      expect(MedicalRecordStorage.resolveMimeType('photo.jpg'), equals('image/jpeg'));
      expect(MedicalRecordStorage.resolveMimeType('photo.jpeg'), equals('image/jpeg'));
      expect(MedicalRecordStorage.resolveMimeType('xray.png'), equals('image/png'));
      expect(MedicalRecordStorage.resolveMimeType('scan.PDF'), equals('application/pdf'));
      expect(MedicalRecordStorage.resolveMimeType('unknown.docx'), equals('application/octet-stream'));

      expect(MedicalRecordStorage.isValidMimeType('application/pdf'), isTrue);
      expect(MedicalRecordStorage.isValidMimeType('image/jpeg'), isTrue);
      expect(MedicalRecordStorage.isValidMimeType('image/jpg'), isTrue);
      expect(MedicalRecordStorage.isValidMimeType('image/png'), isTrue);

      expect(MedicalRecordStorage.isValidMimeType('application/zip'), isFalse);
      expect(MedicalRecordStorage.isValidMimeType('application/x-msdownload'), isFalse);
      expect(MedicalRecordStorage.isValidMimeType('text/plain'), isFalse);
      expect(MedicalRecordStorage.isValidMimeType('application/octet-stream'), isFalse);
    });

    test('5. Validate file size within 10 MB limit', () {
      const tenMB = 10 * 1024 * 1024; // 10,485,760 bytes

      expect(MedicalRecordStorage.isValidFileSize(1), isTrue);
      expect(MedicalRecordStorage.isValidFileSize(1024), isTrue);
      expect(MedicalRecordStorage.isValidFileSize(5 * 1024 * 1024), isTrue);
      expect(MedicalRecordStorage.isValidFileSize(tenMB), isTrue);

      expect(MedicalRecordStorage.isValidFileSize(0), isFalse);
      expect(MedicalRecordStorage.isValidFileSize(-1), isFalse);
      expect(MedicalRecordStorage.isValidFileSize(tenMB + 1), isFalse);
      expect(MedicalRecordStorage.isValidFileSize(20 * 1024 * 1024), isFalse);
    });

    test('6. Record ID Generator produces unique MR-XXXXXXXXXX IDs', () {
      const generator = RecordIdGenerator();
      final ids = <String>{};

      for (int i = 0; i < 50; i++) {
        final id = generator.generate();
        expect(id.startsWith('MR-'), isTrue);
        expect(id.length, equals(13));
        expect(RecordIdGenerator.isValidFormat(id), isTrue);
        expect(ids.contains(id), isFalse);
        ids.add(id);
      }
    });

    test('7. StorageUploadResult model encapsulates Supabase storage result', () {
      const result = StorageUploadResult(
        storagePath: 'P5CeG63YI8UQ4BRQs8MfTGGJ9sX2/P-1G9I7YHB2H/MR-ABC123XYZ0/blood_report.pdf',
        fileSizeBytes: 2048,
        mimeType: 'application/pdf',
        storageType: 'supabase',
        downloadUrl: 'https://ezjecnfrrkgehsabzgrg.supabase.co/storage/v1/object/sign/medical-records/P5CeG63YI8UQ4BRQs8MfTGGJ9sX2/P-1G9I7YHB2H/MR-ABC123XYZ0/blood_report.pdf?token=xyz',
      );

      expect(result.storageType, equals('supabase'));
      expect(result.fileSizeBytes, equals(2048));
      expect(result.mimeType, equals('application/pdf'));
      expect(result.downloadUrl, contains('sign/medical-records'));
      expect(result.localFile, isNull);
    });
  });
}
