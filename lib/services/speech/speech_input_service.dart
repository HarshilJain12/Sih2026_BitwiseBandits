/// Callback signature for voice recognition result updates.
typedef SpeechResultCallback = void Function(String recognizedWords, bool isFinal);

/// Callback signature for speech recognition error events.
typedef SpeechErrorCallback = void Function(String errorMessage);

/// Callback signature for speech listening status changes.
typedef SpeechStatusCallback = void Function(String status);

/// Abstract interface for voice speech recognition.
abstract class SpeechInputService {
  /// Initializes the speech recognition engine.
  Future<bool> initialize({
    SpeechErrorCallback? onError,
    SpeechStatusCallback? onStatus,
  });

  /// Whether speech recognition is initialized and available on this device.
  Future<bool> isAvailable();

  /// Whether the service is currently actively listening to the microphone.
  bool get isListening;

  /// Starts listening for speech input using the specified [localeId] (e.g., 'en_IN', 'hi_IN', 'mr_IN').
  ///
  /// Updates [onResult] with partial or final transcribed text.
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    SpeechErrorCallback? onError,
    String? localeId,
  });

  /// Stops listening and processes the final transcribed speech.
  Future<void> stopListening();

  /// Cancels listening and discards current utterance.
  Future<void> cancelListening();

  /// Resolves the best available locale identifier for a language code ('en', 'hi', 'mr').
  String resolveLocaleId(String languageCode);

  /// Convenience one-shot method that listens and returns the final transcribed string.
  Future<String?> listenForSpeech({
    String? localeId,
    void Function(String partialText)? onPartialResult,
  });

  /// Releases resources.
  void dispose();
}
