import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a patient's medical document metadata stored in Firestore.
///
/// Subcollection location:
/// `/patients/{patientId}/medicalRecords/{recordId}`
///
/// Follows rural-first principles:
/// - [storagePath] is the canonical persistent identifier (e.g. `patients/P-XXX/medicalRecords/MR-YYY/file.pdf`).
/// - [storageType] indicates whether the document is stored `'local'` (on device) or `'firebase'` (Cloud Storage).
/// - [downloadUrl] is nullable/transient and not required for record persistence.
/// - Original uploaded binaries are preserved intact for future AI processing.
class MedicalRecord {
  const MedicalRecord({
    required this.recordId,
    required this.patientId,
    required this.ownerUid,
    required this.originalFileName,
    required this.storagePath,
    this.storageType = 'local',
    this.downloadUrl,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.updatedAt,
    this.status = 'uploaded',
    this.category,
    this.notes,
    this.doctorUid,
    this.doctorName,
    this.doctorSpecialization,
  });

  /// Unique record identifier (format: `MR-XXXXXXXXXX`).
  final String recordId;

  /// Identifier of the owning patient profile (format: `P-XXXXXXXXXX`).
  final String patientId;

  /// Firebase Auth UID of the account that created/owns this record.
  final String ownerUid;

  /// Original user-provided or device filename (e.g. "blood_test.pdf").
  final String originalFileName;

  /// Canonical path in storage:
  /// `patients/{patientId}/medicalRecords/{recordId}/{fileName}`
  final String storagePath;

  /// Storage provider type: `'local'` (on-device app storage) or `'firebase'` (Cloud Storage).
  final String storageType;

  /// Optional transient download URL (if generated during upload/retrieval).
  final String? downloadUrl;

  /// MIME type of the document (e.g. "application/pdf", "image/jpeg", "image/png").
  final String mimeType;

  /// File size in bytes (max 10 MB = 10,485,760 bytes).
  final int fileSizeBytes;

  /// Timestamp when the document was first uploaded.
  final DateTime uploadedAt;

  /// Timestamp when the metadata was last updated.
  final DateTime updatedAt;

  /// Status of the document (e.g. "uploaded", "archived").
  final String status;

  /// Optional user/clinical categorization (e.g. "prescription", "lab_report", "scan", "other").
  final String? category;

  /// Optional notes added by the user or healthcare worker.
  final String? notes;

  /// Firebase UID of the doctor who created this record (null if patient-uploaded).
  final String? doctorUid;

  /// Display name of the doctor who created this record.
  final String? doctorName;

  /// Specialization of the doctor who created this record.
  final String? doctorSpecialization;

  /// Whether this record was created by a doctor.
  bool get isDoctorRecord => doctorUid != null;

