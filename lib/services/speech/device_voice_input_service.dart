import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'speech_input_service.dart';

/// Production device-level voice input service using [stt.SpeechToText].
///
/// Designed for low-literacy and multi-lingual healthcare accessibility:
/// - Supports Indian English (`en_IN`), Hindi (`hi_IN`), and Marathi (`mr_IN`).
/// - Gracefully falls back if specific regional dialect is unavailable.
/// - Handles permission denial, hardware unavailability, and timeouts safely.
class DeviceVoiceInputService implements SpeechInputService {
  DeviceVoiceInputService({stt.SpeechToText? speechToText})
      : _speech = speechToText ?? stt.SpeechToText();

  final stt.SpeechToText _speech;

  bool _isInitialized = false;
  bool _isAvailable = false;
  List<stt.LocaleName> _systemLocales = [];

  SpeechErrorCallback? _onErrorCallback;
  SpeechStatusCallback? _onStatusCallback;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> isAvailable() async {
    if (_isInitialized) return _isAvailable;
    return await initialize();
  }

  @override
  Future<bool> initialize({
    SpeechErrorCallback? onError,
    SpeechStatusCallback? onStatus,
  }) async {
    if (onError != null) _onErrorCallback = onError;
    if (onStatus != null) _onStatusCallback = onStatus;

    if (_isInitialized) return _isAvailable;

    try {
      _isAvailable = await _speech.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
        debugLogging: kDebugMode,
      );
      _isInitialized = true;

      if (_isAvailable) {
        try {
          _systemLocales = await _speech.locales();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[DeviceVoiceInputService] Could not fetch system locales: $e');
          }
        }
      }

      return _isAvailable;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceVoiceInputService] Initialization failed: $e');
      }
      _isInitialized = true;
      _isAvailable = false;
      return false;
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (kDebugMode) {
      debugPrint('[DeviceVoiceInputService] Speech Error: ${error.errorMsg} (permanent: ${error.permanent})');
    }
    _onErrorCallback?.call(error.errorMsg);
  }

  void _handleSpeechStatus(String status) {
    if (kDebugMode) {
      debugPrint('[DeviceVoiceInputService] Speech Status: $status');
    }
    _onStatusCallback?.call(status);
  }

  @override
  String resolveLocaleId(String languageCode) {
    final cleanCode = languageCode.toLowerCase().trim();

    String targetTag;
    switch (cleanCode) {
      case 'hi':
        targetTag = 'hi_IN';
        break;
      case 'mr':
        targetTag = 'mr_IN';
        break;
      case 'en':
      default:
        targetTag = 'en_IN';
        break;
    }

    if (_systemLocales.isEmpty) {
      return targetTag;
    }

    // 1. Exact match (e.g. hi_IN or hi-IN)
    for (final loc in _systemLocales) {
      final locId = loc.localeId.replaceAll('-', '_');
      if (locId.toLowerCase() == targetTag.toLowerCase()) {
        return loc.localeId;
      }
    }

    // 2. Language prefix match (e.g. "hi" or "mr" or "en")
    for (final loc in _systemLocales) {
      final locId = loc.localeId.replaceAll('-', '_').toLowerCase();
      if (locId.startsWith('${cleanCode}_') || locId == cleanCode) {
        return loc.localeId;
      }
    }

    // 3. Fallback to default target tag
    return targetTag;
  }

  @override
  Future<bool> startListening({
    required SpeechResultCallback onResult,
    SpeechErrorCallback? onError,
    String? localeId,
  }) async {
    if (isListening) {
      if (kDebugMode) {
        debugPrint('[DeviceVoiceInputService] Already listening, ignoring start request.');
      }
      return true;
    }

    final available = await isAvailable();
    if (!available) {
      onError?.call('Speech recognition is not available or microphone permission was denied.');
      return false;
    }

    if (onError != null) {
      _onErrorCallback = onError;
    }

    final targetLocale = localeId ?? resolveLocaleId('en');

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: targetLocale,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.search,
        ),
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceVoiceInputService] Error starting speech listen: $e');
      }
      onError?.call(e.toString());
      return false;
    }
  }

  @override
  Future<void> stopListening() async {
    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DeviceVoiceInputService] Error stopping speech: $e');
        }
      }
    }
  }

  @override
  Future<void> cancelListening() async {
    if (_speech.isListening) {
      try {
        await _speech.cancel();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DeviceVoiceInputService] Error cancelling speech: $e');
        }
      }
    }
  }

  @override
  Future<String?> listenForSpeech({
    String? localeId,
    void Function(String partialText)? onPartialResult,
  }) async {
    final completer = Completer<String?>();
    String lastRecognized = '';

    final started = await startListening(
      localeId: localeId,
      onResult: (words, isFinal) {
        lastRecognized = words;
        onPartialResult?.call(words);
        if (isFinal && !completer.isCompleted) {
          completer.complete(words);
        }
      },
      onError: (err) {
        if (!completer.isCompleted) {
          completer.complete(lastRecognized.isNotEmpty ? lastRecognized : null);
        }
      },
    );

    if (!started) {
      return null;
    }

    // Safety timeout after 12 seconds
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
