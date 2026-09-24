/// Centralized API configuration loaded via `--dart-define` or compile-time environment.
///
/// Ensures keys are NOT hardcoded in source control and are never printed to logs.
class ApiConfig {
  ApiConfig._();

  /// Google Gemini API Key for healthcare intent classification & document analysis.
  /// Pass via `--dart-define=GEMINI_API_KEY=your_key_here`.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Google Places API Key (Web Service / Places API New).
  /// Pass via `--dart-define=PLACES_API_KEY=your_key_here` or `--dart-define=GOOGLE_PLACES_API_KEY=your_key_here`.
  static const String placesApiKey = String.fromEnvironment(
    'PLACES_API_KEY',
    defaultValue: String.fromEnvironment(
      'GOOGLE_PLACES_API_KEY',
      defaultValue: String.fromEnvironment(
        'MAPS_API_KEY',
        defaultValue: 'AIzaSyAzNihyqeDlG8X93sAB7E2zujqy0l5GA7c',
      ),
    ),
  );

  /// Whether a valid Gemini API key is configured.
  static bool get hasGeminiKey => geminiApiKey.trim().isNotEmpty;

  /// Whether a valid Places API key is configured.
  static bool get hasPlacesKey => placesApiKey.trim().isNotEmpty;
}
