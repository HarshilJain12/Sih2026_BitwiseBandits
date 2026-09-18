/// Form field validators used across login and registration screens.
///
/// All validators return null on success, or a localized error key string
/// that the calling widget resolves against AppLocalizations.
class Validators {
  Validators._();

  /// Validates a mobile number.
  ///
  /// Supports standard 10-digit Indian numbers as well as international E.164 numbers
  /// (e.g. +1 650-555-3434 for testing).
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation_required';
    }
    final clean = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.startsWith('+')) {
      final digits = clean.substring(1).replaceAll(RegExp(r'\D'), '');
      if (digits.length < 8 || digits.length > 15) {
        return 'validation_phone';
      }
      return null;
    }
    final digits = clean.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return null;
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return null;
    }
    return 'validation_phone';
  }

  /// Normalizes a phone number into standard E.164 format.
  ///
  /// Defaults to India (+91) for raw 10-digit inputs.
  static String normalizePhoneNumber(String raw) {
    final clean = raw.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.startsWith('+')) {
      final digits = clean.substring(1).replaceAll(RegExp(r'\D'), '');
      return '+$digits';
    }
    final digits = clean.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    return '+91$digits';
  }

  /// Validates a patient's full name.
  ///
  /// Supports spaces and Unicode characters (Devanagari, Latin, etc.)
  /// for English, Hindi, and Marathi users.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation_name';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'validation_name';
    }
    return null;
  }

  /// Validates age (1-120 integer).
  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation_age';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1 || parsed > 120) {
      return 'validation_age';
    }
    return null;
  }

  /// Validates weight in kg (positive number, 1.0 - 500.0).
  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation_weight';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 1.0 || parsed > 500.0) {
      return 'validation_weight';
    }
    return null;
  }

  /// Validates height in cm (positive number, 20.0 - 300.0).
  static String? height(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation_height';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 20.0 || parsed > 300.0) {
      return 'validation_height';
    }
    return null;
  }

  /// Validates a 6-digit OTP.
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation_required';
    }
    if (value.trim().length != 6 ||
        !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'validation_otp';
    }
    return null;
  }

  /// Validates that a field is not empty.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation_required';
    }
    return null;
  }

  /// Validates a password with minimum 6 character length.
  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation_required';
    }
    if (value.trim().length < 6) {
      return 'validation_min_length';
    }
    return null;
  }
}
