import 'package:cloud_firestore/cloud_firestore.dart';

/// Strongly typed model for the `/accounts/{firebaseUid}` Firestore document.
///
/// Represents the authenticated phone account — NOT an individual patient.
/// One account (phone number) may manage multiple independent patient profiles.
class Account {
  const Account({
    required this.firebaseUid,
    required this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.accountType = 'patient',
  });

  final String firebaseUid;
  final String phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The type of account. Currently only `"patient"` is supported.
  /// Future phases may add `"asha"`, `"doctor"`, `"hospitalAdmin"`.
  final String accountType;

  /// Creates an [Account] from a Firestore document snapshot.
  factory Account.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Account(
      firebaseUid: data['firebaseUid'] as String? ?? snapshot.id,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      accountType: data['accountType'] as String? ?? 'patient',
    );
  }

  /// Converts this [Account] to a Firestore-compatible map.
  ///
  /// Uses [FieldValue.serverTimestamp] for timestamps when [useServerTimestamp]
  /// is true (recommended for initial creation).
  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      'firebaseUid': firebaseUid,
      'phoneNumber': phoneNumber,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
      'accountType': accountType,
    };
  }

  /// Creates a copy of this account with the given fields replaced.
  Account copyWith({
    String? firebaseUid,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accountType,
  }) {
    return Account(
      firebaseUid: firebaseUid ?? this.firebaseUid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountType: accountType ?? this.accountType,
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
      'Account(uid=$firebaseUid, phone=$phoneNumber, type=$accountType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          firebaseUid == other.firebaseUid;

  @override
  int get hashCode => firebaseUid.hashCode;
}
