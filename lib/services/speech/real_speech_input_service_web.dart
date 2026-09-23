import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'speech_input_service.dart';

class RealSpeechInputService implements SpeechInputService {
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
  Future<String?> listenForSpeech({String lang = 'en-IN'}) async {
    final dynamic speechConstructor =
        js_util.getProperty(html.window, 'SpeechRecognition') ??
        js_util.getProperty(html.window, 'webkitSpeechRecognition');

    if (speechConstructor == null) {
      throw Exception(
        'Speech recognition is not supported in this browser. Please use Chrome or Edge.',
      );
    }

    final completer = Completer<String?>();

    try {
      final recognition = js_util.callConstructor(speechConstructor, []);
      js_util.setProperty(recognition, 'lang', lang);
      js_util.setProperty(recognition, 'interimResults', false);
      js_util.setProperty(recognition, 'maxAlternatives', 1);

      // onresult
      js_util.setProperty(
        recognition,
        'onresult',
        js_util.allowInterop((dynamic event) {
          try {
            final results = js_util.getProperty(event, 'results');
            if (results != null) {
              final firstResult = js_util.callMethod(results, 'item', [0]);
              final firstAlternative = js_util.callMethod(firstResult, 'item', [0]);
              final transcript = js_util.getProperty(firstAlternative, 'transcript');
              if (!completer.isCompleted) {
                completer.complete(transcript?.toString().trim());
              }
            }
          } catch (_) {
            if (!completer.isCompleted) completer.complete(null);
          }
        }),
      );

      // onerror
      js_util.setProperty(
        recognition,
        'onerror',
        js_util.allowInterop((dynamic event) {
          final error = js_util.getProperty(event, 'error');
          if (!completer.isCompleted) {
            if (error == 'not-allowed') {
              completer.completeError(
                'Microphone permission denied. Please allow microphone access in your browser address bar.',
              );
            } else if (error == 'no-speech') {
              completer.complete(null);
            } else {
              completer.completeError('Speech recognition error: $error');
            }
          }
        }),
      );

      // onend
      js_util.setProperty(
        recognition,
        'onend',
        js_util.allowInterop(() {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }),
      );

      js_util.callMethod(recognition, 'start', []);
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError('Could not start speech recognition: $e');
      }
    }

    return completer.future;
  }
}
