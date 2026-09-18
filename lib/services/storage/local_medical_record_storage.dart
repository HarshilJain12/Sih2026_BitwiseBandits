import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'medical_record_storage.dart';

/// Concrete implementation of [MedicalRecordStorage] that persists medical documents
/// locally inside the application-private directory on the device.
///
/// Directory structure:
/// `<app-private-documents-dir>/patients/<patientId>/medicalRecords/<recordId>/<sanitizedFileName>`
///
/// Features:
/// - Isolated per Patient ID (`P-XXXXXXXXXX`).
/// - 100% offline access to previously stored records.
/// - Zero Cloud Storage costs for the prototype.
/// - Seamless drop-in replacement for future Firebase Storage migration.
class LocalMedicalRecordStorage implements MedicalRecordStorage {
  LocalMedicalRecordStorage({this.customBaseDirectory});

  final Directory? customBaseDirectory;

  @override
  String get storageType => 'local';

  /// Resolves the base application-private directory.
  Future<Directory> _getBaseDirectory() async {
    final custom = customBaseDirectory;
    if (custom != null) {
      return custom;
    }
    return await getApplicationDocumentsDirectory();
  }

  /// Resolves the full absolute [File] on the filesystem corresponding to [storagePath].
  Future<File> _resolveFile(String storagePath) async {
    final baseDir = await _getBaseDirectory();
    final normalizedPath = storagePath.replaceAll(RegExp(r'^[/\\]+'), '');
    final fullPath = '${baseDir.path}${Platform.pathSeparator}$normalizedPath'
        .replaceAll(RegExp(r'[/\\]+'), Platform.pathSeparator);
    return File(fullPath);
  }

  @override
  Future<StorageUploadResult> uploadBytes({
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
      patientId: patientId,
      recordId: recordId,
      fileName: originalFileName,
    );

    final targetFile = await _resolveFile(storagePath);

    // Ensure parent directories exist
    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }

    // Write binary bytes to disk
    await targetFile.writeAsBytes(bytes, flush: true);

    if (kDebugMode) {
      debugPrint(
        '[LocalMedicalRecordStorage] Stored local file: ${targetFile.path} ($sizeBytes bytes)',
      );
    }

    return StorageUploadResult(
      storagePath: storagePath,
      fileSizeBytes: sizeBytes,
      mimeType: resolvedMime,
      storageType: storageType,
      downloadUrl: null,
      localFile: targetFile,
    );
  }

  @override
  Future<File?> getFile(String storagePath) async {
    if (storagePath.trim().isEmpty) return null;
    try {
      final file = await _resolveFile(storagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LocalMedicalRecordStorage] Error resolving file for $storagePath: $e',
        );
      }
      return null;
    }
  }

  @override
  Future<Uint8List?> getFileBytes(String storagePath) async {
    final file = await getFile(storagePath);
    if (file == null) return null;
    try {
      return await file.readAsBytes();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LocalMedicalRecordStorage] Error reading bytes for $storagePath: $e',
        );
      }
      return null;
    }
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    if (storagePath.trim().isEmpty) return;
    try {
      final file = await _resolveFile(storagePath);
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          debugPrint(
            '[LocalMedicalRecordStorage] Deleted local file: ${file.path}',
          );
        }

        // Clean up empty parent record directory if empty
        final parentDir = file.parent;
        if (await parentDir.exists()) {
          final remaining = await parentDir.list().isEmpty;
          if (remaining) {
            await parentDir.delete();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LocalMedicalRecordStorage] Error deleting local file $storagePath: $e',
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> fileExists(String storagePath) async {
    if (storagePath.trim().isEmpty) return false;
    try {
      final file = await _resolveFile(storagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getDownloadUrl(String storagePath) async {
    final file = await getFile(storagePath);
    if (file == null) return null;
    return Uri.file(file.path).toString();
  }
}
