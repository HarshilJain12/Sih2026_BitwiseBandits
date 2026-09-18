import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/record_id_generator.dart';
import 'package:healthcare_app/services/storage/local_medical_record_storage.dart';

void main() {
  group('LocalMedicalRecordStorage tests', () {
    late Directory tempDir;
    late LocalMedicalRecordStorage storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'sih_medical_records_test_',
      );
      storage = LocalMedicalRecordStorage(customBaseDirectory: tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      '1 & 3: Patient ID is used for patient-scoped local storage path',
      () async {
        const patientId = 'P-1G9I7YHB2H';
        const recordId = 'MR-ABC123XYZ0';
        const fileName = 'blood_report.pdf';
        final bytes = Uint8List.fromList(
          'Fictional sample medical report content'.codeUnits,
        );

        final result = await storage.uploadBytes(
          patientId: patientId,
          recordId: recordId,
          originalFileName: fileName,
          bytes: bytes,
        );

        expect(
          result.storagePath,
          'patients/P-1G9I7YHB2H/medicalRecords/MR-ABC123XYZ0/blood_report.pdf',
        );
        expect(result.storageType, 'local');
        expect(result.fileSizeBytes, bytes.length);
        expect(result.localFile, isNotNull);
        expect(await result.localFile!.exists(), isTrue);

        // Verify physical path contains patientId
        expect(result.localFile!.path.contains('P-1G9I7YHB2H'), isTrue);
      },
    );

    test(
      '2: Two different Patient IDs produce separate isolated directories',
      () async {
        const patientA = 'P-AAAA111111';
        const patientB = 'P-BBBB222222';
        const recordIdA = 'MR-RECA000001';
        const recordIdB = 'MR-RECB000002';

        final bytesA = Uint8List.fromList(
          'Patient A Fictional Prescription'.codeUnits,
        );
        final bytesB = Uint8List.fromList(
          'Patient B Fictional Lab Report'.codeUnits,
        );

        final resultA = await storage.uploadBytes(
          patientId: patientA,
          recordId: recordIdA,
          originalFileName: 'report.pdf',
          bytes: bytesA,
        );

        final resultB = await storage.uploadBytes(
          patientId: patientB,
          recordId: recordIdB,
          originalFileName: 'report.pdf',
          bytes: bytesB,
        );

        // Verify distinct paths
        expect(resultA.storagePath, isNot(equals(resultB.storagePath)));
        expect(resultA.localFile!.path, isNot(equals(resultB.localFile!.path)));

        // Verify isolated directories on disk
        final dirA = Directory('${tempDir.path}/patients/$patientA');
        final dirB = Directory('${tempDir.path}/patients/$patientB');
        expect(await dirA.exists(), isTrue);
        expect(await dirB.exists(), isTrue);
      },
    );

    test('4: Record IDs are unique across multiple uploads', () async {
      const generator = RecordIdGenerator();
      final ids = <String>{};

      for (int i = 0; i < 50; i++) {
        final id = generator.generate();
        expect(ids.contains(id), isFalse);
        ids.add(id);
      }
      expect(ids.length, 50);
    });

    test(
      '5: File names are sanitized against path traversal and special chars',
      () async {
        const patientId = 'P-1G9I7YHB2H';
        const recordId = 'MR-ABC123XYZ0';
        final bytes = Uint8List.fromList('sample document'.codeUnits);

        final result = await storage.uploadBytes(
          patientId: patientId,
          recordId: recordId,
          originalFileName: '../../dangerous:file*name?.pdf',
          bytes: bytes,
        );

        expect(result.storagePath.contains('..'), isFalse);
        expect(result.storagePath.contains(':'), isFalse);
        expect(result.storagePath.contains('*'), isFalse);
        expect(result.storagePath.contains('?'), isFalse);
        expect(await storage.fileExists(result.storagePath), isTrue);
      },
    );

    test('6: PDF, JPG, JPEG, and PNG formats are supported', () async {
      const patientId = 'P-1G9I7YHB2H';
      final dummyBytes = Uint8List.fromList('sample dummy content'.codeUnits);

      final pdfRes = await storage.uploadBytes(
        patientId: patientId,
        recordId: 'MR-0000000001',
        originalFileName: 'test.pdf',
        bytes: dummyBytes,
      );
      expect(pdfRes.mimeType, 'application/pdf');

      final jpgRes = await storage.uploadBytes(
        patientId: patientId,
        recordId: 'MR-0000000002',
        originalFileName: 'test.jpg',
        bytes: dummyBytes,
      );
      expect(jpgRes.mimeType, 'image/jpeg');

      final jpegRes = await storage.uploadBytes(
        patientId: patientId,
        recordId: 'MR-0000000003',
        originalFileName: 'test.jpeg',
        bytes: dummyBytes,
      );
      expect(jpegRes.mimeType, 'image/jpeg');

      final pngRes = await storage.uploadBytes(
        patientId: patientId,
        recordId: 'MR-0000000004',
        originalFileName: 'test.png',
        bytes: dummyBytes,
      );
      expect(pngRes.mimeType, 'image/png');
    });

    test(
      '7: Files over 10 MB or 0 bytes are rejected with ArgumentError',
      () async {
        const patientId = 'P-1G9I7YHB2H';
        const recordId = 'MR-ABC123XYZ0';

        // 0 bytes
        expect(
          () => storage.uploadBytes(
            patientId: patientId,
            recordId: recordId,
            originalFileName: 'empty.pdf',
            bytes: Uint8List(0),
          ),
          throwsA(isA<ArgumentError>()),
        );

        // 10 MB + 1 byte (10,485,761 bytes)
        final largeBytes = Uint8List(10 * 1024 * 1024 + 1);
        expect(
          () => storage.uploadBytes(
            patientId: patientId,
            recordId: recordId,
            originalFileName: 'large.pdf',
            bytes: largeBytes,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      '8 & 9: Local upload and retrieval succeed with identical bytes',
      () async {
        const patientId = 'P-1G9I7YHB2H';
        const recordId = 'MR-ABC123XYZ0';
        const sampleText = 'Fictional Clinical Summary for SIH 2026';
        final originalBytes = Uint8List.fromList(sampleText.codeUnits);

        final uploadResult = await storage.uploadBytes(
          patientId: patientId,
          recordId: recordId,
          originalFileName: 'clinical_summary.pdf',
          bytes: originalBytes,
        );

        // File exists
        final exists = await storage.fileExists(uploadResult.storagePath);
        expect(exists, isTrue);

        // Retrieve File handle
        final file = await storage.getFile(uploadResult.storagePath);
        expect(file, isNotNull);
        expect(await file!.exists(), isTrue);

        // Retrieve raw bytes
        final retrievedBytes = await storage.getFileBytes(
          uploadResult.storagePath,
        );
        expect(retrievedBytes, isNotNull);
        expect(retrievedBytes, equals(originalBytes));
      },
    );

    test('10: Local deletion removes physical file from disk', () async {
      const patientId = 'P-1G9I7YHB2H';
      const recordId = 'MR-ABC123XYZ0';
      final bytes = Uint8List.fromList('Fictional record to delete'.codeUnits);

      final uploadResult = await storage.uploadBytes(
        patientId: patientId,
        recordId: recordId,
        originalFileName: 'to_delete.pdf',
        bytes: bytes,
      );

      expect(await storage.fileExists(uploadResult.storagePath), isTrue);

      // Delete file
      await storage.deleteFile(uploadResult.storagePath);

      // Verify file is gone
      expect(await storage.fileExists(uploadResult.storagePath), isFalse);
      final fileAfter = await storage.getFile(uploadResult.storagePath);
      expect(fileAfter, isNull);
    });

    test(
      '14: Local records survive new service instantiation (persisted on disk)',
      () async {
        const patientId = 'P-1G9I7YHB2H';
        const recordId = 'MR-ABC123XYZ0';
        final bytes = Uint8List.fromList(
          'Preserved across app restarts'.codeUnits,
        );

        final uploadResult = await storage.uploadBytes(
          patientId: patientId,
          recordId: recordId,
          originalFileName: 'restart_test.pdf',
          bytes: bytes,
        );

        // Simulate app restart by creating a brand new storage instance pointing to same directory
        final newStorageInstance = LocalMedicalRecordStorage(
          customBaseDirectory: tempDir,
        );

        final existsAfterRestart = await newStorageInstance.fileExists(
          uploadResult.storagePath,
        );
        expect(existsAfterRestart, isTrue);

        final readBytes = await newStorageInstance.getFileBytes(
          uploadResult.storagePath,
        );
        expect(readBytes, equals(bytes));
      },
    );
  });
}
