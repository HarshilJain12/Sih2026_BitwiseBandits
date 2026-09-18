import '../../models/patient.dart';

/// Abstract interface for generating friendly, safe AI Nurse Companion messages.
///
/// Implementations must observe strict safety rules:
/// - NEVER diagnose or claim medical conditions.
/// - NEVER prescribe, stop, or change medication dosage.
/// - Provide safe, supportive, informational guidance only.
abstract class HealthMessageGenerator {
  /// Generates a friendly health companion message for the given [patient].
  ///
  /// Takes the current UI locale code (e.g. 'en', 'hi', 'mr') for localized output.
  Future<String> generateMessage({
    required Patient patient,
    required String localeCode,
    Map<String, dynamic>? medicalRecordsSummary,
  });
}
