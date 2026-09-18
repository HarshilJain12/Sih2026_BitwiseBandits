// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'हेल्थकेयर ऐप';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get chooseLanguageSubtitle => 'Choose your language · भाषा निवडा';

  @override
  String get chooseRole => 'आप कौन हैं?';

  @override
  String get chooseRoleSubtitle => 'जारी रखने के लिए अपनी भूमिका चुनें';

  @override
  String get rolePatient => 'मरीज / नागरिक';

  @override
  String get rolePatientDesc => 'स्वास्थ्य सेवाओं तक पहुंचें';

  @override
  String get roleAsha => 'आशा कार्यकर्ता';

  @override
  String get roleAshaDesc => 'सामुदायिक स्वास्थ्य कार्यकर्ता';

  @override
  String get roleDoctor => 'डॉक्टर';

  @override
  String get roleDoctorDesc => 'चिकित्सा पेशेवर';

  @override
  String get roleHospitalAdmin => 'अस्पताल प्रशासन';

  @override
  String get roleHospitalAdminDesc => 'सुविधा प्रबंधन';

  @override
  String get login => 'लॉगिन';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get mobileNumberHint => '10 अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get continueButton => 'जारी रखें';

  @override
  String get getOtp => 'OTP प्राप्त करें';

  @override
  String get otpTitle => 'OTP सत्यापित करें';

  @override
  String otpSentTo(String phone) {
    return '+91 $phone पर OTP भेजा गया';
  }

  @override
  String get otpHint => '6 अंकों का OTP दर्ज करें';

  @override
  String get verifyButton => 'सत्यापित करें और लॉगिन करें';

  @override
  String get resendOtp => 'OTP पुनः भेजें';

  @override
  String resendIn(int seconds) {
    return '$seconds सेकंड में पुनः भेजें';
  }

  @override
  String get ashaId => 'आशा ID';

  @override
  String get ashaIdHint => 'अपना आशा कार्यकर्ता ID दर्ज करें';

  @override
  String get doctorId => 'डॉक्टर ID';

  @override
  String get doctorIdHint => 'अपना डॉक्टर ID दर्ज करें';

  @override
  String get hospitalId => 'अस्पताल ID';

  @override
  String get hospitalIdHint => 'अपना अस्पताल ID दर्ज करें';

  @override
  String get password => 'पासवर्ड';

  @override
  String get passwordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get loginButton => 'लॉगिन';

  @override
  String get firstTimeRegister => 'पहली बार? पंजीकरण करें';

  @override
  String get registerTitle => 'पंजीकरण';

  @override
  String get registerSubtitle => 'पंजीकरण के लिए अपनी भूमिका चुनें';

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String comingSoonDesc(String role) {
    return '$role के लिए पंजीकरण अगले चरण में उपलब्ध होगा।';
  }

  @override
  String get back => 'वापस';

  @override
  String get loading => 'कृपया प्रतीक्षा करें...';

  @override
  String get errorGeneric => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get errorInvalidCredentials =>
      'गलत ID या पासवर्ड। कृपया पुनः प्रयास करें।';

  @override
  String get errorInvalidOtp => 'गलत OTP। कृपया जाँचें और पुनः प्रयास करें।';

  @override
  String get validationRequired => 'यह फ़ील्ड आवश्यक है।';

  @override
  String get validationPhone =>
      'कृपया एक वैध 10 अंकों का मोबाइल नंबर दर्ज करें।';

  @override
  String get validationOtp => 'कृपया एक वैध 6 अंकों का OTP दर्ज करें।';

  @override
  String get validationMinLength => 'कम से कम 6 अक्षर होने चाहिए।';

  @override
  String get mockOtpHint => 'परीक्षण के लिए 123456 उपयोग करें';

  @override
  String selectedRole(String role) {
    return 'चुनी गई भूमिका: $role';
  }

  @override
  String get phoneAuthNotice =>
      'आपके खाते को सत्यापित करने के लिए आपके फ़ोन नंबर का उपयोग किया जाएगा। आपके मोबाइल ऑपरेटर के अनुसार SMS शुल्क लग सकते हैं।';

  @override
  String get errorInvalidPhone => 'कृपया एक मान्य फ़ोन नंबर दर्ज करें।';

  @override
  String get errorSessionExpired =>
      'यह OTP समाप्त हो गया है। कृपया नया OTP मांगें।';

  @override
  String get errorTooManyRequests =>
      'बहुत अधिक प्रयास। कृपया थोड़ी देर प्रतीक्षा करें और पुनः प्रयास करें।';

  @override
  String get errorNetwork =>
      'कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get phoneVerifiedSuccess => 'फ़ोन सफलतापूर्वक सत्यापित हुआ';

  @override
  String get phoneVerifiedSubtitle => 'आपका फ़ोन नंबर सत्यापित हो चुका है।';

  @override
  String get firebaseAuthSuccess => 'फ़ायरबेस प्रमाणीकरण सफल';

  @override
  String debugFirebaseUid(String uid) {
    return 'फ़ायरबेस UID: $uid';
  }

  @override
  String get signOut => 'साइन आउट';

  @override
  String get createPatientProfileTitle => 'अपना मरीज प्रोफाइल बनाएं';

  @override
  String get createPatientProfileSubtitle =>
      'शुरू करने के लिए कुछ बुनियादी विवरण दर्ज करें।';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get fullNameHint => 'पूरा नाम दर्ज करें';

  @override
  String get age => 'आयु';

  @override
  String get ageHint => 'उदा. 25';

  @override
  String get years => 'वर्ष';

  @override
  String get weight => 'वजन';

  @override
  String get weightHint => 'उदा. 65';

  @override
  String get kg => 'किग्रा';

  @override
  String get height => 'ऊंचाई';

  @override
  String get heightHint => 'उदा. 170';

  @override
  String get cm => 'सेमी';

  @override
  String get createProfileButton => 'मरीज प्रोफाइल बनाएं';

  @override
  String get verifiedPhone => 'सत्यापित फ़ोन';

  @override
  String get patientProfileCreated => 'मरीज प्रोफाइल बन गई';

  @override
  String get yourPatientId => 'आपका मरीज ID';

  @override
  String get copyPatientId => 'मरीज ID कॉपी करें';

  @override
  String get patientIdCopied => 'मरीज ID क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get validationName => 'कृपया अपना नाम दर्ज करें।';

  @override
  String get validationAge => 'कृपया एक मान्य आयु दर्ज करें (1–120)।';

  @override
  String get validationWeight => 'कृपया किग्रा में मान्य वजन दर्ज करें।';

  @override
  String get validationHeight => 'कृपया सेमी में मान्य ऊंचाई दर्ज करें।';

  @override
  String get existingProfileFound => 'मौजूदा मरीज प्रोफाइल मिली।';

  @override
  String get locationTitle => 'स्थान चुनें';

  @override
  String get locationSubtitle => 'अपना स्थान प्रदान करने का तरीका चुनें';

  @override
  String get useCurrentLocation => 'वर्तमान स्थान का उपयोग करें';

  @override
  String get useCurrentLocationDesc =>
      'जीपीएस का उपयोग करके स्वचालित रूप से स्थान प्राप्त करें';

  @override
  String get enterLocationManually => 'मैन्युअल रूप से स्थान दर्ज करें';

  @override
  String get enterLocationManuallyDesc => 'गांव, जिला और पिन कोड दर्ज करें';

  @override
  String get confirmLocation => 'स्थान की पुष्टि करें';

  @override
  String get selectedLocation => 'चुना गया स्थान';

  @override
  String get adjustPinPrompt =>
      'पिन को अपने सटीक स्थान पर रखने के लिए नक्शा हिलाएं';

  @override
  String get village => 'गांव / शहर';

  @override
  String get villageHint => 'गांव या शहर का नाम दर्ज करें';

  @override
  String get district => 'जिला';

  @override
  String get districtHint => 'उदा. पुणे, सातारा, नागपुर';

  @override
  String get state => 'राज्य';

  @override
  String get stateHint => 'उदा. महाराष्ट्र';

  @override
  String get pincode => 'पिन कोड';

  @override
  String get pincodeHint => '6-अंकों का पिन कोड';

  @override
  String get fullAddress => 'पूरा पता (वैकल्पिक)';

  @override
  String get fullAddressHint => 'मकान संख्या, गली, लैंडमार्क';

  @override
  String get saveLocationButton => 'स्थान सहेजें';

  @override
  String get locationSaved => 'स्थान सहेजा गया';

  @override
  String get locationSavedDesc =>
      'आपके स्थान का विवरण आपके मरीज प्रोफ़ाइल से जोड़ दिया गया है।';

  @override
  String get locationPermissionRequired =>
      'आपकी वर्तमान स्थिति का पता लगाने के लिए स्थान अनुमति आवश्यक है।';

  @override
  String get locationServicesDisabled =>
      'डिवाइस स्थान सेवाएं बंद हैं। कृपया जीपीएस चालू करें।';

  @override
  String get locationFetchFailed =>
      'जीपीएस स्थान प्राप्त नहीं हो सका। कृपया सिग्नल जांचें या मैन्युअल रूप से दर्ज करें।';

  @override
  String get openSettings => 'सेटिंग्स खोलें';

  @override
  String get tryAgain => 'पुनः प्रयास करें';

  @override
  String get orEnterManually => 'या मैन्युअल रूप से स्थान दर्ज करें';

  @override
  String get medicalRecordsTitle => 'मेडिकल रिकॉर्ड्स';

  @override
  String get medicalRecordsSubtitle => 'अगले चरण में आ रहा है';

  @override
  String get medicalRecordsComingSoonDesc =>
      'आने वाले चरण में, आप नुस्खे, लैब रिपोर्ट और मेडिकल इतिहास अपलोड कर सकेंगे।';

  @override
  String get finishRegistration => 'पंजीकरण पूरा करें और लॉगिन पर जाएं';

  @override
  String get validationPincode => 'कृपया एक वैध 6-अंकों का पिन कोड दर्ज करें।';

  @override
  String get validationVillage => 'कृपया अपने गांव या शहर का नाम दर्ज करें।';

  @override
  String get validationDistrict => 'कृपया अपने जिले का नाम दर्ज करें।';

  @override
  String get validationState => 'कृपया अपने राज्य का नाम दर्ज करें।';

  @override
  String get fetchingGps => 'वर्तमान स्थान प्राप्त किया जा रहा है...';

  @override
  String greetingMorning(String name) {
    return 'शुभ प्रभात, $name 👋';
  }

  @override
  String greetingAfternoon(String name) {
    return 'नमस्कार, $name 👋';
  }

  @override
  String greetingEvening(String name) {
    return 'शुभ संध्या, $name 👋';
  }

  @override
  String greetingGeneric(String name) {
    return 'नमस्ते, $name 👋';
  }

  @override
  String patientIdLabel(String id) {
    return 'मरीज ID: $id';
  }

  @override
  String get nurseCompanionTitle => 'एआई नर्स साथी';

  @override
  String get findHospitalTitle => 'अस्पताल खोजें';

  @override
  String get findHospitalSubtitle =>
      'हमें बताएं कि आपको क्या स्वास्थ्य समस्या है';

  @override
  String get describeHealthProblemHint =>
      'अपनी स्वास्थ्य समस्या का वर्णन करें (उदा. पेट दर्द, दांत दर्द)...';

  @override
  String get listeningVoiceInput => 'सुन रहे हैं... अब बोलें...';

  @override
  String get speechNotAvailable =>
      'आवाज इनपुट सक्रिय है। बोलने के लिए टैप करें।';

  @override
  String get findHospitalButton => 'आस-पास के अस्पताल खोजें';

  @override
  String get searchingHospitals =>
      'निकटतम स्वास्थ्य सुविधाएं खोजी जा रही हैं...';

  @override
  String get noHospitalsFound => 'आपकी खोज से मेल खाता कोई अस्पताल नहीं मिला।';

  @override
  String get viewMap => 'मानचित्र देखें';

  @override
  String get getDirections => 'दिशा-निर्देश प्राप्त करें';

  @override
  String get quickAccessTitle => 'त्वरित पहुँच';

  @override
  String get appointmentsTitle => 'अपॉइंटमेंट';

  @override
  String get prescriptionsTitle => 'नुस्खे';

  @override
  String get referralsTitle => 'रेफ़रल';

  @override
  String get yourFollowUpsTitle => 'आपके फॉलो-अप';

  @override
  String get noUpcomingFollowUps => 'कोई आगामी फॉलो-अप नहीं है';

  @override
  String get emergencyHelpTitle => 'आपातकालीन सहायता';

  @override
  String get getEmergencyHelpButton => 'आपातकालीन कॉल (108)';

  @override
  String get emergencyNotice =>
      'गंभीर चिकित्सा आपात स्थिति के मामले में, 108 पर कॉल करें या तुरंत नजदीकी अस्पताल जाएं।';

  @override
  String get navHome => 'होम';

  @override
  String get navHealth => 'स्वास्थ्य';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String kmAway(String distance) {
    return '$distance किमी दूर';
  }

  @override
  String get open247 => '24/7 खुला है';

  @override
  String get emergencyServicesAvailable => 'आपातकालीन देखभाल उपलब्ध';
}
