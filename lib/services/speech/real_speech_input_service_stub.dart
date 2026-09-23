import 'dart:async';

import 'mock_speech_input_service.dart';
import 'speech_input_service.dart';

class RealSpeechInputService implements SpeechInputService {
  final _fallback = MockSpeechInputService();

  @override
  Future<bool> isAvailable() async => _fallback.isAvailable();

  @override
  Future<String?> listenForSpeech({String lang = 'en-IN'}) async {
    return _fallback.listenForSpeech();
  }
}
