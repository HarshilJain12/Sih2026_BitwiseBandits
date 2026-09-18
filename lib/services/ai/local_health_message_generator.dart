import 'dart:math';
import '../../models/patient.dart';
import 'health_message_generator.dart';

/// Local prototype implementation of [HealthMessageGenerator].
///
/// Uses pre-approved safe messages in English, Hindi, and Marathi.
/// Serves as the primary generator until Gemini API is connected in future phase.
class LocalHealthMessageGenerator implements HealthMessageGenerator {
  final Random _random = Random();

  static const List<String> _fallbackMessagesEn = [
    'Welcome! I am here to help you take care of your health. 💚',
    'Good day! How are you feeling today? Remember to stay hydrated. 💧',
    'Your health matters. I am here whenever you need assistance. 🩺',
    'Take a moment today to look after yourself and rest well. ✨',
    'Remember to follow the general instructions given by your healthcare provider. 📋',
  ];

  static const List<String> _fallbackMessagesHi = [
    'स्वागत है! मैं आपके स्वास्थ्य का ख्याल रखने में मदद करने के लिए यहाँ हूँ। 💚',
    'नमस्कार! आज आप कैसा महसूस कर रहे हैं? पानी पीते रहें और स्वस्थ रहें। 💧',
    'आपका स्वास्थ्य महत्वपूर्ण है। जब भी मदद चाहिए, मैं यहाँ हूँ। 🩺',
    'आज अपने लिए थोड़ा समय निकालें और अच्छे से विश्राम करें। ✨',
    'अपने डॉक्टर द्वारा दिए गए सामान्य निर्देशों का पालन याद रखें। 📋',
  ];

  static const List<String> _fallbackMessagesMr = [
    'स्वागत आहे! तुमच्या आरोग्याची काळजी घेण्यास मदत करण्यासाठी मी येथे आहे. 💚',
    'नमस्कार! आज तुम्हाला कसे वाटत आहे? मुबलक पाणी प्या आणि निरोगी राहा. 💧',
    'तुमचे आरोग्य महत्त्वाचे आहे. तुम्हाला मदत हवी असल्यास मी येथे आहे. 🩺',
    'आज स्वतःसाठी थोडा वेळ काढा आणि विश्रांती घ्या. ✨',
    'तुमच्या डॉक्टरांनी दिलेल्या सूचनांचे पालन करण्याचे लक्षात ठेवा. 📋',
  ];

  static const List<String> _historyMessagesEn = [
    'Have you taken your prescribed tablets today? 💊',
    'Don\'t forget your upcoming follow-up appointment. 🗓️',
    'Keep your recent medical reports handy for your next consultation. 📄',
    'Remember to take light walks and rest well today. 🚶‍♂️',
  ];

  static const List<String> _historyMessagesHi = [
    'क्या आपने आज अपनी डॉक्टर द्वारा दी गई दवाइयां ली हैं? 💊',
    'अपनी आगामी फॉलो-अप अपॉइंटमेंट याद रखें। 🗓️',
    'अगली सलाह के लिए अपनी हालिया मेडिकल रिपोर्ट साथ रखें। 📄',
    'आज हल्का व्यायाम करें और पर्याप्त आराम लें। 🚶‍♂️',
  ];

  static const List<String> _historyMessagesMr = [
    'तुम्ही आज तुमच्या डॉक्टरांनी दिलेली औषधे घेतली आहेत का? 💊',
    'तुमची आगामी फॉलो-अप भेट लक्षात ठेवा. 🗓️',
    'पुढील सल्लामसलतीसाठी तुमचे वैद्यकीय अहवाल सोबत ठेवा. 📄',
    'आज थोडा वेळ हलका व्यायाम करा आणि विश्रांती घ्या. 🚶‍♂️',
  ];

  @override
  Future<String> generateMessage({
    required Patient patient,
    required String localeCode,
    Map<String, dynamic>? medicalRecordsSummary,
  }) async {
    // Simulate brief dynamic processing delay for prototype demo
    await Future.delayed(const Duration(milliseconds: 300));

    final hasHistory = medicalRecordsSummary != null &&
        medicalRecordsSummary.isNotEmpty &&
        medicalRecordsSummary['hasRecords'] == true;

    final list = _selectList(localeCode: localeCode, hasHistory: hasHistory);
    final index = _random.nextInt(list.length);
    return list[index];
  }

  List<String> _selectList({
    required String localeCode,
    required bool hasHistory,
  }) {
    if (hasHistory) {
      switch (localeCode.toLowerCase()) {
        case 'hi':
          return _historyMessagesHi;
        case 'mr':
          return _historyMessagesMr;
        default:
          return _historyMessagesEn;
      }
    } else {
      switch (localeCode.toLowerCase()) {
        case 'hi':
          return _fallbackMessagesHi;
        case 'mr':
          return _fallbackMessagesMr;
        default:
          return _fallbackMessagesEn;
      }
    }
  }
}
