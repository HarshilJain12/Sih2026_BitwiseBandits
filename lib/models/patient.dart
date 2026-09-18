import 'package:cloud_firestore/cloud_firestore.dart';

import 'patient_location.dart';

/// Strongly typed model for the `/patients/{patientId}` Firestore document.
///
/// Represents an individual human being's patient profile.
///
/// Important design principles:
/// - Patient ID ≠ Firebase UID ≠ Phone Number (three separate concepts)
/// - One account may own multiple patient profiles (family members)
/// - Only identity and location fields are stored in this phase — no medical history,
///   documents, appointments, or prescriptions
class Patient {
  const Patient({
    required this.patientId,
    required this.ownerUid,
    required this.name,
    required this.phoneNumber,
    this.age,
    this.weightKg,
    this.heightCm,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
  });

  /// Human-readable unique identifier in format `P-XXXXXXXXXX`.
  final String patientId;

  /// Firebase UID of the account that created/owns this patient profile.
  final String ownerUid;

  /// Full name of the patient.
  final String name;

  /// Phone number associated with this patient profile.
  /// Initially the verified phone from the owning account.
  final String phoneNumber;

  /// Patient age in years.
  final int? age;

  /// Patient weight in kilograms.
  final double? weightKg;

  /// Patient height in centimeters.
  final double? heightCm;

  /// Patient geographic location (optional, backward-compatible).
  final PatientLocation? location;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Patient status. Currently: `"active"`.
  /// Future phases may add: `"inactive"`, `"transferred"`, etc.
  final String status;

  /// Creates a [Patient] from a Firestore document snapshot.
  /// Handles missing or legacy fields safely for backward compatibility.
  factory Patient.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    PatientLocation? parsedLocation;
    if (data['location'] is Map<String, dynamic>) {
      parsedLocation = PatientLocation.fromMap(
        data['location'] as Map<String, dynamic>,
      );
    }

    return Patient(
      patientId: data['patientId'] as String? ?? snapshot.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      age: (data['age'] as num?)?.toInt(),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      location: parsedLocation,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      status: data['status'] as String? ?? 'active',
    );
  }

  /// Converts this [Patient] to a Firestore-compatible map.
  ///
  /// Uses [FieldValue.serverTimestamp] when [useServerTimestamp] is true
  /// (recommended for initial creation).
  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = <String, dynamic>{
      'patientId': patientId,
      'ownerUid': ownerUid,
      'name': name,
      'phoneNumber': phoneNumber,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
      'status': status,
    };

    if (age != null) {
      map['age'] = age;
    }
    if (weightKg != null) {
      map['weightKg'] = weightKg;
    }
    if (heightCm != null) {
      map['heightCm'] = heightCm;
    }
    if (location != null) {
      map['location'] = location!.toMap();
    }

    return map;
  }

  /// Creates a copy with the given fields replaced.
  Patient copyWith({
    String? patientId,
    String? ownerUid,
    String? name,
    String? phoneNumber,
    int? age,
    double? weightKg,
    double? heightCm,
    PatientLocation? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return Patient(
      patientId: patientId ?? this.patientId,
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  /// Safely parses a Firestore Timestamp or returns epoch if null/invalid.
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  String toString() =>
      'Patient(id=$patientId, owner=$ownerUid, name=$name, age=$age, location=$location)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Patient &&
          runtimeType == other.runtimeType &&
          patientId == other.patientId;

  @override
  int get hashCode => patientId.hashCode;
}
