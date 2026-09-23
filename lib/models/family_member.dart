import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMember {
  const FamilyMember({
    required this.memberId,
    required this.familyId,
    this.patientId, // Null if synthetic, linked if exists
    required this.name,
    required this.age,
    required this.gender,
    required this.relationship,
    this.phone,
    required this.pregnancyStatus,
    this.expectedDeliveryMonth,
    required this.infantStatus,
    this.nutritionStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String memberId;
  final String familyId;
  final String? patientId;
  final String name;
  final int age;
  final String gender;
  final String relationship;
  final String? phone;
  
  final bool pregnancyStatus;
  final String? expectedDeliveryMonth; // MM-YYYY
  
  final bool infantStatus;
  final String? nutritionStatus;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FamilyMember.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return FamilyMember(
      memberId: snapshot.id,
      familyId: data['familyId'] as String? ?? '',
      patientId: data['patientId'] as String?,
      name: data['name'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      gender: data['gender'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      phone: data['phone'] as String?,
      pregnancyStatus: data['pregnancyStatus'] as bool? ?? false,
      expectedDeliveryMonth: data['expectedDeliveryMonth'] as String?,
      infantStatus: data['infantStatus'] as bool? ?? false,
      nutritionStatus: data['nutritionStatus'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = <String, dynamic>{
      'familyId': familyId,
      'name': name,
      'age': age,
      'gender': gender,
      'relationship': relationship,
      'pregnancyStatus': pregnancyStatus,
      'infantStatus': infantStatus,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
    if (patientId != null) map['patientId'] = patientId;
    if (phone != null) map['phone'] = phone;
    if (expectedDeliveryMonth != null) map['expectedDeliveryMonth'] = expectedDeliveryMonth;
    if (nutritionStatus != null) map['nutritionStatus'] = nutritionStatus;
    
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
