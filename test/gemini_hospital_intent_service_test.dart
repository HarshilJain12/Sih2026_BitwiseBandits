import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/ai/gemini_hospital_intent_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GeminiHospitalIntentService Unit Tests', () {
    test('1. Dentist query maps to dentist via deterministic fallback', () {
      expect(GeminiHospitalIntentService.fallbackClassify('I have a tooth ache'), equals(HealthcareCategory.dentist));
      expect(GeminiHospitalIntentService.fallbackClassify('I need a dentist'), equals(HealthcareCategory.dentist));
      expect(GeminiHospitalIntentService.fallbackClassify('दांत में दर्द है'), equals(HealthcareCategory.dentist));
    });

    test('2. Eye query maps to eye_care via deterministic fallback', () {
      expect(GeminiHospitalIntentService.fallbackClassify('my eyes are hurting'), equals(HealthcareCategory.eyeCare));
      expect(GeminiHospitalIntentService.fallbackClassify('I need an eye doctor'), equals(HealthcareCategory.eyeCare));
      expect(GeminiHospitalIntentService.fallbackClassify('आँख में जलन'), equals(HealthcareCategory.eyeCare));
    });

    test('3. Skin query maps to dermatologist', () {
      expect(GeminiHospitalIntentService.fallbackClassify('I have skin rash and itching'), equals(HealthcareCategory.dermatologist));
    });

    test('4. Child query maps to pediatrician', () {
      expect(GeminiHospitalIntentService.fallbackClassify('my child has high fever'), equals(HealthcareCategory.pediatrician));
      expect(GeminiHospitalIntentService.fallbackClassify('लहान बाळाला ताप'), equals(HealthcareCategory.pediatrician));
    });

    test('5. Bone query maps to orthopedics', () {
      expect(GeminiHospitalIntentService.fallbackClassify('I broke my leg joint'), equals(HealthcareCategory.orthopedics));
    });

    test('6. Gemini API success parses structured JSON category correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '{"category": "dentist"}'}
                  ]
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiHospitalIntentService(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      final category = await service.classifyIntent('my tooth has been hurting');
      expect(category, equals(HealthcareCategory.dentist));
    });

    test('7. Gemini API failure or timeout triggers safe deterministic fallback', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = GeminiHospitalIntentService(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      final category = await service.classifyIntent('eye pain and blurriness');
      expect(category, equals(HealthcareCategory.eyeCare));
    });

    test('8. Invalid/unsupported Gemini category triggers safe fallback', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '{"category": "brain_surgery_rocket_science"}'}
                  ]
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiHospitalIntentService(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      final category = await service.classifyIntent('my tooth is hurting');
      // Because "brain_surgery_rocket_science" is invalid, falls back to keyword classifier ("tooth" -> dentist)
      expect(category, equals(HealthcareCategory.dentist));
    });
  });
}
