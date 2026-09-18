// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Healthcare App';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseLanguageSubtitle => 'भाषा चुनें · भाषा निवडा';

  @override
  String get chooseRole => 'Who are you?';

  @override
  String get chooseRoleSubtitle => 'Select your role to continue';

  @override
  String get rolePatient => 'Patient / Citizen';

  @override
  String get rolePatientDesc => 'Access healthcare services';

  @override
  String get roleAsha => 'ASHA Worker';

  @override
  String get roleAshaDesc => 'Community health worker';

  @override
  String get roleDoctor => 'Doctor';

  @override
  String get roleDoctorDesc => 'Medical professional';

  @override
  String get roleHospitalAdmin => 'Hospital Admin';

  @override
  String get roleHospitalAdminDesc => 'Facility management';

  @override
  String get login => 'Login';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get mobileNumberHint => 'Enter 10-digit mobile number';

  @override
  String get continueButton => 'Continue';

  @override
  String get getOtp => 'Get OTP';

  @override
  String get otpTitle => 'Verify OTP';

  @override
  String otpSentTo(String phone) {
    return 'OTP sent to +91 $phone';
  }

  @override
  String get otpHint => 'Enter 6-digit OTP';

  @override
  String get verifyButton => 'Verify & Login';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get ashaId => 'ASHA ID';

  @override
  String get ashaIdHint => 'Enter your ASHA Worker ID';

  @override
  String get doctorId => 'Doctor ID';

  @override
  String get doctorIdHint => 'Enter your Doctor ID';

  @override
  String get hospitalId => 'Hospital ID';

  @override
  String get hospitalIdHint => 'Enter your Hospital ID';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get loginButton => 'Login';

  @override
  String get firstTimeRegister => 'First time? Register';

  @override
  String get registerTitle => 'Register';

  @override
  String get registerSubtitle => 'Select your role to register';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String comingSoonDesc(String role) {
    return 'Registration for $role will be implemented in the next phase.';
  }

  @override
  String get back => 'Back';

  @override
  String get loading => 'Please wait...';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorInvalidCredentials =>
      'Invalid ID or password. Please try again.';

  @override
  String get errorInvalidOtp => 'Invalid OTP. Please check and try again.';

  @override
  String get validationRequired => 'This field is required.';

  @override
  String get validationPhone => 'Please enter a valid 10-digit mobile number.';

  @override
  String get validationOtp => 'Please enter a valid 6-digit OTP.';

  @override
  String get validationMinLength => 'Must be at least 6 characters.';

  @override
  String get mockOtpHint => 'Use 123456 for testing';

  @override
  String selectedRole(String role) {
    return 'Selected role: $role';
  }

  @override
  String get phoneAuthNotice =>
      'Your phone number will be used to verify your account. SMS charges may apply depending on your mobile operator.';

  @override
  String get errorInvalidPhone => 'Please enter a valid phone number.';

  @override
  String get errorSessionExpired =>
      'This OTP has expired. Please request a new OTP.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Please wait a while and try again.';

  @override
  String get errorNetwork =>
      'Please check your internet connection and try again.';

  @override
  String get phoneVerifiedSuccess => 'Phone verified successfully';

  @override
  String get phoneVerifiedSubtitle => 'Your account has been authenticated.';

  @override
  String get firebaseAuthSuccess => 'Firebase authentication successful';

  @override
  String debugFirebaseUid(String uid) {
    return 'Firebase UID: $uid';
  }

  @override
  String get signOut => 'Sign Out';

  @override
  String get createPatientProfileTitle => 'Create your patient profile';

  @override
  String get createPatientProfileSubtitle =>
      'Enter a few basic details to get started.';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'Enter full name';

  @override
  String get age => 'Age';

  @override
  String get ageHint => 'e.g. 25';

  @override
  String get years => 'years';

  @override
  String get weight => 'Weight';

  @override
  String get weightHint => 'e.g. 65';

  @override
  String get kg => 'kg';

  @override
  String get height => 'Height';

  @override
  String get heightHint => 'e.g. 170';

  @override
  String get cm => 'cm';

  @override
  String get createProfileButton => 'Create Patient Profile';

  @override
  String get verifiedPhone => 'Verified phone';

  @override
  String get patientProfileCreated => 'Patient profile created';

  @override
  String get yourPatientId => 'Your Patient ID';

  @override
  String get copyPatientId => 'Copy Patient ID';

  @override
  String get patientIdCopied => 'Patient ID copied to clipboard';

  @override
  String get validationName => 'Please enter your name.';

  @override
  String get validationAge => 'Please enter a valid age (1–120).';

  @override
  String get validationWeight => 'Please enter a valid weight in kg.';

  @override
  String get validationHeight => 'Please enter a valid height in cm.';

  @override
  String get existingProfileFound => 'Existing patient profile found.';
}
