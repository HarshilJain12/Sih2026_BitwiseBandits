import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

/// Supported healthcare search categories (strictly controlled whitelist).
class HealthcareCategory {
  static const String dentist = 'dentist';
  static const String generalPhysician = 'general_physician';
  static const String eyeCare = 'eye_care';
  static const String dermatologist = 'dermatologist';
  static const String ent = 'ent';
  static const String pediatrician = 'pediatrician';
  static const String orthopedics = 'orthopedics';
  static const String gynecologist = 'gynecologist';
  static const String hospital = 'hospital';
  static const String clinic = 'clinic';
  static const String pharmacy = 'pharmacy';

  static const List<String> all = [
    dentist,
    generalPhysician,
    eyeCare,
    dermatologist,
    ent,
    pediatrician,
    orthopedics,
    gynecologist,
    hospital,
    clinic,
    pharmacy,
  ];

  static bool isValid(String? category) {
    if (category == null) return false;
    return all.contains(category.toLowerCase().trim());
  }

  /// User-friendly label in English
  static String getDisplayName(String category) {
    switch (category) {
      case dentist:
        return 'Dentist & Dental Clinic';
      case eyeCare:
        return 'Eye Care & Ophthalmologist';
      case dermatologist:
        return 'Dermatologist & Skin Clinic';
      case ent:
        return 'ENT Specialist';
      case pediatrician:
        return 'Child Specialist & Pediatrics';
      case orthopedics:
        return 'Orthopedics & Bone Clinic';
      case gynecologist:
        return 'Gynecologist & Maternity';
      case pharmacy:
        return 'Pharmacy & Chemist';
      case hospital:
        return 'Hospital';
      case clinic:
        return 'Medical Clinic';
      case generalPhysician:
      default:
        return 'General Physician & Doctor';
    }
  }
}

