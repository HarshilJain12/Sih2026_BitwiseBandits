import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/medical_record.dart';
import '../record_id_generator.dart';
import '../storage/firebase_medical_record_storage.dart';
import '../storage/medical_record_storage.dart';

/// Service responsible for managing medical record metadata in Firestore
/// and coordinating with the [MedicalRecordStorage] provider.
///
/// Subcollection location:
/// `/patients/{patientId}/medicalRecords/{recordId}`
///
/// Current Production & Prototype Architecture:
/// `MedicalRecordService` -> `MedicalRecordStorage` -> `FirebaseMedicalRecordStorage` (Cloud Storage)
///
/// Future Offline Architecture:
/// `MedicalRecordService` -> `MedicalRecordStorage` -> `LocalMedicalRecordStorage` (Local on-device)
///
/// Follows rural-first principles:
/// - Isolated per-patient subcollections and local directories.
/// - Defensive client-side authentication and ownership verification.
/// - Clean coordinated deletion (Storage file + Firestore metadata) to avoid orphaned data.
/// - Original file preservation for future AI extraction.
class MedicalRecordService {
  MedicalRecordService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    MedicalRecordStorage? storage,
    RecordIdGenerator? idGenerator,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseMedicalRecordStorage(),
       _idGenerator = idGenerator ?? const RecordIdGenerator();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final MedicalRecordStorage _storage;
  final RecordIdGenerator _idGenerator;

  /// Returns the active storage provider.
  MedicalRecordStorage get storage => _storage;

  CollectionReference<Map<String, dynamic>> _recordsRef(String patientId) =>
      _firestore
          .collection('patients')
          .doc(patientId)
          .collection('medicalRecords');

  DocumentReference<Map<String, dynamic>> _patientDocRef(String patientId) =>
      _firestore.collection('patients').doc(patientId);

  /// Stores document binary bytes and records metadata atomically in Firestore.
  ///
  /// Flow:
  /// 1. Verifies authentication and patient profile ownership.
  /// 2. Generates unique Medical Record ID (`MR-XXXXXXXXXX`).
  /// 3. Stores binary file using [_storage] (defaults to Local storage).
  /// 4. Creates Firestore metadata document in `/patients/{patientId}/medicalRecords/{recordId}`.
  ///
  /// Returns the created [MedicalRecord].
  ///
  /// Throws [StateError] if unauthenticated or user does not own the patient profile.
  /// Throws [ArgumentError] if file size > 10 MB or MIME type is not supported.
  Future<MedicalRecord> uploadAndCreateRecord({
    required String patientId,
    required String originalFileName,
    required Uint8List bytes,
    String? mimeType,
    String? category,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'Cannot upload medical record: no authenticated user. '
        'Ensure Firebase Auth is completed before uploading.',
      );
    }

    final uid = user.uid;

    // 1. Verify patient profile existence and ownership
    final patientSnap = await _patientDocRef(patientId).get();
    if (!patientSnap.exists) {
      throw StateError('Patient profile $patientId does not exist.');
    }
    final patientOwner = patientSnap.data()?['ownerUid'] as String?;
    if (patientOwner != uid) {
      throw StateError(
        'Access denied: user $uid does not own patient $patientId (owner: $patientOwner).',
      );
    }

    // 2. Generate unique Record ID
    final recordId = _idGenerator.generate();

    // 3. Store file bytes using storage provider
    final uploadResult = await _storage.uploadBytes(
      patientId: patientId,
      recordId: recordId,
      originalFileName: originalFileName,
      bytes: bytes,
      mimeType: mimeType,
    );

    final now = DateTime.now();

    final record = MedicalRecord(
      recordId: recordId,
      patientId: patientId,
      ownerUid: uid,
      originalFileName: originalFileName,
      storagePath: uploadResult.storagePath,
      storageType: _storage.storageType,
      downloadUrl: uploadResult.downloadUrl,
      mimeType: uploadResult.mimeType,
      fileSizeBytes: uploadResult.fileSizeBytes,
      uploadedAt: now,
      updatedAt: now,
      status: 'uploaded',
      category: category,
      notes: notes,
    );

