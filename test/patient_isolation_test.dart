import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/storage/local_medical_record_storage.dart';
import 'package:healthcare_app/services/storage/medical_record_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testBaseDir;
  late LocalMedicalRecordStorage storage;

  setUp(() async {
    testBaseDir = await Directory.systemTemp.createTemp('patient_isolation_test_');
    storage = LocalMedicalRecordStorage(customBaseDirectory: testBaseDir);
  });

  tearDown(() async {
    if (await testBaseDir.exists()) {
      await testBaseDir.delete(recursive: true);
    }
  });

  group('Critical Patient Isolation Tests', () {
    const patientA = 'P-AAAA111111';
    const patientB = 'P-BBBB222222';
    const recordA = 'MR-AAAA000001';
    const recordB = 'MR-BBBB000002';

    test('Patient A upload is isolated in Patient A directory and inaccessible to Patient B', () async {
      final bytesA = Uint8List.fromList([1, 2, 3, 4, 5]);
      final uploadResultA = await storage.uploadBytes(
        patientId: patientA,
        recordId: recordA,
        originalFileName: 'patient_a_prescription.pdf',
        bytes: bytesA,
        mimeType: 'application/pdf',
      );

      expect(uploadResultA.storagePath, contains('patients/$patientA/medicalRecords/$recordA'));
      expect(uploadResultA.storagePath, isNot(contains(patientB)));

      // Verify file exists at Patient A path
      expect(await storage.fileExists(uploadResultA.storagePath), isTrue);

      // Verify Patient B path with same record ID does NOT exist
      final simulatedPathB = MedicalRecordStorage.buildStoragePath(
        patientId: patientB,
        recordId: recordA,
        fileName: 'patient_a_prescription.pdf',
      );
      expect(await storage.fileExists(simulatedPathB), isFalse);
      expect(await storage.getFileBytes(simulatedPathB), isNull);
    });

    test('Patient B upload is isolated in Patient B directory and inaccessible to Patient A', () async {
      final bytesB = Uint8List.fromList([10, 20, 30, 40]);
      final uploadResultB = await storage.uploadBytes(
        patientId: patientB,
        recordId: recordB,
        originalFileName: 'patient_b_blood_test.png',
        bytes: bytesB,
        mimeType: 'image/png',
      );

      expect(uploadResultB.storagePath, contains('patients/$patientB/medicalRecords/$recordB'));
      expect(uploadResultB.storagePath, isNot(contains(patientA)));

      // Verify file exists at Patient B path
      expect(await storage.fileExists(uploadResultB.storagePath), isTrue);

      // Verify Patient A path with record B does NOT exist
      final simulatedPathA = MedicalRecordStorage.buildStoragePath(
        patientId: patientA,
        recordId: recordB,
        fileName: 'patient_b_blood_test.png',
      );
      expect(await storage.fileExists(simulatedPathA), isFalse);
      expect(await storage.getFileBytes(simulatedPathA), isNull);
    });

    test('Both patients have independent directories on disk without overlap', () async {
      final bytesA = Uint8List.fromList('Patient A Document'.codeUnits);
      final bytesB = Uint8List.fromList('Patient B Document'.codeUnits);

      final resA = await storage.uploadBytes(
        patientId: patientA,
        recordId: recordA,
        originalFileName: 'doc.pdf',
        bytes: bytesA,
      );

      final resB = await storage.uploadBytes(
        patientId: patientB,
        recordId: recordB,
        originalFileName: 'doc.pdf',
        bytes: bytesB,
      );

      final readA = await storage.getFileBytes(resA.storagePath);
      final readB = await storage.getFileBytes(resB.storagePath);

      expect(readA, isNotNull);
      expect(readB, isNotNull);
      expect(readA, equals(bytesA));
      expect(readB, equals(bytesB));
      expect(readA, isNot(equals(readB)));

      // Deleting Patient A does not affect Patient B
      await storage.deleteFile(resA.storagePath);
      expect(await storage.fileExists(resA.storagePath), isFalse);
      expect(await storage.fileExists(resB.storagePath), isTrue);
    });
  });
}
