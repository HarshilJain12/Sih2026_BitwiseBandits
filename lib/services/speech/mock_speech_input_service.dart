import 'dart:math';
import 'speech_input_service.dart';

/// Prototype mock implementation of [SpeechInputService].
///
/// Provides sample spoken health descriptions in English/Hindi for demo.
class MockSpeechInputService implements SpeechInputService {
  final Random _random = Random();

  static const List<String> _sampleVoiceInputs = [
    'I have severe stomach pain since morning',
    'मुझे दांत में बहुत तेज दर्द हो रहा है',
    'माझ्या लहान मुलाला कालपासून ताप आहे',
    'I need a skin specialist doctor for rash',
    'छाती में दर्द और सांस लेने में तकलीफ हो रही है',
  ];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String?> listenForSpeech({String lang = 'en-IN'}) async {
    // Simulate listening delay
    await Future.delayed(const Duration(milliseconds: 1200));
    final index = _random.nextInt(_sampleVoiceInputs.length);
    return _sampleVoiceInputs[index];
  }
}
