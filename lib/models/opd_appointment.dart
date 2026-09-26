import 'package:cloud_firestore/cloud_firestore.dart';

/// Strongly-typed model for hospital OPD / Appointment slips and records.
///
/// Supports both registered patients (linked to existing patientId and QR)
/// and walk-in patients (lightweight profile without permanent full registration or QR).
class OpdAppointment {
  const OpdAppointment({
    required this.appointmentId,
    required this.hospitalId,
    this.patientId,
    required this.patientName,
    this.patientAge,
    this.patientGender,
    required this.doctorCategory,
    this.doctorId,
    this.doctorName,
    required this.appointmentDate,
    required this.appointmentTime,
    this.patientType = 'registered',
    this.qrLinked = false,
    this.qrPayload,
    this.status = 'upcoming',
    required this.createdAt,
  });

  /// Unique appointment identifier (e.g., `OPD-1002938471`).
  final String appointmentId;

  /// Hospital / Health Center ID (e.g. `ADMIN001`, `HOSP001`).
  final String hospitalId;

  /// Canonical Patient ID (null for walk-in patients).
  final String? patientId;

  /// Patient display name.
  final String patientName;

  /// Patient age in years.
  final int? patientAge;

  /// Patient gender (e.g. 'Male', 'Female', 'Other').
  final String? patientGender;

  /// Selected doctor / specialty category (e.g., 'General Medicine', 'Cardiology').
  final String doctorCategory;

  /// Assigned doctor ID if available.
  final String? doctorId;

  /// Assigned doctor name if available.
  final String? doctorName;

  /// Date of the appointment.
  final DateTime appointmentDate;

  /// Formatted time string (e.g. '04:20 PM').
  final String appointmentTime;

  /// 'registered' or 'walk_in'.
  final String patientType;

  /// Whether an existing patient QR code is linked to this slip.
  final bool qrLinked;

  /// The patient's existing QR code payload/token if registered.
  final String? qrPayload;

  /// Appointment status: 'upcoming', 'current', 'completed', 'cancelled'.
  final String status;

  /// Timestamp when created.
  final DateTime createdAt;

  bool get isWalkIn => patientType == 'walk_in' || patientId == null;
  bool get isRegistered => !isWalkIn && qrLinked;

  factory OpdAppointment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return OpdAppointment.fromMap(data, id: snapshot.id);
  }

  factory OpdAppointment.fromMap(Map<String, dynamic> data, {String? id}) {
    return OpdAppointment(
      appointmentId: data['appointmentId'] as String? ?? id ?? '',
      hospitalId: data['hospitalId'] as String? ?? 'ADMIN001',
      patientId: data['patientId'] as String?,
      patientName: data['patientName'] as String? ?? '',
      patientAge: (data['patientAge'] as num?)?.toInt(),
      patientGender: data['patientGender'] as String?,
      doctorCategory: data['doctorCategory'] as String? ?? 'General Medicine',
      doctorId: data['doctorId'] as String?,
      doctorName: data['doctorName'] as String?,
      appointmentDate: _parseTimestamp(data['appointmentDate']),
      appointmentTime: data['appointmentTime'] as String? ?? '',
      patientType: data['patientType'] as String? ??
          (data['patientId'] != null ? 'registered' : 'walk_in'),
      qrLinked: data['qrLinked'] as bool? ?? (data['patientId'] != null),
      qrPayload: data['qrPayload'] as String?,
      status: data['status'] as String? ?? 'upcoming',
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = <String, dynamic>{
      'appointmentId': appointmentId,
      'hospitalId': hospitalId,
      'patientName': patientName,
      'doctorCategory': doctorCategory,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'patientType': patientType,
      'qrLinked': qrLinked,
      'status': status,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };

    if (patientId != null) map['patientId'] = patientId;
    if (patientAge != null) map['patientAge'] = patientAge;
    if (patientGender != null) map['patientGender'] = patientGender;
    if (doctorId != null) map['doctorId'] = doctorId;
    if (doctorName != null) map['doctorName'] = doctorName;
    if (qrPayload != null) map['qrPayload'] = qrPayload;

    return map;
  }

  OpdAppointment copyWith({
    String? appointmentId,
    String? hospitalId,
    String? patientId,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? doctorCategory,
    String? doctorId,
    String? doctorName,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? patientType,
    bool? qrLinked,
    String? qrPayload,
    String? status,
    DateTime? createdAt,
  }) {
    return OpdAppointment(
      appointmentId: appointmentId ?? this.appointmentId,
      hospitalId: hospitalId ?? this.hospitalId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      doctorCategory: doctorCategory ?? this.doctorCategory,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      patientType: patientType ?? this.patientType,
      qrLinked: qrLinked ?? this.qrLinked,
      qrPayload: qrPayload ?? this.qrPayload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  @override
  String toString() =>
      'OpdAppointment(id=$appointmentId, patient=$patientName, category=$doctorCategory, type=$patientType, qr=$qrLinked)';
}
