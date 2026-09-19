import 'dart:async';
import 'dart:math';

import 'speech_input_service.dart';

/// Testable and demo mock implementation of [SpeechInputService].
class MockSpeechInputService implements SpeechInputService {
  MockSpeechInputService({
    this.mockAvailable = true,
    this.mockResult,
    this.mockError,
    this.simulatedDelay = const Duration(milliseconds: 200),
  });

  final bool mockAvailable;
  final String? mockResult;
  final String? mockError;
  final Duration simulatedDelay;
  final Random _random = Random();

  bool _isListening = false;
  int startListeningCallCount = 0;
  String? lastRequestedLocaleId;

  static const List<String> _sampleVoiceInputs = [
    'I have severe stomach pain since morning',
    'मुझे दांत में बहुत तेज दर्द हो रहा है',
    'माझ्या लहान मुलाला कालपासून ताप आहे',
    'I need a skin specialist doctor for rash',
    'छाती में दर्द और सांस लेने में तकलीफ हो रही है',
  ];

  Timer? _activeTimer;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize({
    SpeechErrorCallback? onError,
    SpeechStatusCallback? onStatus,
  }) async {
    return mockAvailable;
  }

  @override
  Future<bool> isAvailable() async => mockAvailable;

  @override
  String resolveLocaleId(String languageCode) {
    switch (languageCode.toLowerCase().trim()) {
      case 'hi':
        return 'hi_IN';
      case 'mr':
        return 'mr_IN';
      case 'en':
      default:
        return 'en_IN';
    }
  }

  @override
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    SpeechErrorCallback? onError,
    String? localeId,
  }) async {
    if (_isListening) {
      // Avoid duplicate simultaneous sessions
      return true;
    }

    _activeTimer?.cancel();
    startListeningCallCount++;
    lastRequestedLocaleId = localeId;

    if (!mockAvailable) {
      onError?.call(mockError ?? 'Speech recognition unavailable');
      return false;
    }

    _isListening = true;

    if (mockError != null) {
      _isListening = false;
      onError?.call(mockError!);
      return false;
    }

    final speechText = mockResult ?? _sampleVoiceInputs[_random.nextInt(_sampleVoiceInputs.length)];

    // Simulate partial result then final result
    _activeTimer = Timer(simulatedDelay, () {
      if (_isListening) {
        onResult(speechText, true);
        _isListening = false;
      }
    });

    return true;
  }

  @override
  Future<void> stopListening() async {
    _activeTimer?.cancel();
    _activeTimer = null;
    _isListening = false;
  }

  @override
  Future<void> cancelListening() async {
    _activeTimer?.cancel();
    _activeTimer = null;
    _isListening = false;
  }

  @override
  Future<String?> listenForSpeech({
    String? localeId,
    void Function(String partialText)? onPartialResult,
  }) async {
    final completer = Completer<String?>();
    final ok = await startListening(
      localeId: localeId,
      onResult: (text, isFinal) {
        onPartialResult?.call(text);
        if (isFinal && !completer.isCompleted) {
          completer.complete(text);
        }
      },
      onError: (err) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    if (!ok) return null;
    return completer.future;
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    _activeTimer = null;
    _isListening = false;
  }
}
