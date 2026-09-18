import 'dart:math';

/// Generates collision-safe unique Patient IDs in format `P-XXXXXXXXXX`.
///
/// Uses cryptographically secure randomness (`Random.secure()`) with a
/// 10-character alphanumeric suffix (`[A-Z0-9]`), providing
/// 36^10 ≈ 3.65 quadrillion possible combinations.
///
/// The generation is performed entirely locally without client-side Firestore
/// reads, aligning with Firestore security rules where unowned documents
/// cannot be probed.
class PatientIdGenerator {
  const PatientIdGenerator();

  static const String _prefix = 'P-';
  static const int _suffixLength = 10;
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Generates a unique Patient ID formatted as `P-XXXXXXXXXX`.
  String generate([Random? random]) {
    return generateCandidate(random);
  }

  /// Generates a candidate ID string.
  static String generateCandidate([Random? random]) {
    final rng = random ?? Random.secure();
    final suffix = String.fromCharCodes(
      Iterable.generate(
        _suffixLength,
        (_) => _chars.codeUnitAt(rng.nextInt(_chars.length)),
      ),
    );
    return '$_prefix$suffix';
  }

  /// Validates that a string matches the expected Patient ID format.
  static bool isValidFormat(String id) {
    if (!id.startsWith(_prefix)) return false;
    final suffix = id.substring(_prefix.length);
    if (suffix.length != _suffixLength) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(suffix);
  }
}
