import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/patient_qr.dart';

/// Result type for QR validation.
class QrValidationResult {
  const QrValidationResult._({
    required this.success,
    this.patientId,
    this.errorMessage,
  });

  const QrValidationResult.success(String patientId)
      : this._(success: true, patientId: patientId);

  const QrValidationResult.failure(String errorMessage)
      : this._(success: false, errorMessage: errorMessage);

  final bool success;
  final String? patientId;
  final String? errorMessage;
}

/// Service for managing patient QR token generation, storage, and validation.
///
/// QR tokens are stored in `/patientQrCodes/{qrToken}` as secure opaque
/// identifiers. The QR payload format is `SIH_PATIENT:<token>` — no medical
/// data is ever encoded in the QR.
///
/// Key guarantees:
/// - Idempotent: calling [ensurePatientQr] multiple times returns the same token.
/// - Globally unique: cryptographic randomness with 16-char alphanumeric suffix.
/// - Backward compatible: existing patients without QR get one on first access.
class PatientQrService {
  PatientQrService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _tokenPrefix = 'QRT-';
  static const int _tokenLength = 16;
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  CollectionReference<Map<String, dynamic>> get _qrCodesRef =>
      _firestore.collection('patientQrCodes');

  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection('patients');

  /// Generates a cryptographically secure random QR token.
  /// Format: `QRT-XXXXXXXXXXXXXXXX` (16-char alphanumeric suffix).
  String _generateToken() {
    final rng = Random.secure();
    final suffix = String.fromCharCodes(
      Iterable.generate(
        _tokenLength,
        (_) => _chars.codeUnitAt(rng.nextInt(_chars.length)),
      ),
    );
    return '$_tokenPrefix$suffix';
  }

  /// Ensures a patient has a unique QR token assigned.
  ///
  /// **Idempotent**: if the patient already has a QR token, returns the existing one.
  /// If not, generates a new token, stores the mapping in `/patientQrCodes/{qrToken}`,
  /// and updates the patient document with `qrToken` and `qrVersion`.
  ///
  /// Returns the QR token string.
  Future<String> ensurePatientQr(String patientId) async {
    // Check if patient already has a QR token
    final patientDoc = await _patientsRef.doc(patientId).get();
    if (!patientDoc.exists) {
      throw StateError('Patient $patientId does not exist.');
    }

    final existingToken = patientDoc.data()?['qrToken'] as String?;
    if (existingToken != null && existingToken.isNotEmpty) {
      // Verify the QR code document still exists
      final qrDoc = await _qrCodesRef.doc(existingToken).get();
      if (qrDoc.exists) {
        if (kDebugMode) {
          debugPrint('[PatientQrService] Reusing existing QR token for patient $patientId.');
        }
        return existingToken;
      }
      // QR document was lost — regenerate below
    }

    // Generate a new unique token
    String token;
    int attempts = 0;
    do {
      token = _generateToken();
      final existing = await _qrCodesRef.doc(token).get();
      if (!existing.exists) break;
      attempts++;
    } while (attempts < 10);

    if (attempts >= 10) {
      throw StateError('Failed to generate unique QR token after 10 attempts.');
    }

    // Atomic write: QR mapping + patient update
    final batch = _firestore.batch();

    final qr = PatientQr(
      qrToken: token,
      patientId: patientId,
      version: PatientQr.currentVersion,
      status: 'active',
      createdAt: DateTime.now(),
    );

    batch.set(_qrCodesRef.doc(token), qr.toFirestore(useServerTimestamp: true));
    batch.update(_patientsRef.doc(patientId), {
      'qrToken': token,
      'qrVersion': PatientQr.currentVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    if (kDebugMode) {
      debugPrint('[PatientQrService] Generated new QR token for patient $patientId.');
    }

    return token;
  }

  /// Validates a raw QR payload and resolves it to a patient ID.
  ///
  /// Validation chain:
  /// 1. Format check (`SIH_PATIENT:<token>`)
  /// 2. Token existence in `/patientQrCodes/{qrToken}`
  /// 3. Status check (active, not revoked)
  /// 4. Version check (supported version)
  /// 5. Patient existence in `/patients/{patientId}`
  Future<QrValidationResult> validateAndResolveQr(String rawPayload) async {
    // 1. Extract token from payload
    final token = PatientQr.extractToken(rawPayload);
    if (token == null) {
      return const QrValidationResult.failure('Invalid patient QR code.');
    }

    try {
      // 2. Lookup QR code document
      final qrDoc = await _qrCodesRef.doc(token).get();
      if (!qrDoc.exists) {
        return const QrValidationResult.failure('Patient record not found.');
      }

      final qr = PatientQr.fromFirestore(qrDoc);

      // 3. Check status
      if (qr.isRevoked) {
        return const QrValidationResult.failure('This QR code has been revoked.');
      }

      // 4. Check version
      if (qr.version != PatientQr.currentVersion) {
        return const QrValidationResult.failure('Unsupported patient QR code.');
      }

      // 5. Verify patient exists
      final patientDoc = await _patientsRef.doc(qr.patientId).get();
      if (!patientDoc.exists) {
        return const QrValidationResult.failure('Patient record not found.');
      }

      return QrValidationResult.success(qr.patientId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientQrService] QR validation error: $e');
      }
      return const QrValidationResult.failure('Unable to verify QR code. Please try again.');
    }
  }
}
