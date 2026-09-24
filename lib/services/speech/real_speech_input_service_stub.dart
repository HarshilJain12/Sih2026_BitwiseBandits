import 'dart:async';

import 'device_voice_input_service.dart';
import 'speech_input_service.dart';

class RealSpeechInputService implements SpeechInputService {
  final _delegate = DeviceVoiceInputService();

  @override
  bool get isListening => _delegate.isListening;

  @override
  Future<bool> initialize({
    SpeechErrorCallback? onError,
    SpeechStatusCallback? onStatus,
  }) =>
      _delegate.initialize(onError: onError, onStatus: onStatus);

  @override
  Future<bool> isAvailable() => _delegate.isAvailable();

  @override
  String resolveLocaleId(String languageCode) =>
      _delegate.resolveLocaleId(languageCode);

  @override
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    SpeechErrorCallback? onError,
    String? localeId,
  }) =>
      _delegate.startListening(
        onResult: onResult,
        onError: onError,
        localeId: localeId,
      );

  @override
  Future<void> stopListening() => _delegate.stopListening();

  @override
  Future<void> cancelListening() => _delegate.cancelListening();

  @override
  Future<String?> listenForSpeech({
    String? localeId,
    String? lang,
    void Function(String partialText)? onPartialResult,
  }) =>
      _delegate.listenForSpeech(
        localeId: localeId,
        lang: lang,
        onPartialResult: onPartialResult,
      );

  @override
  void dispose() => _delegate.dispose();
}
