/// Abstract interface for voice speech recognition.
abstract class SpeechInputService {
  /// Listens for voice speech and returns transcribed text.
  Future<String?> listenForSpeech({String lang = 'en-IN'});

  /// Whether speech recognition is currently available on the device.
  Future<bool> isAvailable();
}
