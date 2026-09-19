import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/storage/medical_record_storage.dart';

/// Fake implementation of [MedicalRecordStorage] simulating Supabase Storage behavior in unit tests.
class FakeSupabaseMedicalRecordStorage implements MedicalRecordStorage {
  final Map<String, Uint8List> _storage = {};
  final List<String> deletedPaths = [];
  final List<String> uploadedPaths = [];

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
    final sizeBytes = bytes.length;
    if (!MedicalRecordStorage.isValidFileSize(sizeBytes)) {
      throw ArgumentError('Invalid file size: $sizeBytes bytes.');
    }

    final resolvedMime = MedicalRecordStorage.resolveMimeType(
      originalFileName,
      mimeType,
    );
    if (!MedicalRecordStorage.isValidMimeType(resolvedMime)) {
      throw ArgumentError('Unsupported file format: $resolvedMime.');
    }

    final storagePath = MedicalRecordStorage.buildStoragePath(
      ownerUid: ownerUid,
      patientId: patientId,
      recordId: recordId,
      fileName: originalFileName,
    );

    _storage[storagePath] = bytes;
    uploadedPaths.add(storagePath);

    return StorageUploadResult(
      storagePath: storagePath,
      fileSizeBytes: sizeBytes,
      mimeType: resolvedMime,
      storageType: storageType,
      downloadUrl: 'https://ezjecnfrrkgehsabzgrg.supabase.co/storage/v1/object/sign/medical-records/$storagePath?token=fake_signed_token',
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
    deletedPaths.add(storagePath);
  }

  @override
  Future<bool> fileExists(String storagePath) async => _storage.containsKey(storagePath);

  @override
  Future<String?> getDownloadUrl(String storagePath) async {
    if (!_storage.containsKey(storagePath)) return null;
    return 'https://ezjecnfrrkgehsabzgrg.supabase.co/storage/v1/object/sign/medical-records/$storagePath?token=fake_signed_token';
  }
}

void main() {
  group('Supabase Medical Record Storage Architecture & Workflow Tests', () {
    late FakeSupabaseMedicalRecordStorage supabaseStorage;

    setUp(() {
      supabaseStorage = FakeSupabaseMedicalRecordStorage();
    });

    test('1. Supabase storage has storageType "supabase"', () {
      expect(supabaseStorage.storageType, equals('supabase'));
    });

    test('2. Uploads sample medical PDF to Supabase private bucket path {firebaseUid}/{patientId}/{recordId}/{fileName}', () async {
      const ownerUid = 'P5CeG63YI8UQ4BRQs8MfTGGJ9sX2';
      const patientId = 'P-RURALPAT01';
      const recordId = 'MR-REC9876543';
      const fileName = 'fictional_blood_test_report.pdf';
      final samplePdfBytes = Uint8List.fromList(
        '%PDF-1.4 Fictional Blood Glucose: 95 mg/dL, HbA1c: 5.6%'.codeUnits,
      );

      final uploadResult = await supabaseStorage.uploadBytes(
        ownerUid: ownerUid,
        patientId: patientId,
        recordId: recordId,
        originalFileName: fileName,
        bytes: samplePdfBytes,
        mimeType: 'application/pdf',
      );

      // Expected canonical storage path with Firebase UID top-level sandbox
      expect(
        uploadResult.storagePath,
        equals('P5CeG63YI8UQ4BRQs8MfTGGJ9sX2/P-RURALPAT01/MR-REC9876543/fictional_blood_test_report.pdf'),
      );
      expect(uploadResult.storageType, equals('supabase'));
      expect(uploadResult.fileSizeBytes, equals(samplePdfBytes.length));
      expect(uploadResult.mimeType, equals('application/pdf'));
      expect(uploadResult.downloadUrl, contains('sign/medical-records'));
      expect(uploadResult.localFile, isNull);

      // Verify file exists in Supabase storage
      expect(await supabaseStorage.fileExists(uploadResult.storagePath), isTrue);

      // Read back bytes from Supabase
      final storedBytes = await supabaseStorage.getFileBytes(uploadResult.storagePath);
      expect(storedBytes, isNotNull);
      expect(storedBytes, equals(samplePdfBytes));
    });

    test('3. Store prescription image with clean signed URL and verify coordinated deletion', () async {
      const ownerUid = 'P5CeG63YI8UQ4BRQs8MfTGGJ9sX2';
      const patientId = 'P-VILLAGE002';
      const recordId = 'MR-RX12345678';
      const fileName = 'dr_sharma_prescription.jpg';
      final sampleImgBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]);

      final uploadResult = await supabaseStorage.uploadBytes(
        ownerUid: ownerUid,
        patientId: patientId,
        recordId: recordId,
        originalFileName: fileName,
        bytes: sampleImgBytes,
        mimeType: 'image/jpeg',
      );

      expect(uploadResult.storagePath, contains('P5CeG63YI8UQ4BRQs8MfTGGJ9sX2/P-VILLAGE002/MR-RX12345678'));
      expect(uploadResult.storageType, equals('supabase'));

      // Check download signed URL
      final signedUrl = await supabaseStorage.getDownloadUrl(uploadResult.storagePath);
      expect(signedUrl, isNotNull);
      expect(signedUrl, contains('token=fake_signed_token'));

      // Delete from storage
      await supabaseStorage.deleteFile(uploadResult.storagePath);
      expect(await supabaseStorage.fileExists(uploadResult.storagePath), isFalse);
      expect(supabaseStorage.deletedPaths.contains(uploadResult.storagePath), isTrue);
    });

    test('4. Large file exceeding 10 MB is rejected with ArgumentError before upload', () async {
      const ownerUid = 'P5CeG63YI8UQ4BRQs8MfTGGJ9sX2';
      const patientId = 'P-OVERSIZED';
      const recordId = 'MR-BIG1234567';
      final oversizedBytes = Uint8List(10 * 1024 * 1024 + 1);

      expect(
        () => supabaseStorage.uploadBytes(
          ownerUid: ownerUid,
          patientId: patientId,
          recordId: recordId,
          originalFileName: 'huge_scan.pdf',
          bytes: oversizedBytes,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('5. Unsupported MIME type (e.g. .exe / .zip) is rejected before upload', () async {
      const ownerUid = 'P5CeG63YI8UQ4BRQs8MfTGGJ9sX2';
      const patientId = 'P-INVALID';
      const recordId = 'MR-INV1234567';
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      expect(
        () => supabaseStorage.uploadBytes(
          ownerUid: ownerUid,
          patientId: patientId,
          recordId: recordId,
          originalFileName: 'malware.exe',
          bytes: bytes,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
