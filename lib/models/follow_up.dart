import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUp {
  const FollowUp({
    required this.followUpId,
    required this.ashaId,
    required this.memberId,
    required this.familyId,
    required this.type, // pregnancy, vaccination, infant_nutrition, fever, hospital_referral
    required this.description,
    required this.scheduledDate,
    required this.status, // pending, completed, overdue
    this.completedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String followUpId;
  final String ashaId;
  final String memberId;
  final String familyId;
  final String type;
  final String description;
  final DateTime scheduledDate;
  final String status;
  final DateTime? completedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FollowUp.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return FollowUp(
      followUpId: snapshot.id,
      ashaId: data['ashaId'] as String? ?? '',
      memberId: data['memberId'] as String? ?? '',
      familyId: data['familyId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      description: data['description'] as String? ?? '',
      scheduledDate: _parseTimestamp(data['scheduledDate']),
      status: data['status'] as String? ?? 'pending',
      completedDate: data['completedDate'] != null
          ? _parseTimestamp(data['completedDate'])
          : null,
      notes: data['notes'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = <String, dynamic>{
      'ashaId': ashaId,
      'memberId': memberId,
      'familyId': familyId,
      'type': type,
      'description': description,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
    if (completedDate != null) map['completedDate'] = Timestamp.fromDate(completedDate!);
    if (notes != null) map['notes'] = notes;
    return map;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
