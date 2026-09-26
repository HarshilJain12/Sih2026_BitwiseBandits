/// Application-wide constants.
/// The app title is a configurable placeholder — update [kAppTitle] once the
/// product name is finalized without touching any other file.
class AppConstants {
  AppConstants._();

  /// Application title
  static const String kAppTitle = 'Arogya Seva';
  static const String kAppTagline = 'Connecting Every Step of Your Healthcare Journey';
  static const String kLogoAsset = 'assets/images/logo.png';

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