/// Service that classifies user health queries into a search category using Gemini or safe fallback.
///
/// Safety Rule: Gemini is strictly used for intent extraction to query Google Places, NEVER for diagnosing patients.
class GeminiHospitalIntentService {
  GeminiHospitalIntentService({
    String? apiKey,
    http.Client? httpClient,
  })  : _apiKey = apiKey ?? ApiConfig.geminiApiKey,
        _client = httpClient ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  /// Classifies [userQuery] into a supported [HealthcareCategory].
  Future<String> classifyIntent(String userQuery) async {
    final cleaned = userQuery.trim();
    if (cleaned.isEmpty) {
      return HealthcareCategory.hospital;
    }

    if (_apiKey.isEmpty) {
      return fallbackClassify(cleaned);
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
      );

      final prompt = '''
You are a healthcare intent classification engine for a rural healthcare assistance app.
Your ONLY responsibility is to categorize the user's healthcare request into exactly ONE category from this whitelist:
- dentist
- general_physician
- eye_care
- dermatologist
- ent
- pediatrician
- orthopedics
- gynecologist
- hospital
- clinic
- pharmacy

CRITICAL SAFETY INSTRUCTIONS:
- Do NOT provide medical diagnoses, treatment advice, or drug recommendations.
- Output ONLY valid JSON in this exact structure: {"category": "<category_from_whitelist>"}

User Request: "$cleaned"
''';

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'temperature': 0.0,
          },
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final rawText = parts[0]['text'] as String?;
            if (rawText != null) {
              final parsed = jsonDecode(rawText.trim()) as Map<String, dynamic>;
              final category = parsed['category']?.toString().toLowerCase().trim();
              if (HealthcareCategory.isValid(category)) {
                return category!;
              }
            }
          }
        }
      }

      // Fallback if HTTP call failed or response was malformed
      return fallbackClassify(cleaned);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiHospitalIntentService] Classification failed, using fallback: $e');
      }
      return fallbackClassify(cleaned);
    }
  }

  /// Safe, deterministic local keyword-based fallback classifier.
  static String fallbackClassify(String query) {
    final q = query.toLowerCase().trim();

    // Dental
    if (q.contains('tooth') ||
        q.contains('teeth') ||
        q.contains('dental') ||
        q.contains('dentist') ||
        q.contains('gum') ||
        q.contains('daant') ||
        q.contains('daat') ||
        q.contains('दांत') ||
        q.contains('दात') ||
        q.contains('दंत')) {
      return HealthcareCategory.dentist;
    }

    // Eye care
    if (q.contains('eye') ||
        q.contains('vision') ||
        q.contains('optometrist') ||
        q.contains('ophthalmolog') ||
        q.contains('aankh') ||
        q.contains('dola') ||
        q.contains('आँख') ||
        q.contains('आंख') ||
        q.contains('डोळ') ||
        q.contains('नेत्र')) {
      return HealthcareCategory.eyeCare;
    }

    // Dermatology
    if (q.contains('skin') ||
        q.contains('rash') ||
        q.contains('acne') ||
        q.contains('itching') ||
        q.contains('dermatolog') ||
        q.contains('twacha') ||
        q.contains('khujli') ||
        q.contains('त्वचा') ||
        q.contains('खाज') ||
        q.contains('खुजली')) {
      return HealthcareCategory.dermatologist;
    }

    // Pediatrics
    if (q.contains('child') ||
        q.contains('baby') ||
        q.contains('kid') ||
        q.contains('pediatric') ||
        q.contains('paediatric') ||
        q.contains('bachha') ||
        q.contains('baal') ||
        q.contains('lahan mul') ||
        q.contains('बच्च') ||
        q.contains('बाळ') ||
        q.contains('मूल') ||
        q.contains('शिशु')) {
      return HealthcareCategory.pediatrician;
    }

    // Orthopedics
    if (q.contains('bone') ||
        q.contains('joint') ||
        q.contains('fracture') ||
        q.contains('orthopedic') ||
        q.contains('leg') ||
        q.contains('knee') ||
        q.contains('spine') ||
        q.contains('haad') ||
        q.contains('haddi') ||
        q.contains('हड्डी') ||
        q.contains('हाड') ||
        q.contains('जोड़') ||
        q.contains('सांधे')) {
      return HealthcareCategory.orthopedics;
    }

    // ENT
    if (q.contains('ear') ||
        q.contains('nose') ||
        q.contains('throat') ||
        q.contains('ent') ||
        q.contains('kaan') ||
        q.contains('naak') ||
        q.contains('gala') ||
        q.contains('कान') ||
        q.contains('नाक') ||
        q.contains('गला') ||
        q.contains('घसा')) {
      return HealthcareCategory.ent;
    }

    // Gynecologist / Maternity
    if (q.contains('pregnant') ||
        q.contains('pregnancy') ||
        q.contains('maternity') ||
        q.contains('gynecolog') ||
        q.contains('women') ||
        q.contains('garbh') ||
        q.contains('mahila') ||
        q.contains('गर्भ') ||
        q.contains('महिला') ||
        q.contains('स्त्री')) {
      return HealthcareCategory.gynecologist;
    }

    // Pharmacy
    if (q.contains('pharmacy') ||
        q.contains('medicine') ||
        q.contains('chemist') ||
        q.contains('drug') ||
        q.contains('tablet') ||
        q.contains('dawai') ||
        q.contains('aushadh') ||
        q.contains('दवा') ||
        q.contains('औषध') ||
        q.contains('गोळ्या') ||
        q.contains('फार्मसी')) {
      return HealthcareCategory.pharmacy;
    }

    // General Hospital / Emergency
    if (q.contains('hospital') ||
        q.contains('emergency') ||
        q.contains('aspatal') ||
        q.contains('rugnalaya') ||
        q.contains('अस्पताल') ||
        q.contains('रुग्णालय') ||
        q.contains('इमरजेंसी')) {
      return HealthcareCategory.hospital;
    }

    // Clinic
    if (q.contains('clinic') ||
        q.contains('dispensary') ||
        q.contains('phc') ||
        q.contains('dawakhana') ||
        q.contains('क्लिनिक') ||
        q.contains('दवाखाना')) {
      return HealthcareCategory.clinic;
    }

    // Default fallback
    return HealthcareCategory.generalPhysician;
  }
}
