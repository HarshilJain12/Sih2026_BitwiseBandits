import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/storage/medical_record_storage.dart';

/// Fake Supabase storage to test patient isolation
class IsolationTestStorage implements MedicalRecordStorage {
  final Map<String, Uint8List> _storage = {};

  @override
  String get storageType => 'supabase';

  @override
  Future<StorageUploadResult> uploadBytes({
    required String ownerUid,
    required String patientId,
    required String recordId,
    required String originalFileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final storagePath = MedicalRecordStorage.buildStoragePath(
      ownerUid: ownerUid,
      patientId: patientId,
      recordId: recordId,
      fileName: originalFileName,
    );
    _storage[storagePath] = bytes;

    return StorageUploadResult(
      storagePath: storagePath,
      fileSizeBytes: bytes.length,
      mimeType: mimeType ?? 'application/pdf',
      storageType: storageType,
      downloadUrl: 'https://ezjecnfrrkgehsabzgrg.supabase.co/storage/v1/object/sign/medical-records/$storagePath',
      localFile: null,
    );
  }

  @override
  Future<File?> getFile(String storagePath) async => null;

  @override
  Future<Uint8List?> getFileBytes(String storagePath) async => _storage[storagePath];

  @override
  Future<void> deleteFile(String storagePath) async {
    _storage.remove(storagePath);
  }

  @override
  Future<bool> fileExists(String storagePath) async => _storage.containsKey(storagePath);

  @override
  Future<String?> getDownloadUrl(String storagePath) async {
    if (!_storage.containsKey(storagePath)) return null;
    return 'https://ezjecnfrrkgehsabzgrg.supabase.co/storage/v1/object/sign/medical-records/$storagePath';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IsolationTestStorage storage;

  setUp(() {
    storage = IsolationTestStorage();
  });

  group('Critical Patient Isolation Tests with Firebase UID Sandboxing', () {
    const userA = 'UID_USER_A_1111111111111111111';
    const userB = 'UID_USER_B_2222222222222222222';
    const patientA = 'P-AAAA111111';
    const patientB = 'P-BBBB222222';
    const recordA = 'MR-AAAA000001';
    const recordB = 'MR-BBBB000002';

    test('Patient A upload is isolated under User A Firebase UID and inaccessible to User B', () async {
      final bytesA = Uint8List.fromList([1, 2, 3, 4, 5]);
      final uploadResultA = await storage.uploadBytes(
        ownerUid: userA,
        patientId: patientA,
        recordId: recordA,
        originalFileName: 'patient_a_prescription.pdf',
        bytes: bytesA,
        mimeType: 'application/pdf',
      );

      expect(uploadResultA.storagePath, startsWith('$userA/$patientA/$recordA'));
      expect(uploadResultA.storagePath, isNot(contains(userB)));
      expect(uploadResultA.storagePath, isNot(contains(patientB)));

      // Verify file exists at User A path
      expect(await storage.fileExists(uploadResultA.storagePath), isTrue);

      // Verify User B path with same patient ID and record ID does NOT exist
      final simulatedPathB = MedicalRecordStorage.buildStoragePath(
        ownerUid: userB,
        patientId: patientA,
        recordId: recordA,
        fileName: 'patient_a_prescription.pdf',
      );
      expect(await storage.fileExists(simulatedPathB), isFalse);
      expect(await storage.getFileBytes(simulatedPathB), isNull);
    });

    test('Patient B upload is isolated under User B Firebase UID and inaccessible to User A', () async {
      final bytesB = Uint8List.fromList([10, 20, 30, 40]);
      final uploadResultB = await storage.uploadBytes(
        ownerUid: userB,
        patientId: patientB,
        recordId: recordB,
        originalFileName: 'patient_b_blood_test.png',
        bytes: bytesB,
        mimeType: 'image/png',
      );

      expect(uploadResultB.storagePath, startsWith('$userB/$patientB/$recordB'));
      expect(uploadResultB.storagePath, isNot(contains(userA)));

      // Verify file exists at User B path
      expect(await storage.fileExists(uploadResultB.storagePath), isTrue);

      // Verify User A path with record B does NOT exist
      final simulatedPathA = MedicalRecordStorage.buildStoragePath(
        ownerUid: userA,
        patientId: patientB,
        recordId: recordB,
        fileName: 'patient_b_blood_test.png',
      );
      expect(await storage.fileExists(simulatedPathA), isFalse);
      expect(await storage.getFileBytes(simulatedPathA), isNull);
    });

    test('Two different patients managed under the SAME User Firebase UID are segregated by Patient ID', () async {
      const familyUser = 'UID_FAMILY_HEAD_33333333333';
      const patientSelf = 'P-SELF000001';
      const patientChild = 'P-CHILD00002';

      final bytesSelf = Uint8List.fromList('Self Medical Record'.codeUnits);
      final bytesChild = Uint8List.fromList('Child Vaccination Record'.codeUnits);

      final resSelf = await storage.uploadBytes(
        ownerUid: familyUser,
        patientId: patientSelf,
        recordId: 'MR-SELF00001',
        originalFileName: 'report.pdf',
        bytes: bytesSelf,
      );

      final resChild = await storage.uploadBytes(
        ownerUid: familyUser,
        patientId: patientChild,
        recordId: 'MR-CHILD0001',
        originalFileName: 'vaccine.pdf',
        bytes: bytesChild,
      );

      expect(resSelf.storagePath, startsWith('$familyUser/$patientSelf/'));
      expect(resChild.storagePath, startsWith('$familyUser/$patientChild/'));
      expect(resSelf.storagePath, isNot(equals(resChild.storagePath)));

      // Deleting self record does not affect child record
      await storage.deleteFile(resSelf.storagePath);
      expect(await storage.fileExists(resSelf.storagePath), isFalse);
      expect(await storage.fileExists(resChild.storagePath), isTrue);
    });
  });
}
