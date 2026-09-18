// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'हेल्थकेअर अ‍ॅप';

  @override
  String get chooseLanguage => 'तुमची भाषा निवडा';

  @override
  String get chooseLanguageSubtitle => 'Choose your language · भाषा चुनें';

  @override
  String get chooseRole => 'तुम्ही कोण आहात?';

  @override
  String get chooseRoleSubtitle => 'पुढे जाण्यासाठी तुमची भूमिका निवडा';

  @override
  String get rolePatient => 'रुग्ण / नागरिक';

  @override
  String get rolePatientDesc => 'आरोग्य सेवांचा लाभ घ्या';

  @override
  String get roleAsha => 'आशा कार्यकर्ता';

  @override
  String get roleAshaDesc => 'सामुदायिक आरोग्य कार्यकर्ता';

  @override
  String get roleDoctor => 'डॉक्टर';

  @override
  String get roleDoctorDesc => 'वैद्यकीय व्यावसायिक';

  @override
  String get roleHospitalAdmin => 'रुग्णालय प्रशासन';

  @override
  String get roleHospitalAdminDesc => 'सुविधा व्यवस्थापन';

  @override
  String get login => 'लॉगिन';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get mobileNumberHint => '10 अंकी मोबाइल नंबर टाका';

  @override
  String get continueButton => 'पुढे जा';

  @override
  String get getOtp => 'OTP मिळवा';

  @override
  String get otpTitle => 'OTP सत्यापित करा';

  @override
  String otpSentTo(String phone) {
    return '+91 $phone वर OTP पाठवला गेला';
  }

  @override
  String get otpHint => '6 अंकी OTP टाका';

  @override
  String get verifyButton => 'सत्यापित करा आणि लॉगिन करा';

  @override
  String get resendOtp => 'OTP पुन्हा पाठवा';

  @override
  String resendIn(int seconds) {
    return '$seconds सेकंदांत पुन्हा पाठवा';
  }

  @override
  String get ashaId => 'आशा ID';

  @override
  String get ashaIdHint => 'तुमचा आशा कार्यकर्ता ID टाका';

  @override
  String get doctorId => 'डॉक्टर ID';

  @override
  String get doctorIdHint => 'तुमचा डॉक्टर ID टाका';

  @override
  String get hospitalId => 'रुग्णालय ID';

  @override
  String get hospitalIdHint => 'तुमचा रुग्णालय ID टाका';

  @override
  String get password => 'पासवर्ड';

  @override
  String get passwordHint => 'तुमचा पासवर्ड टाका';

  @override
  String get loginButton => 'लॉगिन';

  @override
  String get firstTimeRegister => 'प्रथमच? नोंदणी करा';

  @override
  String get registerTitle => 'नोंदणी';

  @override
  String get registerSubtitle => 'नोंदणीसाठी तुमची भूमिका निवडा';

  @override
  String get comingSoon => 'लवकरच येत आहे';

  @override
  String comingSoonDesc(String role) {
    return '$role साठी नोंदणी पुढील टप्प्यात उपलब्ध होईल.';
  }

  @override
  String get back => 'मागे';

  @override
  String get loading => 'कृपया प्रतीक्षा करा...';

  @override
  String get errorGeneric => 'काहीतरी चूक झाली. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get errorInvalidCredentials =>
      'चुकीचा ID किंवा पासवर्ड. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get errorInvalidOtp =>
      'चुकीचा OTP. कृपया तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get validationRequired => 'हे क्षेत्र आवश्यक आहे.';

  @override
  String get validationPhone => 'कृपया वैध 10 अंकी मोबाइल नंबर टाका.';

  @override
  String get validationOtp => 'कृपया वैध 6 अंकी OTP टाका.';

  @override
  String get validationMinLength => 'किमान 6 अक्षरे असणे आवश्यक आहे.';

  @override
  String get mockOtpHint => 'चाचणीसाठी 123456 वापरा';

  @override
  String selectedRole(String role) {
    return 'निवडलेली भूमिका: $role';
  }

  @override
  String get phoneAuthNotice =>
      'तुमच्या खात्याची पडताळणी करण्यासाठी तुमचा फोन नंबर वापरला जाईल. तुमच्या मोबाइल ऑपरेटरनुसार SMS शुल्क लागू शकते.';

  @override
  String get errorInvalidPhone => 'कृपया वैध फोन नंबर टाका.';

  @override
  String get errorSessionExpired =>
      'हा OTP कालबाह्य झाला आहे. कृपया नवीन OTP मागवा.';

  @override
  String get errorTooManyRequests =>
      'खूप जास्त प्रयत्न. कृपया थोडा वेळ थांबा आणि पुन्हा प्रयत्न करा.';

  @override
  String get errorNetwork =>
      'कृपया तुमचे इंटरनेट कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get phoneVerifiedSuccess => 'फोन यशस्वीरित्या सत्यापित झाला';

  @override
  String get phoneVerifiedSubtitle => 'तुमचा फोन नंबर सत्यापित झाला आहे.';

  @override
  String get firebaseAuthSuccess => 'फायरबेस प्रमाणीकरण यशस्वी';

  @override
  String debugFirebaseUid(String uid) {
    return 'फायरबेस UID: $uid';
  }

  @override
  String get signOut => 'साइन आउट';

  @override
  String get createPatientProfileTitle => 'तुमचे रुग्ण प्रोफाइल तयार करा';

  @override
  String get createPatientProfileSubtitle =>
      'सुरू करण्यासाठी काही मूलभूत तपशील भरा.';

  @override
  String get fullName => 'पूर्ण नाव';

  @override
  String get fullNameHint => 'पूर्ण नाव प्रविष्ट करा';

  @override
  String get age => 'वय';

  @override
  String get ageHint => 'उदा. 25';

  @override
  String get years => 'वर्षे';

  @override
  String get weight => 'वजन';

  @override
  String get weightHint => 'उदा. 65';

  @override
  String get kg => 'कि.ग्रॅ.';

  @override
  String get height => 'उंची';

  @override
  String get heightHint => 'उदा. 170';

  @override
  String get cm => 'सें.मी.';

  @override
  String get createProfileButton => 'रुग्ण प्रोफाइल तयार करा';

  @override
  String get verifiedPhone => 'सत्यापित फोन';

  @override
  String get patientProfileCreated => 'रुग्ण प्रोफाइल तयार झाले';

  @override
  String get yourPatientId => 'तुमचा रुग्ण ID';

  @override
  String get copyPatientId => 'रुग्ण ID कॉपी करा';

  @override
  String get patientIdCopied => 'रुग्ण ID क्लिपबोर्डवर कॉपी केले';

  @override
  String get validationName => 'कृपया तुमचे नाव प्रविष्ट करा.';

  @override
  String get validationAge => 'कृपया वैध वय प्रविष्ट करा (1–120).';

  @override
  String get validationWeight => 'कृपया कि.ग्रॅ. मध्ये वैध वजन प्रविष्ट करा.';

  @override
  String get validationHeight => 'कृपया सें.मी. मध्ये वैध उंची प्रविष्ट करा.';

  @override
  String get existingProfileFound => 'विद्यमान रुग्ण प्रोफाइल आढळली।';

  @override
  String get locationTitle => 'स्थान निवडा';

  @override
  String get locationSubtitle => 'आपले स्थान प्रदान करण्याचा मार्ग निवडा';

  @override
  String get useCurrentLocation => 'चालू स्थान वापरा';

  @override
  String get useCurrentLocationDesc => 'जीपीएस वापरून आपोआप स्थान मिळवा';

  @override
  String get enterLocationManually => 'स्वतः स्थान प्रविष्ट करा';

  @override
  String get enterLocationManuallyDesc =>
      'गाव, जिल्हा आणि पिन कोड प्रविष्ट करा';

  @override
  String get confirmLocation => 'स्थानाची पुष्टी करा';

  @override
  String get selectedLocation => 'निवडलेले स्थान';

  @override
  String get adjustPinPrompt =>
      'पिन आपल्या अचूक स्थानावर ठेवण्यासाठी नकाशा हलवा';

  @override
  String get village => 'गाव / शहर';

  @override
  String get villageHint => 'गाव किंवा शहराचे नाव प्रविष्ट करा';

  @override
  String get district => 'जिल्हा';

  @override
  String get districtHint => 'उदा. पुणे, सातारा, नागपूर';

  @override
  String get state => 'राज्य';

  @override
  String get stateHint => 'उदा. महाराष्ट्र';

  @override
  String get pincode => 'पिन कोड';

  @override
  String get pincodeHint => '६-अंकी पिन कोड';

  @override
  String get fullAddress => 'संपूर्ण पत्ता (पर्यायी)';

  @override
  String get fullAddressHint => 'घर क्रमांक, गल्ली, लँडमार्क';

  @override
  String get saveLocationButton => 'स्थान जतन करा';

  @override
  String get locationSaved => 'स्थान जतन केले';

  @override
  String get locationSavedDesc =>
      'तुमचा स्थान तपशील तुमच्या रुग्ण प्रोफाइलशी जोडला गेला आहे.';

  @override
  String get locationPermissionRequired =>
      'आपले चालू स्थान शोधण्यासाठी स्थानाची परवानगी आवश्यक आहे.';

  @override
  String get locationServicesDisabled =>
      'डिव्हाइस स्थान सेवा बंद आहेत. कृपया जीपीएस चालू करा.';

  @override
  String get locationFetchFailed =>
      'जीपीएस स्थान मिळवता आले नाही. कृपया सिग्नल तपासा किंवा स्वतः प्रविष्ट करा.';

  @override
  String get openSettings => 'सेटिंग्ज उघडा';

  @override
  String get tryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get orEnterManually => 'किंवा स्वतः स्थान प्रविष्ट करा';

  @override
  String get medicalRecordsTitle => 'वैद्यकीय नोंदी';

  @override
  String get medicalRecordsSubtitle => 'पुढील टप्प्यात येत आहे';

  @override
  String get medicalRecordsComingSoonDesc =>
      'पुढील टप्प्यात, तुम्ही औषधोपचार, लॅब अहवाल आणि वैद्यकीय इतिहास अपलोड करू शकाल.';

  @override
  String get finishRegistration => 'नोंदणी पूर्ण करा आणि लॉगिनवर जा';

  @override
  String get validationPincode => 'कृपया वैध ६-अंकी पिन कोड प्रविष्ट करा.';

  @override
  String get validationVillage =>
      'कृपया आपल्या गावाचे किंवा शहराचे नाव प्रविष्ट करा.';

  @override
  String get validationDistrict => 'कृपया आपल्या जिल्ह्याचे नाव प्रविष्ट करा.';

  @override
  String get validationState => 'कृपया आपल्या राज्याचे नाव प्रविष्ट करा.';

  @override
  String get fetchingGps => 'चालू स्थान शोधत आहे...';
}
