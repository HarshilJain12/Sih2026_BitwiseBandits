import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for `/patientQrCodes/{qrToken}` Firestore documents.
///
/// Maps an opaque QR token to a canonical Patient ID.
/// The QR code itself only encodes `SIH_PATIENT:<qrToken>` — no medical data.
///
/// Supports:
/// - Version field for forward-compatible payload format changes.
/// - Status field for future QR revocation (`active` / `revoked`).
class PatientQr {
  const PatientQr({
    required this.qrToken,
    required this.patientId,
    this.version = 1,
    this.status = 'active',
    required this.createdAt,
  });

  /// Opaque cryptographic token (format: `QRT-XXXXXXXXXXXXXXXX`).
  final String qrToken;

  /// Canonical Patient ID (format: `P-XXXXXXXXXX`).
  final String patientId;

  /// Payload version for forward compatibility. Currently `1`.
  final int version;

  /// QR status: `'active'` or `'revoked'`.
  final String status;

  /// When this QR mapping was created.
  final DateTime createdAt;

  /// The prefix used in QR payload encoding.
  static const String payloadPrefix = 'SIH_PATIENT:';

  /// The current supported QR version.
  static const int currentVersion = 1;

  /// Returns the full QR payload string: `SIH_PATIENT:<qrToken>`.
  String get payload => '$payloadPrefix$qrToken';

  /// Whether this QR is currently active and usable.
  bool get isActive => status == 'active';

  /// Whether this QR has been revoked.
  bool get isRevoked => status == 'revoked';

  /// Extracts the token from a raw QR payload string.
  /// Returns `null` if the format is invalid.
  static String? extractToken(String rawPayload) {
    if (!rawPayload.startsWith(payloadPrefix)) return null;
    final token = rawPayload.substring(payloadPrefix.length).trim();
    if (token.isEmpty) return null;
    return token;
  }

  /// Creates a [PatientQr] from a Firestore document snapshot.
  factory PatientQr.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return PatientQr(
      qrToken: data['qrToken'] as String? ?? snapshot.id,
      patientId: data['patientId'] as String? ?? '',
      version: (data['version'] as num?)?.toInt() ?? 1,
      status: data['status'] as String? ?? 'active',
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  /// Converts this [PatientQr] to a Firestore-compatible map.
  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      'qrToken': qrToken,
      'patientId': patientId,
      'version': version,
      'status': status,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  String toString() =>
      'PatientQr(token=$qrToken, patientId=$patientId, v=$version, status=$status)';
}
