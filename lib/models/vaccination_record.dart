import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinationRecord {
  const VaccinationRecord({
    required this.vaccinationId,
    required this.patientId,
    this.memberId,
    required this.chwId, // ASHA worker ID
    required this.vaccineName,
    required this.vaccineType,
    required this.scheduledDate,
    this.administeredDate,
    required this.status, // pending, scheduled, administered, missed
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  final String vaccinationId;
  final String patientId;
  final String? memberId;
  final String chwId;
  final String vaccineName;
  final String vaccineType;
  final DateTime scheduledDate;
  final DateTime? administeredDate;
  final String status;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory VaccinationRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return VaccinationRecord(
      vaccinationId: snapshot.id,
      patientId: data['patientId'] as String? ?? '',
      memberId: data['memberId'] as String?,
      chwId: data['chwId'] as String? ?? '',
      vaccineName: data['vaccineName'] as String? ?? '',
      vaccineType: data['vaccineType'] as String? ?? '',
      scheduledDate: _parseTimestamp(data['scheduledDate']),
      administeredDate: data['administeredDate'] != null
          ? _parseTimestamp(data['administeredDate'])
          : null,
      status: data['status'] as String? ?? 'pending',
      remarks: data['remarks'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = <String, dynamic>{
      'patientId': patientId,
      'chwId': chwId,
      'vaccineName': vaccineName,
      'vaccineType': vaccineType,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
    if (memberId != null) map['memberId'] = memberId;
    if (administeredDate != null) {
      map['administeredDate'] = Timestamp.fromDate(administeredDate!);
    }
    if (remarks != null) map['remarks'] = remarks;
    return map;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
