import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  const Family({
    required this.familyId,
    required this.headOfFamilyName,
    required this.address,
    required this.village,
    required this.ward,
    required this.block,
    required this.district,
    required this.contactNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  final String familyId;
  final String headOfFamilyName;
  final String address;
  final String village;
  final String ward;
  final String block;
  final String district;
  final String contactNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Family.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return Family(
      familyId: snapshot.id,
      headOfFamilyName: data['headOfFamilyName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      village: data['village'] as String? ?? '',
      ward: data['ward'] as String? ?? '',
      block: data['block'] as String? ?? '',
      district: data['district'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      'headOfFamilyName': headOfFamilyName,
      'address': address,
      'village': village,
      'ward': ward,
      'block': block,
      'district': district,
      'contactNumber': contactNumber,
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
