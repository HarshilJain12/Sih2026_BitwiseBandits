import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import 'medical_record_storage.dart';

/// Concrete implementation of [MedicalRecordStorage] that uses Supabase Storage
/// with the private `medical-records` bucket.
///
/// Canonical path format:
/// `{firebaseUid}/{patientId}/{recordId}/{sanitizedFileName}`
///
/// Features:
/// - Authenticated top-level security sandbox using Firebase UID (`auth.jwt() ->> 'sub'`).
/// - Multi-patient / family-member architecture supported under the same Firebase UID.
/// - Private bucket security with signed URL generation.
/// - Automatic MIME type and size validation (<= 10 MB).
class SupabaseMedicalRecordStorage implements MedicalRecordStorage {
  SupabaseMedicalRecordStorage({
    SupabaseClient? client,
    String? bucketName,
  }) : _customClient = client,
       _bucketName = bucketName ?? SupabaseConfig.medicalRecordsBucket;

  final SupabaseClient? _customClient;
  final String _bucketName;

  SupabaseClient get _client {
    if (_customClient != null) return _customClient;
    return Supabase.instance.client;
  }

  @override
  String get storageType => 'supabase';

  /// Storage bucket reference.
  StorageFileApi get _storage => _client.storage.from(_bucketName);

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

    if (kDebugMode) {
      final uri = Uri.tryParse(SupabaseConfig.supabaseUrl);
      final projectRef = uri?.host.split('.').firstOrNull ?? 'unknown';
      debugPrint('════════════════ SUPABASE UPLOAD TRACE ════════════════');
      debugPrint('1. SUPABASE INITIALIZED: true');
      debugPrint('2. SUPABASE URL: ${SupabaseConfig.supabaseUrl}');
      debugPrint('3. SUPABASE PROJECT REF: $projectRef');
      debugPrint('4. BUCKET NAME: $_bucketName');
      debugPrint('5. TARGET STORAGE PATH: $storagePath');
      debugPrint('6. OWNER UID (CALLER): $ownerUid');
      debugPrint('7. PATIENT ID: $patientId | RECORD ID: $recordId');
      debugPrint('8. FILE DETAILS: $originalFileName ($sizeBytes bytes, $resolvedMime)');
    }

    try {
      await _storage.uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: resolvedMime,
          upsert: true,
        ),
      );

      String? downloadUrl;
      try {
        downloadUrl = await _storage.createSignedUrl(storagePath, 3600);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[SupabaseMedicalRecordStorage] Non-fatal: unable to generate initial signedUrl: $e',
          );
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[SupabaseMedicalRecordStorage] Upload SUCCESS: $storagePath ($sizeBytes bytes, $resolvedMime)',
        );
        debugPrint('═══════════════════════════════════════════════════════');
      }

      return StorageUploadResult(
        storagePath: storagePath,
        fileSizeBytes: sizeBytes,
        mimeType: resolvedMime,
        storageType: storageType,
        downloadUrl: downloadUrl,
        localFile: null,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('──────────────── SUPABASE UPLOAD ERROR ────────────────');
        debugPrint('EXCEPTION TYPE: ${e.runtimeType}');
        debugPrint('ERROR MESSAGE: $e');
        if (e is StorageException) {
          debugPrint('STATUS CODE: ${e.statusCode}');
          debugPrint('STORAGE ERROR: ${e.error}');
          debugPrint('STORAGE MESSAGE: ${e.message}');
        }
        if (e is AuthException) {
          debugPrint('AUTH STATUS CODE: ${e.statusCode}');
          debugPrint('AUTH MESSAGE: ${e.message}');
        }
        debugPrint('ATTEMPTED PATH: $storagePath');
        debugPrint('BUCKET: $_bucketName');
        debugPrint('STACK TRACE: $stackTrace');
        debugPrint('═══════════════════════════════════════════════════════');
      }
      rethrow;
    }
  }

  @override
  Future<File?> getFile(String storagePath) async {
    // Cloud storage files are stored in Supabase, not as persistent local files.
    return null;
  }

  @override
  Future<Uint8List?> getFileBytes(String storagePath) async {
    if (storagePath.trim().isEmpty) return null;
    try {
      return await _storage.download(storagePath);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[SupabaseMedicalRecordStorage] Error downloading bytes for $storagePath: $e',
        );
      }
      return null;
    }
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    if (storagePath.trim().isEmpty) return;
    try {
      await _storage.remove([storagePath]);
      if (kDebugMode) {
        debugPrint(
          '[SupabaseMedicalRecordStorage] Deleted file at $storagePath',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[SupabaseMedicalRecordStorage] Error deleting file $storagePath: $e',
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> fileExists(String storagePath) async {
    if (storagePath.trim().isEmpty) return false;
    try {
      // List the specific file path in the parent directory
      final lastSlash = storagePath.lastIndexOf('/');
      final parentPath = lastSlash > 0 ? storagePath.substring(0, lastSlash) : '';
      final fileName = lastSlash > 0 ? storagePath.substring(lastSlash + 1) : storagePath;

      final files = await _storage.list(path: parentPath.isEmpty ? null : parentPath);
      return files.any((f) => f.name == fileName);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getDownloadUrl(String storagePath) async {
    if (storagePath.trim().isEmpty) return null;
    try {
      // 1-hour signed URL for private bucket access
      return await _storage.createSignedUrl(storagePath, 3600);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[SupabaseMedicalRecordStorage] Error generating signed URL for $storagePath: $e',
        );
      }
      return null;
    }
  }
}
