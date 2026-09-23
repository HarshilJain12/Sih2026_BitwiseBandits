import 'package:cloud_firestore/cloud_firestore.dart';

class HomeVisit {
  const HomeVisit({
    required this.visitId,
    required this.ashaId,
    required this.familyId,
    required this.date,
    required this.status, // e.g. "completed", "scheduled"
    required this.createdAt,
    required this.updatedAt,
  });

  final String visitId;
  final String ashaId;
  final String familyId;
  final DateTime date;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HomeVisit.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return HomeVisit(
      visitId: snapshot.id,
      ashaId: data['ashaId'] as String? ?? '',
      familyId: data['familyId'] as String? ?? '',
      date: _parseTimestamp(data['date']),
      status: data['status'] as String? ?? 'completed',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      'ashaId': ashaId,
      'familyId': familyId,
      'date': Timestamp.fromDate(date),
      'status': status,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
