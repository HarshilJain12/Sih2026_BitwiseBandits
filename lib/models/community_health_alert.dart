import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityHealthAlert {
  const CommunityHealthAlert({
    required this.alertId,
    required this.ashaId,
    required this.ashaName,
    required this.issueType,
    required this.description,
    required this.village,
    required this.ward,
    required this.severity, // low, medium, high
    required this.status, // pending, verified, rejected, resolved
    this.voiceTranscript,
    this.affectedPopulation,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String alertId;
  final String ashaId;
  final String ashaName;
  final String issueType;
  final String description;
  final String village;
  final String ward;
  final String severity;
  final String status;
  final String? voiceTranscript;
  final int? affectedPopulation;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CommunityHealthAlert.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return CommunityHealthAlert(
      alertId: snapshot.id,
      ashaId: data['ashaId'] as String? ?? '',
      ashaName: data['ashaName'] as String? ?? '',
      issueType: data['issueType'] as String? ?? '',
      description: data['description'] as String? ?? '',
      village: data['village'] as String? ?? '',
      ward: data['ward'] as String? ?? '',
      severity: data['severity'] as String? ?? 'medium',
      status: data['status'] as String? ?? 'pending',
      voiceTranscript: data['voiceTranscript'] as String?,
      affectedPopulation: (data['affectedPopulation'] as num?)?.toInt(),
      photoUrl: data['photoUrl'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = <String, dynamic>{
      'ashaId': ashaId,
      'ashaName': ashaName,
      'issueType': issueType,
      'description': description,
      'village': village,
      'ward': ward,
      'severity': severity,
      'status': status,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
    if (voiceTranscript != null) map['voiceTranscript'] = voiceTranscript;
    if (affectedPopulation != null) map['affectedPopulation'] = affectedPopulation;
    if (photoUrl != null) map['photoUrl'] = photoUrl;
    return map;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
