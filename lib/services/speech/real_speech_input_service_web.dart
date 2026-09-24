import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'speech_input_service.dart';

class RealSpeechInputService implements SpeechInputService {
  bool _isListening = false;
  dynamic _activeRecognition;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize({
    SpeechErrorCallback? onError,
    SpeechStatusCallback? onStatus,
  }) async {
    return isAvailable();
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return js_util.hasProperty(html.window, 'SpeechRecognition') ||
          js_util.hasProperty(html.window, 'webkitSpeechRecognition');
    } catch (_) {
      return false;
    }
  }

  @override
  String resolveLocaleId(String languageCode) {
    switch (languageCode.toLowerCase().trim()) {
      case 'hi':
        return 'hi-IN';
      case 'mr':
        return 'mr-IN';
      case 'en':
      default:
        return 'en-IN';
    }
  }

  @override
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    SpeechErrorCallback? onError,
    String? localeId,
  }) async {
    final dynamic speechConstructor =
        js_util.getProperty(html.window, 'SpeechRecognition') ??
        js_util.getProperty(html.window, 'webkitSpeechRecognition');

    if (speechConstructor == null) {
      onError?.call(
        'Speech recognition is not supported in this browser. Please use Chrome or Edge.',
      );
      return false;
    }

    try {
      final recognition = js_util.callConstructor(speechConstructor, []);
      _activeRecognition = recognition;
      js_util.setProperty(recognition, 'lang', localeId ?? 'en-IN');
      js_util.setProperty(recognition, 'interimResults', true);
      js_util.setProperty(recognition, 'maxAlternatives', 1);

      js_util.setProperty(
        recognition,
        'onresult',
        js_util.allowInterop((dynamic event) {
          try {
            final results = js_util.getProperty(event, 'results');
            if (results != null) {
              final firstResult = js_util.callMethod(results, 'item', [0]);
              final isFinal = js_util.getProperty(firstResult, 'isFinal') == true;
              final firstAlternative = js_util.callMethod(firstResult, 'item', [0]);
              final transcript = js_util.getProperty(firstAlternative, 'transcript')?.toString().trim();
              if (transcript != null && transcript.isNotEmpty) {
                onResult(transcript, isFinal);
              }
            }
          } catch (_) {}
        }),
      );

      js_util.setProperty(
        recognition,
        'onerror',
        js_util.allowInterop((dynamic event) {
          final error = js_util.getProperty(event, 'error');
          _isListening = false;
          if (error == 'not-allowed') {
            onError?.call('Microphone permission denied. Please allow microphone access in browser.');
          } else if (error != 'no-speech') {
            onError?.call('Speech recognition error: $error');
          }
        }),
      );

      js_util.setProperty(
        recognition,
        'onend',
        js_util.allowInterop(() {
          _isListening = false;
        }),
      );

      js_util.callMethod(recognition, 'start', []);
      _isListening = true;
      return true;
    } catch (e) {
      _isListening = false;
      onError?.call('Could not start speech recognition: $e');
      return false;
    }
  }

  @override
  Future<void> stopListening() async {
    if (_activeRecognition != null) {
      try {
        js_util.callMethod(_activeRecognition, 'stop', []);
      } catch (_) {}
      _isListening = false;
    }
  }

  @override
  Future<void> cancelListening() async {
    if (_activeRecognition != null) {
      try {
        js_util.callMethod(_activeRecognition, 'abort', []);
      } catch (_) {}
      _isListening = false;
    }
  }

  @override
  Future<String?> listenForSpeech({
    String? localeId,
    String? lang,
    void Function(String partialText)? onPartialResult,
  }) async {
    final completer = Completer<String?>();
    String lastRecognized = '';

    final ok = await startListening(
      localeId: localeId ?? lang ?? 'en-IN',
      onResult: (text, isFinal) {
        lastRecognized = text;
        onPartialResult?.call(text);
        if (isFinal && !completer.isCompleted) {
          completer.complete(text);
        }
      },
      onError: (err) {
        if (!completer.isCompleted) {
          completer.complete(lastRecognized.isNotEmpty ? lastRecognized : null);
        }
      },
    );

    if (!ok) return null;

    Timer(const Duration(seconds: 12), () {
      if (!completer.isCompleted) {
        stopListening();
        completer.complete(lastRecognized.isNotEmpty ? lastRecognized : null);
      }
    });

    return completer.future;
  }

  @override
  void dispose() {
    cancelListening();
  }
}
