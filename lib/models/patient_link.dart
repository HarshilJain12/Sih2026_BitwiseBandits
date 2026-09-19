import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for `/accounts/{uid}/patientLinks/{patientId}` subcollection documents.
///
/// Links an authenticated account to an individual patient profile.
/// One account can have multiple patient links (self + family members).
///
/// In this phase, only `"self"` relationship is created.
/// Future phases will support:
/// - `"mother"`, `"father"`, `"spouse"`, `"son"`, `"daughter"`
/// - `"grandparent"`, `"other"`
class PatientLink {
  const PatientLink({
    required this.patientId,
    required this.relationship,
    required this.createdAt,
  });

  /// The Patient ID this link refers to (e.g. `"P-7K4M92XQ1A"`).
  final String patientId;

  /// The relationship of the linked patient to the account holder.
  /// Currently: `"self"`. Future: `"mother"`, `"father"`, `"spouse"`, etc.
  final String relationship;

  final DateTime createdAt;

  factory PatientLink.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return PatientLink(
      patientId: data['patientId'] as String? ?? snapshot.id,
      relationship: data['relationship'] as String? ?? 'self',
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  /// Converts this [PatientLink] to a Firestore-compatible map.
  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      'patientId': patientId,
      'relationship': relationship,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  /// Safely parses a Firestore Timestamp or returns epoch if null/invalid.
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  String toString() =>
      'PatientLink(patientId=$patientId, relationship=$relationship)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientLink &&
          runtimeType == other.runtimeType &&
          patientId == other.patientId;

  @override
  int get hashCode => patientId.hashCode;
}
