import 'package:cloud_firestore/cloud_firestore.dart';

class AwarenessCampaign {
  const AwarenessCampaign({
    required this.campaignId,
    this.alertId,
    required this.title,
    required this.description,
    required this.safetyInstructions,
    required this.hospitalName,
    this.contactInfo,
    required this.targetVillages,
    required this.targetWards,
    required this.targetType, // all, village, ward, hospital
    required this.status, // draft, published
    required this.createdBy, // hospital admin id
    required this.createdAt,
    required this.updatedAt,
  });

  final String campaignId;
  final String? alertId; // linked ASHA alert if any
  final String title;
  final String description;
  final String safetyInstructions;
  final String hospitalName;
  final String? contactInfo;
  final List<String> targetVillages;
  final List<String> targetWards;
  final String targetType;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AwarenessCampaign.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return AwarenessCampaign(
      campaignId: snapshot.id,
      alertId: data['alertId'] as String?,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      safetyInstructions: data['safetyInstructions'] as String? ?? '',
      hospitalName: data['hospitalName'] as String? ?? '',
      contactInfo: data['contactInfo'] as String?,
      targetVillages: List<String>.from(data['targetVillages'] ?? []),
      targetWards: List<String>.from(data['targetWards'] ?? []),
      targetType: data['targetType'] as String? ?? 'all',
      status: data['status'] as String? ?? 'draft',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'safetyInstructions': safetyInstructions,
      'hospitalName': hospitalName,
      'targetVillages': targetVillages,
      'targetWards': targetWards,
      'targetType': targetType,
      'status': status,
      'createdBy': createdBy,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
    if (alertId != null) map['alertId'] = alertId;
    if (contactInfo != null) map['contactInfo'] = contactInfo;
    return map;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
