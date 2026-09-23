import 'package:cloud_firestore/cloud_firestore.dart';

class HealthObservation {
  const HealthObservation({
    required this.observationId,
    required this.visitId,
    required this.memberId,
    this.generalHealth, // e.g. "Fever, Cough"
    this.maternalHealth,
    this.infantHealth,
    this.nutrition,
    required this.followUpRequired,
    this.followUpDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String observationId;
  final String visitId;
  final String memberId;
  final String? generalHealth;
  final String? maternalHealth;
  final String? infantHealth;
  final String? nutrition;
  final bool followUpRequired;
  final DateTime? followUpDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HealthObservation.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return HealthObservation(
      observationId: snapshot.id,
      visitId: data['visitId'] as String? ?? '',
      memberId: data['memberId'] as String? ?? '',
      generalHealth: data['generalHealth'] as String?,
      maternalHealth: data['maternalHealth'] as String?,
      infantHealth: data['infantHealth'] as String?,
      nutrition: data['nutrition'] as String?,
      followUpRequired: data['followUpRequired'] as bool? ?? false,
      followUpDate: data['followUpDate'] != null ? _parseTimestamp(data['followUpDate']) : null,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = <String, dynamic>{
      'visitId': visitId,
      'memberId': memberId,
      'followUpRequired': followUpRequired,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
    if (generalHealth != null) map['generalHealth'] = generalHealth;
    if (maternalHealth != null) map['maternalHealth'] = maternalHealth;
    if (infantHealth != null) map['infantHealth'] = infantHealth;
    if (nutrition != null) map['nutrition'] = nutrition;
    if (followUpDate != null) map['followUpDate'] = Timestamp.fromDate(followUpDate!);
    return map;
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
