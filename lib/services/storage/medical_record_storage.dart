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

  /// Canonical relative path: `patients/{patientId}/medicalRecords/{recordId}/{fileName}`
  final String storagePath;

  /// Exact file size in bytes.
  final int fileSizeBytes;

  /// MIME type (e.g. "application/pdf", "image/jpeg", "image/png").
  final String mimeType;

  /// Storage provider identifier: `'local'` or `'firebase'`.
  final String storageType;

  /// Optional remote download URL (for Firebase Storage).
  final String? downloadUrl;

  /// Optional local [File] handle (for Local Storage).
  final File? localFile;
}

/// Abstract storage interface for patient medical records.
///
/// Decouples the UI and [MedicalRecordService] from physical storage mechanisms.
/// Supports both:
/// - [LocalMedicalRecordStorage] (active for SIH prototype, zero cloud costs)
/// - [FirebaseMedicalRecordStorage] (future production migration)
abstract class MedicalRecordStorage {
  /// Identifier of the storage provider ('local' or 'firebase').
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
  /// `patients/{patientId}/medicalRecords/{recordId}/{fileName}`
  static String buildStoragePath({
    required String patientId,
    required String recordId,
    required String fileName,
  }) {
    final cleanFileName = sanitizeFileName(fileName);
    return 'patients/$patientId/medicalRecords/$recordId/$cleanFileName';
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

  /// Stores / uploads file bytes under the given [patientId] and [recordId].
  Future<StorageUploadResult> uploadBytes({
    required String patientId,
    required String recordId,
    required String originalFileName,
    required Uint8List bytes,
    String? mimeType,
  });

  /// Retrieves the stored file handle.
  ///
  /// Returns `null` if the file does not exist locally.
  Future<File?> getFile(String storagePath);

  /// Reads raw bytes of the stored file.
  ///
  /// Returns `null` if the file cannot be found or read.
  Future<Uint8List?> getFileBytes(String storagePath);

  /// Deletes the file from storage.
  Future<void> deleteFile(String storagePath);

  /// Checks if the file exists at [storagePath].
  Future<bool> fileExists(String storagePath);

  /// Retrieves a temporary or persistent download/view URL (if supported).
  Future<String?> getDownloadUrl(String storagePath);
}
