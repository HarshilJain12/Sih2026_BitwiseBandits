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
  String get medicalRecordsSubtitle => 'तुमचे वैद्यकीय दस्तऐवज व्यवस्थापित करा';

  @override
  String get medicalRecordsComingSoonDesc =>
      'पुढील टप्प्यात, तुम्ही औषधोपचार, लॅब अहवाल आणि वैद्यकीय इतिहास अपलोड करू शकाल.';

  @override
  String get finishRegistration => 'नोंदणी पूर्ण करा';

  @override
  String get addMedicalRecordsTitle => 'आपले वैद्यकीय रेकॉर्ड जोडा';

  @override
  String get addMedicalRecordsSubtitle =>
      'तुम्ही प्रिस्क्रिप्शन, लॅब रिपोर्ट, स्कॅन आणि इतर वैद्यकीय कागदपत्रे अपलोड करू शकता.';

  @override
  String get addMedicalRecordButton => 'वैद्यकीय रेकॉर्ड जोडा';

  @override
  String get skipForNow => 'आत्ता वगळा';

  @override
  String get selectCategoryTitle => 'दस्तऐवज श्रेणी निवडा';

  @override
  String get selectCategorySubtitle =>
      'तुम्ही कोणत्या प्रकारचे कागदपत्र जोडत आहात ते निवडा';

  @override
  String get categoryPrescription => 'प्रिस्क्रिप्शन / औषधोपचार';

  @override
  String get categoryPrescriptionDesc =>
      'डॉक्टरांचे प्रिस्क्रिप्शन आणि औषधांचा सल्ला';

  @override
  String get categoryLabReport => 'लॅब रिपोर्ट';

  @override
  String get categoryLabReportDesc =>
      'रक्त तपासणी, लघवी तपासणी, पॅथॉलॉजी रिपोर्ट';

  @override
  String get categoryScanXray => 'स्कॅन / एक्स-रे';

  @override
  String get categoryScanXrayDesc =>
      'एक्स-रे, एमआरआय, सीटी स्कॅन, सोनोग्राफी रिपोर्ट';

  @override
  String get categoryDischargeSummary => 'डिस्चार्ज सारांश';

  @override
  String get categoryDischargeSummaryDesc =>
      'रुग्णालयात दाखल आणि डिस्चार्जचा सारांश';

  @override
  String get categoryOther => 'इतर दस्तऐवज';

  @override
  String get categoryOtherDesc => 'लसीकरण कार्ड, बिले, इतर आरोग्य नोंदी';

  @override
  String get chooseFile => 'फाइल निवडा';

  @override
  String get chooseFilePrompt => 'तुमच्या डिव्हाइसमधून पीडीएफ किंवा फोटो निवडा';

  @override
  String get supportedFormatsNotice =>
      'स्वीकृत स्वरूप: PDF, JPG, PNG (कमाल १० MB)';

  @override
  String get documentPreviewTitle => 'दस्तऐवजाची खात्री करा';

  @override
  String get documentPreviewSubtitle =>
      'अपलोड करण्यापूर्वी दस्तऐवज तपशील तपासा';

  @override
  String get fileNameLabel => 'फाइलचे नाव';

  @override
  String get fileSizeLabel => 'फाइलचा आकार';

  @override
  String get fileTypeLabel => 'फाइलचा प्रकार';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get notesLabel => 'नोंद जोडा (पर्यायी)';

  @override
  String get notesHint => 'उदा. मागील भेटीचे प्रिस्क्रिप्शन';

  @override
  String get uploadButton => 'दस्तऐवज अपलोड करा';

  @override
  String get changeFileButton => 'फाइल बदला';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get uploadingTitle => 'वैद्यकीय अहवाल अपलोड होत आहे...';

  @override
  String get uploadSuccessTitle => 'वैद्यकीय रेकॉर्ड जोडले गेले';

  @override
  String get uploadSuccessDesc =>
      'तुमचा वैद्यकीय रेकॉर्ड सुरक्षितपणे जतन केला गेला आहे.';

  @override
  String get viewMedicalRecords => 'वैद्यकीय रेकॉर्ड पहा';

  @override
  String get addAnotherRecord => 'आणखी रेकॉर्ड जोडा';

  @override
  String get noRecordsTitle => 'अद्याप कोणतेही वैद्यकीय रेकॉर्ड नाही';

  @override
  String get noRecordsDesc =>
      'तुम्ही येथे प्रिस्क्रिप्शन, लॅब रिपोर्ट, स्कॅन आणि इतर आरोग्य कागदपत्रे जोडू शकता.';

  @override
  String get openRecord => 'उघडा';

  @override
  String get deleteRecord => 'हटवा';

  @override
  String get deleteConfirmTitle => 'हे वैद्यकीय रेकॉर्ड हटवायचे आहे का?';

  @override
  String get deleteConfirmDesc =>
      'एकदा हटवल्यानंतर, हा दस्तऐवज परत मिळवता येणार नाही.';

  @override
  String get recordDeleted => 'वैद्यकीय रेकॉर्ड यशस्वीरित्या हटवले गेले';

  @override
  String get errorFileSizeExceeded =>
      'फाइलचा आकार १० MB पेक्षा जास्त आहे. कृपया लहान फाइल निवडा.';

  @override
  String get errorUnsupportedFormat =>
      'असमर्थित फाइल स्वरूप. कृपया PDF, JPG किंवा PNG निवडा.';

  @override
  String get errorUploadFailed =>
      'दस्तऐवज जतन करण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get errorDeleteFailed =>
      'रेकॉर्ड हटवण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get errorLoadRecordsFailed =>
      'वैद्यकीय रेकॉर्ड लोड करता आले नाही. रिफ्रेश करण्यासाठी खाली ओढा.';

  @override
  String get errorOpenDocumentFailed =>
      'दस्तऐवज उघडण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get openingDocument => 'दस्तऐवज उघडत आहे...';

  @override
  String get refreshRecords => 'रिफ्रेश करण्यासाठी खाली ओढा';

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

  @override
  String greetingMorning(String name) {
    return 'शुभ सकाळ, $name 👋';
  }

  @override
  String greetingAfternoon(String name) {
    return 'शुभ दुपार, $name 👋';
  }

  @override
  String greetingEvening(String name) {
    return 'शुभ संध्याकाळ, $name 👋';
  }

  @override
  String greetingGeneric(String name) {
    return 'नमस्कार, $name 👋';
  }

  @override
  String patientIdLabel(String id) {
    return 'रुग्ण ID: $id';
  }

  @override
  String get nurseCompanionTitle => 'एआय परिचारिका साथी';

  @override
  String get findHospitalTitle => 'रुग्णालय शोधा';

  @override
  String get findHospitalSubtitle =>
      'तुम्हाला काय आरोग्य समस्या आहे ते आम्हाला सांगा';

  @override
  String get describeHealthProblemHint =>
      'तुमच्या आरोग्य समस्येचे वर्णन करा (उदा. पोटदुखी, दातदुखी)...';

  @override
  String get listeningVoiceInput => 'ऐकत आहे... आता बोला...';

  @override
  String get speechNotAvailable =>
      'आवाज इनपुट सक्रिय आहे. बोलण्यासाठी टॅप करा.';

  @override
  String get findHospitalButton => 'जवळची रुग्णालये शोधा';

  @override
  String get searchingHospitals => 'जवळच्या आरोग्य सुविधा शोधत आहे...';

  @override
  String get noHospitalsFound =>
      'तुमच्या शोधाशी जुळणारे कोणतेही रुग्णालय आढळले नाही.';

  @override
  String get viewMap => 'नकाशा पहा';

  @override
  String get getDirections => 'दिशा मिळवा';

  @override
  String get quickAccessTitle => 'जलद प्रवेश';

  @override
  String get appointmentsTitle => 'भेटी (Appointments)';

  @override
  String get prescriptionsTitle => 'औषधोपचार';

  @override
  String get referralsTitle => 'संदर्भ (Referrals)';

  @override
  String get yourFollowUpsTitle => 'तुमचे फॉलो-अप';

  @override
  String get noUpcomingFollowUps => 'कोणतेही आगामी फॉलो-अप नाहीत';

  @override
  String get emergencyHelpTitle => 'तातडीची मदत';

  @override
  String get getEmergencyHelpButton => 'तातडीची मदत कॉल (१०८)';

  @override
  String get emergencyNotice =>
      'गंभीर वैद्यकीय आणीबाणीच्या प्रसंगी, १०८ वर कॉल करा किंवा ताबडतोब जवळच्या रुग्णालयात जा.';

  @override
  String get navHome => 'मुख्यपृष्ठ';

  @override
  String get navHealth => 'आरोग्य';

  @override
  String get navProfile => 'प्रोफाइल';

  @override
  String kmAway(String distance) {
    return '$distance किमी अंतरावर';
  }

  @override
  String get open247 => '२४/७ उघडे आहे';

  @override
  String get emergencyServicesAvailable => 'तातडीची सेवा उपलब्ध';
}
