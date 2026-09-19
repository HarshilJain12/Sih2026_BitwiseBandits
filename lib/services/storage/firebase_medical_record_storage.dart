import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'medical_record_storage.dart';

/// Concrete implementation of [MedicalRecordStorage] that uses Firebase Cloud Storage.
///
/// Preserved for future production use after the prototype phase.
class FirebaseMedicalRecordStorage implements MedicalRecordStorage {
  FirebaseMedicalRecordStorage({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  String get storageType => 'firebase';

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
      throw ArgumentError(
        'Invalid file size: $sizeBytes bytes. File size must be between 1 byte and 10 MB (10,485,760 bytes).',
      );
    }

    final resolvedMime = MedicalRecordStorage.resolveMimeType(
      originalFileName,
      mimeType,
    );
    if (!MedicalRecordStorage.isValidMimeType(resolvedMime)) {
      throw ArgumentError(
        'Unsupported file format: $resolvedMime. Allowed formats: PDF, JPEG, JPG, PNG.',
      );
    }

    final storagePath = MedicalRecordStorage.buildStoragePath(
      ownerUid: ownerUid,
      patientId: patientId,
      recordId: recordId,
      fileName: originalFileName,
    );

    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(
      contentType: resolvedMime,
      customMetadata: {
        'patientId': patientId,
        'recordId': recordId,
        'originalFileName': MedicalRecordStorage.sanitizeFileName(
          originalFileName,
        ),
      },
    );

    try {
      final uploadTask = await ref.putData(bytes, metadata);
      String? downloadUrl;
      try {
        downloadUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[FirebaseMedicalRecordStorage] Non-fatal: unable to generate downloadUrl: $e',
          );
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[FirebaseMedicalRecordStorage] Uploaded $storagePath ($sizeBytes bytes, $resolvedMime)',
        );
      }

      return StorageUploadResult(
        storagePath: storagePath,
        fileSizeBytes: sizeBytes,
        mimeType: resolvedMime,
        storageType: storageType,
        downloadUrl: downloadUrl,
        localFile: null,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseMedicalRecordStorage] Upload failed for $storagePath: $e',
        );
      }
      rethrow;
    }
  }

  @override
  Future<File?> getFile(String storagePath) async {
    // Cloud storage files are stored remotely, not as persistent local files.
    return null;
  }

  @override
  Future<Uint8List?> getFileBytes(String storagePath) async {
    if (storagePath.trim().isEmpty) return null;
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getData(MedicalRecordStorage.maxFileSizeBytes);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseMedicalRecordStorage] Error downloading bytes for $storagePath: $e',
        );
      }
      return null;
    }
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    if (storagePath.trim().isEmpty) return;
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
      if (kDebugMode) {
        debugPrint(
          '[FirebaseMedicalRecordStorage] Deleted file at $storagePath',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseMedicalRecordStorage] Error deleting file $storagePath: $e',
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> fileExists(String storagePath) async {
    if (storagePath.trim().isEmpty) return false;
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getDownloadUrl(String storagePath) async {
    if (storagePath.trim().isEmpty) return null;
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseMedicalRecordStorage] Error getting download URL for $storagePath: $e',
        );
      }
      return null;
    }
  }

  /// Returns a direct Firebase Storage [Reference] for a [storagePath].
  Reference getReference(String storagePath) {
    return _storage.ref().child(storagePath);
  }
}
