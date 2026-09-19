import 'dart:io';

import 'package:flutter/foundation.dart';

/// Result from a successful storage upload / save operation.
class StorageUploadResult {
  const StorageUploadResult({
    required this.storagePath,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.storageType,
    this.downloadUrl,
    this.localFile,
  });

  /// Canonical relative path: `{ownerUid}/{patientId}/{recordId}/{fileName}`
  final String storagePath;

  /// Exact file size in bytes.
  final int fileSizeBytes;

  /// MIME type (e.g. "application/pdf", "image/jpeg", "image/png").
  final String mimeType;

  /// Storage provider identifier: `'supabase'` or `'firebase'`.
  final String storageType;

  /// Optional remote or signed download URL.
  final String? downloadUrl;

  /// Optional temporary cached [File] handle (e.g. for viewer).
  final File? localFile;
}

/// Abstract storage interface for patient medical records.
///
/// Decouples the UI and [MedicalRecordService] from physical storage mechanisms.
/// Supports:
/// - [SupabaseMedicalRecordStorage] (active cloud storage in private `medical-records` bucket)
/// - [FirebaseMedicalRecordStorage] (alternative cloud storage provider)
abstract class MedicalRecordStorage {
  /// Identifier of the storage provider ('supabase' or 'firebase').
  String get storageType;

  /// Maximum allowed file size in bytes: 10 MB (10,485,760 bytes).
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Whitelisted MIME types for medical documents.
  static const Set<String> allowedMimeTypes = {
    'application/pdf',
    'image/jpeg',
    'image/jpg',
    'image/png',
  };

  /// Whitelisted file extensions.
  static const Set<String> allowedExtensions = {
    '.pdf',
    '.jpg',
    '.jpeg',
    '.png',
  };

  /// Constructs the canonical patient-scoped storage path:
  /// `{ownerUid}/{patientId}/{recordId}/{fileName}`
  static String buildStoragePath({
    required String ownerUid,
    required String patientId,
    required String recordId,
    required String fileName,
  }) {
    final cleanFileName = sanitizeFileName(fileName);
    final cleanUid = ownerUid.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '');
    return '$cleanUid/$patientId/$recordId/$cleanFileName';
  }

  /// Sanitizes a file name by removing illegal path characters and directory traversal.
  static String sanitizeFileName(String rawName) {
    if (rawName.trim().isEmpty) {
      return 'document.bin';
    }
    // Remove directory traversal dots like ../ or ..\ or leading dots
    var cleaned = rawName.replaceAll(RegExp(r'\.\.+[/\\]*'), '_');
    // Remove directory traversal, control characters, and illegal filesystem characters
    cleaned = cleaned.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
    cleaned = cleaned
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    // Remove leading underscores or dots
    cleaned = cleaned.replaceAll(RegExp(r'^[_.]+'), '');
    if (cleaned.isEmpty) {
      return 'document.bin';
    }
    return cleaned.trim();
  }

  /// Resolves the MIME type from a file name extension if not explicitly supplied.
  static String resolveMimeType(String fileName, [String? explicitMime]) {
    if (explicitMime != null &&
        explicitMime.isNotEmpty &&
        allowedMimeTypes.contains(explicitMime.toLowerCase())) {
      return explicitMime.toLowerCase();
    }
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    return 'application/octet-stream';
  }

  /// Validates whether a given MIME type is supported.
  static bool isValidMimeType(String mimeType) {
    return allowedMimeTypes.contains(mimeType.toLowerCase());
  }

  /// Validates whether a file size in bytes is within the 10 MB limit.
  static bool isValidFileSize(int sizeBytes) {
    return sizeBytes > 0 && sizeBytes <= maxFileSizeBytes;
  }

  /// Stores / uploads file bytes under the given [ownerUid], [patientId], and [recordId].
  Future<StorageUploadResult> uploadBytes({
    required String ownerUid,
    required String patientId,
    required String recordId,
    required String originalFileName,
    required Uint8List bytes,
    String? mimeType,
  });

  /// Retrieves the stored file handle (temporary cache if downloaded).
  ///
  /// Returns `null` if the file is remote and not cached.
  Future<File?> getFile(String storagePath);

  /// Reads raw bytes of the stored file.
  ///
  /// Returns `null` if the file cannot be found or read.
  Future<Uint8List?> getFileBytes(String storagePath);

  /// Deletes the file from storage.
  Future<void> deleteFile(String storagePath);

  /// Checks if the file exists at [storagePath].
  Future<bool> fileExists(String storagePath);

  /// Retrieves a temporary authenticated download/view URL (signed URL).
  Future<String?> getDownloadUrl(String storagePath);
}
