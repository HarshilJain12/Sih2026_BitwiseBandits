import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/speech/mock_speech_input_service.dart';

void main() {
  group('VoiceInputService Unit Tests', () {
    late MockSpeechInputService mockSpeech;

    setUp(() {
      mockSpeech = MockSpeechInputService(
        mockResult: 'I need a dental clinic',
        simulatedDelay: const Duration(milliseconds: 50),
      );
    });

    test('1. Speech service initializes and checks availability successfully', () async {
      expect(await mockSpeech.initialize(), isTrue);
      expect(await mockSpeech.isAvailable(), isTrue);
      expect(mockSpeech.isListening, isFalse);
    });

    test('2. Mock speech service listens and returns transcribed text', () async {
      String? result;
      final started = await mockSpeech.startListening(
        onResult: (words, isFinal) {
          result = words;
        },
      );

      expect(started, isTrue);
      expect(mockSpeech.isListening, isTrue);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(mockSpeech.isListening, isFalse);
      expect(result, equals('I need a dental clinic'));
    });

    test('3. listenForSpeech helper completes with final transcribed string', () async {
      final text = await mockSpeech.listenForSpeech();
      expect(text, equals('I need a dental clinic'));
    });

    test('4. Language mapping: English maps to en_IN', () {
      expect(mockSpeech.resolveLocaleId('en'), equals('en_IN'));
      expect(mockSpeech.resolveLocaleId('EN'), equals('en_IN'));
    });

    test('5. Language mapping: Hindi maps to hi_IN', () {
      expect(mockSpeech.resolveLocaleId('hi'), equals('hi_IN'));
      expect(mockSpeech.resolveLocaleId('HI'), equals('hi_IN'));
    });

    test('6. Language mapping: Marathi maps to mr_IN', () {
      expect(mockSpeech.resolveLocaleId('mr'), equals('mr_IN'));
      expect(mockSpeech.resolveLocaleId('MR'), equals('mr_IN'));
    });

    test('7. Multiple microphone taps do not create multiple simultaneous listeners', () async {
      final firstStart = await mockSpeech.startListening(onResult: (text, isFinal) {});
      expect(firstStart, isTrue);
      expect(mockSpeech.startListeningCallCount, equals(1));

      // Attempt second start while already listening
      final secondStart = await mockSpeech.startListening(onResult: (text, isFinal) {});
      expect(secondStart, isTrue);
      // Call count should NOT increment because service was already active
      expect(mockSpeech.startListeningCallCount, equals(1));
    });

    test('8. Voice error handling reports error gracefully without throwing', () async {
      final errorSpeech = MockSpeechInputService(
        mockError: 'Microphone permission denied',
      );

      String? caughtError;
      final started = await errorSpeech.startListening(
        onResult: (text, isFinal) {},
        onError: (err) {
          caughtError = err;
        },
      );

      expect(started, isFalse);
      expect(errorSpeech.isListening, isFalse);
      expect(caughtError, equals('Microphone permission denied'));
    });

    test('9. Voice unavailable reports error gracefully without throwing', () async {
      final unavailableSpeech = MockSpeechInputService(
        mockAvailable: false,
      );

      expect(await unavailableSpeech.isAvailable(), isFalse);

      String? caughtError;
      final started = await unavailableSpeech.startListening(
        onResult: (text, isFinal) {},
        onError: (err) {
          caughtError = err;
        },
      );

      expect(started, isFalse);
      expect(caughtError, contains('unavailable'));
    });

    test('10. Stop and Cancel listening update isListening state', () async {
      await mockSpeech.startListening(onResult: (text, isFinal) {});
      expect(mockSpeech.isListening, isTrue);

      await mockSpeech.stopListening();
      expect(mockSpeech.isListening, isFalse);

      await mockSpeech.startListening(onResult: (text, isFinal) {});
      expect(mockSpeech.isListening, isTrue);

      await mockSpeech.cancelListening();
      expect(mockSpeech.isListening, isFalse);
    });
  });
}