  /// Creates a [MedicalRecord] from a Firestore [DocumentSnapshot].
  factory MedicalRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'Cannot create MedicalRecord from null DocumentSnapshot data',
      );
    }
    return MedicalRecord.fromMap(data, documentId: snapshot.id);
  }

  /// Creates a [MedicalRecord] from a Map.
  factory MedicalRecord.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final rawUploadedAt = map['uploadedAt'];
    DateTime uploadedAt;
    if (rawUploadedAt is Timestamp) {
      uploadedAt = rawUploadedAt.toDate();
    } else if (rawUploadedAt is String) {
      uploadedAt = DateTime.tryParse(rawUploadedAt) ?? DateTime.now();
    } else {
      uploadedAt = DateTime.now();
    }

    final rawUpdatedAt = map['updatedAt'];
    DateTime updatedAt;
    if (rawUpdatedAt is Timestamp) {
      updatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is String) {
      updatedAt = DateTime.tryParse(rawUpdatedAt) ?? DateTime.now();
    } else {
      updatedAt = DateTime.now();
    }

    return MedicalRecord(
      recordId: documentId ?? (map['recordId'] as String? ?? ''),
      patientId: map['patientId'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      originalFileName: map['originalFileName'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? '',
      storageType: map['storageType'] as String? ?? 'local',
      downloadUrl: map['downloadUrl'] as String?,
      mimeType: map['mimeType'] as String? ?? 'application/octet-stream',
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedAt: uploadedAt,
      updatedAt: updatedAt,
      status: map['status'] as String? ?? 'uploaded',
      category: map['category'] as String?,
      notes: map['notes'] as String?,
      doctorUid: map['doctorUid'] as String?,
      doctorName: map['doctorName'] as String?,
      doctorSpecialization: map['doctorSpecialization'] as String?,
    );
  }

  /// Converts the [MedicalRecord] to a Firestore-compatible Map.
  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = <String, dynamic>{
      'recordId': recordId,
      'patientId': patientId,
      'ownerUid': ownerUid,
      'originalFileName': originalFileName,
      'storagePath': storagePath,
      'storageType': storageType,
      'mimeType': mimeType,
      'fileSizeBytes': fileSizeBytes,
      'status': status,
      'uploadedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(uploadedAt),
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };

    if (downloadUrl != null) {
      map['downloadUrl'] = downloadUrl;
    }
    if (category != null) {
      map['category'] = category;
    }
    if (notes != null) {
      map['notes'] = notes;
    }
    if (doctorUid != null) {
      map['doctorUid'] = doctorUid;
    }
    if (doctorName != null) {
      map['doctorName'] = doctorName;
    }
    if (doctorSpecialization != null) {
      map['doctorSpecialization'] = doctorSpecialization;
    }

    return map;
  }

  /// Converts to standard serializable Map.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'recordId': recordId,
      'patientId': patientId,
      'ownerUid': ownerUid,
      'originalFileName': originalFileName,
      'storagePath': storagePath,
      'storageType': storageType,
      'mimeType': mimeType,
      'fileSizeBytes': fileSizeBytes,
      'uploadedAt': uploadedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
    };

    if (downloadUrl != null) {
      map['downloadUrl'] = downloadUrl;
    }
    if (category != null) {
      map['category'] = category;
    }
    if (notes != null) {
      map['notes'] = notes;
    }
    if (doctorUid != null) {
      map['doctorUid'] = doctorUid;
    }
    if (doctorName != null) {
      map['doctorName'] = doctorName;
    }
    if (doctorSpecialization != null) {
      map['doctorSpecialization'] = doctorSpecialization;
    }

    return map;
  }

  /// Returns a copy of this [MedicalRecord] with updated fields.
  MedicalRecord copyWith({
    String? recordId,
    String? patientId,
    String? ownerUid,
    String? originalFileName,
    String? storagePath,
    String? storageType,
    String? downloadUrl,
    String? mimeType,
    int? fileSizeBytes,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    String? status,
    String? category,
    String? notes,
    String? doctorUid,
    String? doctorName,
    String? doctorSpecialization,
  }) {
    return MedicalRecord(
      recordId: recordId ?? this.recordId,
      patientId: patientId ?? this.patientId,
      ownerUid: ownerUid ?? this.ownerUid,
      originalFileName: originalFileName ?? this.originalFileName,
      storagePath: storagePath ?? this.storagePath,
      storageType: storageType ?? this.storageType,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      doctorUid: doctorUid ?? this.doctorUid,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialization: doctorSpecialization ?? this.doctorSpecialization,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicalRecord &&
          runtimeType == other.runtimeType &&
          recordId == other.recordId &&
          patientId == other.patientId &&
          ownerUid == other.ownerUid &&
          originalFileName == other.originalFileName &&
          storagePath == other.storagePath &&
          storageType == other.storageType &&
          mimeType == other.mimeType &&
          fileSizeBytes == other.fileSizeBytes &&
          status == other.status &&
          category == other.category &&
          notes == other.notes;

  @override
  int get hashCode =>
      recordId.hashCode ^
      patientId.hashCode ^
      ownerUid.hashCode ^
      originalFileName.hashCode ^
      storagePath.hashCode ^
      storageType.hashCode ^
      mimeType.hashCode ^
      fileSizeBytes.hashCode ^
      status.hashCode ^
      category.hashCode ^
      notes.hashCode;

  @override
  String toString() =>
      'MedicalRecord(recordId: $recordId, patientId: $patientId, type: $storageType, fileName: $originalFileName, size: $fileSizeBytes bytes, mime: $mimeType)';
}
