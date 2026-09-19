import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for `/appointments/{appointmentId}` Firestore documents.
///
/// Represents a scheduled medical appointment between a patient and doctor.
class Appointment {
  const Appointment({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.scheduledAt,
    this.status = 'upcoming',
    this.type = 'consultation',
    this.notes,
    required this.createdAt,
  });

  /// Unique appointment identifier (format: `APT-XXXXXXXXXX`).
  final String appointmentId;

  /// Patient ID (format: `P-XXXXXXXXXX`).
  final String patientId;

  /// Patient display name.
  final String patientName;

  /// Doctor identifier (login ID / staff ID).
  final String doctorId;

  /// Doctor display name.
  final String doctorName;

  /// Scheduled date and time.
  final DateTime scheduledAt;

  /// Appointment status: `'upcoming'`, `'current'`, `'completed'`, `'cancelled'`.
  final String status;

  /// Appointment type: `'consultation'`, `'follow_up'`, `'routine_checkup'`.
  final String type;

  /// Optional notes about the appointment.
  final String? notes;

  /// When this appointment was created.
  final DateTime createdAt;

  /// Whether the appointment is scheduled for today.
  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  /// Whether the appointment is currently active (today + upcoming/current).
  bool get isCurrent =>
      isToday && (status == 'upcoming' || status == 'current');

  factory Appointment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return Appointment(
      appointmentId: data['appointmentId'] as String? ?? snapshot.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      scheduledAt: _parseTimestamp(data['scheduledAt']),
      status: data['status'] as String? ?? 'upcoming',
      type: data['type'] as String? ?? 'consultation',
      notes: data['notes'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = <String, dynamic>{
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': status,
      'type': type,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
    if (notes != null) {
      map['notes'] = notes;
    }
    return map;
  }

  Appointment copyWith({
    String? appointmentId,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    DateTime? scheduledAt,
    String? status,
    String? type,
    String? notes,
    DateTime? createdAt,
  }) {
    return Appointment(
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  String toString() =>
      'Appointment(id=$appointmentId, patient=$patientName, doctor=$doctorName, at=$scheduledAt, status=$status)';
}