    // 4. Write metadata document to Firestore
    try {
      await _recordsRef(patientId)
          .doc(recordId)
          .set(record.toFirestore(useServerTimestamp: true));

      if (kDebugMode) {
        debugPrint(
          '[MedicalRecordService] Saved metadata for record $recordId (patient: $patientId, type: ${_storage.storageType})',
        );
      }

      // Re-fetch to retrieve server timestamps
      final savedSnap = await _recordsRef(patientId).doc(recordId).get();
      return MedicalRecord.fromFirestore(savedSnap);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MedicalRecordService] Firestore metadata creation failed: $e. Cleaning up stored file ${uploadResult.storagePath}',
        );
      }
      // Attempt cleanup to prevent orphaned storage binary
      try {
        await _storage.deleteFile(uploadResult.storagePath);
      } catch (cleanupError) {
        if (kDebugMode) {
          debugPrint(
            '[MedicalRecordService] Failed to clean up orphaned storage file ${uploadResult.storagePath}: $cleanupError',
          );
        }
      }
      rethrow;
    }
  }

  /// Retrieves a single medical record metadata document by its [recordId].
  ///
  /// Returns `null` if the record does not exist or the user is not authorized.
  Future<MedicalRecord?> getRecord({
    required String patientId,
    required String recordId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final snap = await _recordsRef(patientId).doc(recordId).get();
      if (!snap.exists) return null;

      final record = MedicalRecord.fromFirestore(snap);
      if (record.ownerUid != user.uid) {
        if (kDebugMode) {
          debugPrint(
            '[MedicalRecordService] Access denied: user ${user.uid} does not own record $recordId',
          );
        }
        return null;
      }

      return record;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MedicalRecordService] Error getting record $recordId: $e');
      }
      rethrow;
    }
  }

  /// Retrieves all medical records for a [patientId], ordered by [uploadedAt] descending.
  Future<List<MedicalRecord>> getRecordsForPatient(String patientId) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _recordsRef(patientId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MedicalRecord.fromFirestore(doc))
          .where((record) => record.ownerUid == user.uid)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MedicalRecordService] Error fetching records for patient $patientId: $e',
        );
      }
      rethrow;
    }
  }

  /// Deletes a medical record completely:
  /// 1. Deletes the physical file using [_storage].
  /// 2. Deletes the metadata document in Firestore.
  ///
  /// Prevents leaving orphaned files or broken references.
  Future<void> deleteRecord({
    required String patientId,
    required String recordId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Cannot delete record: user not authenticated.');
    }

    final docRef = _recordsRef(patientId).doc(recordId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw StateError('Medical record $recordId does not exist.');
    }

    final record = MedicalRecord.fromFirestore(snap);
    if (record.ownerUid != user.uid) {
      throw StateError(
        'Access denied: user ${user.uid} does not own record $recordId.',
      );
    }

    // 1. Delete physical storage file
    try {
      await _storage.deleteFile(record.storagePath);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MedicalRecordService] Warning: error deleting storage file ${record.storagePath}: $e. Proceeding to delete metadata.',
        );
      }
    }

    // 2. Delete Firestore document
    try {
      await docRef.delete();
      if (kDebugMode) {
        debugPrint(
          '[MedicalRecordService] Successfully deleted record $recordId metadata.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MedicalRecordService] Error deleting Firestore document $recordId: $e',
        );
      }
      rethrow;
    }
  }

  /// Retrieves the stored local [File] handle for a record (if available on device).
  Future<File?> getLocalFile(MedicalRecord record) async {
    return await _storage.getFile(record.storagePath);
  }

  /// Reads raw bytes of the stored medical document.
  Future<Uint8List?> getDocumentBytes(MedicalRecord record) async {
    return await _storage.getFileBytes(record.storagePath);
  }

  /// Updates optional metadata fields (category, notes, status) for a medical record.
  Future<MedicalRecord> updateRecordMetadata({
    required String patientId,
    required String recordId,
    String? category,
    String? notes,
    String? status,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Cannot update record: user not authenticated.');
    }

    final docRef = _recordsRef(patientId).doc(recordId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw StateError('Medical record $recordId does not exist.');
    }

    final record = MedicalRecord.fromFirestore(snap);
    if (record.ownerUid != user.uid) {
      throw StateError(
        'Access denied: user ${user.uid} does not own record $recordId.',
      );
    }

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (category != null) updates['category'] = category;
    if (notes != null) updates['notes'] = notes;
    if (status != null) updates['status'] = status;

    await docRef.update(updates);

    final updatedSnap = await docRef.get();
    return MedicalRecord.fromFirestore(updatedSnap);
  }
}
