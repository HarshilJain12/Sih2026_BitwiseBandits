import 'package:cloud_firestore/cloud_firestore.dart';

class AshaWorker {
  const AshaWorker({
    required this.id,
    required this.ashaId,
    required this.name,
    required this.phone,
    required this.passwordHash,
    required this.state,
    required this.district,
    required this.block,
    required this.village,
    required this.wardId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ashaId;
  final String name;
  final String phone;
  final String passwordHash;
  final String state;
  final String district;
  final String block;
  final String village;
  final String wardId;
  final DateTime createdAt;
  final DateTime updatedAt;

  static final AshaWorker demoWorker = AshaWorker(
    id: 'demo_asha_001',
    ashaId: 'ASHA001',
    name: 'Sunita Sharma',
    phone: '+91 9876543210',
    passwordHash: 'proto_hash_MTIzNDU2',
    state: 'Maharashtra',
    district: 'Pune',
    block: 'Haveli',
    village: 'Kondhwa',
    wardId: 'Ward 4',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  factory AshaWorker.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return AshaWorker(
      id: snapshot.id,
      ashaId: data['ashaId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      passwordHash: data['passwordHash'] as String? ?? '',
      state: data['state'] as String? ?? '',
      district: data['district'] as String? ?? '',
      block: data['block'] as String? ?? '',
      village: data['village'] as String? ?? '',
      wardId: data['wardId'] as String? ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      'ashaId': ashaId,
      'name': name,
      'phone': phone,
      'passwordHash': passwordHash,
      'state': state,
      'district': district,
      'block': block,
      'village': village,
      'wardId': wardId,
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
