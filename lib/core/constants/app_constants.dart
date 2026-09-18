/// Application-wide constants.
/// The app title is a configurable placeholder — update [kAppTitle] once the
/// product name is finalized without touching any other file.
class AppConstants {
  AppConstants._();

  /// Temporary placeholder — replace with the finalized product name.
  static const String kAppTitle = 'Healthcare App';

  /// Storage keys
  static const String kSelectedLanguageKey = 'selected_language_code';

  /// Supported language codes
  static const String kLangEn = 'en';
  static const String kLangHi = 'hi';
  static const String kLangMr = 'mr';

  /// Mock OTP for development — remove when real OTP service is integrated.
  static const String kMockOtp = '123456';

  /// OTP resend timer in seconds
  static const int kOtpResendSeconds = 30;
}
