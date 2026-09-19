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

  @override
  String get locationTitle => 'Select Location';

  @override
  String get locationSubtitle => 'Choose how you want to provide your location';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get useCurrentLocationDesc => 'Fetch location automatically using GPS';

  @override
  String get enterLocationManually => 'Enter Location Manually';

  @override
  String get enterLocationManuallyDesc =>
      'Enter village, district, and PIN code';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get selectedLocation => 'Selected Location';

  @override
  String get adjustPinPrompt =>
      'Move map to place the pin on your exact location';

  @override
  String get village => 'Village / Town';

  @override
  String get villageHint => 'Enter village or town name';

  @override
  String get district => 'District';

  @override
  String get districtHint => 'e.g. Pune, Satara, Nagpur';

  @override
  String get state => 'State';

  @override
  String get stateHint => 'e.g. Maharashtra';

  @override
  String get pincode => 'PIN Code';

  @override
  String get pincodeHint => '6-digit postal code';

  @override
  String get fullAddress => 'Full Address (Optional)';

  @override
  String get fullAddressHint => 'House no., street, landmark';

  @override
  String get saveLocationButton => 'Save Location';

  @override
  String get locationSaved => 'Location Saved';

  @override
  String get locationSavedDesc =>
      'Your location details have been linked to your patient profile.';

  @override
  String get locationPermissionRequired =>
      'Location permission is required to detect your current position.';

  @override
  String get locationServicesDisabled =>
      'Device location services are turned off. Please turn on GPS.';

  @override
  String get locationFetchFailed =>
      'Could not fetch GPS location. Please check your signal or enter manually.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get orEnterManually => 'Or Enter Location Manually';

  @override
  String get medicalRecordsTitle => 'Medical Records';

  @override
  String get medicalRecordsSubtitle => 'Manage your medical documents';

  @override
  String get medicalRecordsComingSoonDesc =>
      'In the upcoming phase, you will be able to upload prescriptions, lab reports, and medical history.';

  @override
  String get finishRegistration => 'Complete Registration';

  @override
  String get addMedicalRecordsTitle => 'Add your medical records';

  @override
  String get addMedicalRecordsSubtitle =>
      'You can upload prescriptions, lab reports, scans and other medical documents.';

  @override
  String get addMedicalRecordButton => 'Add Medical Record';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get selectCategoryTitle => 'Select Document Category';

  @override
  String get selectCategorySubtitle =>
      'Choose what type of document you are adding';

  @override
  String get categoryPrescription => 'Prescription';

  @override
  String get categoryPrescriptionDesc =>
      'Doctor\'s prescriptions and medication advice';

  @override
  String get categoryLabReport => 'Lab Report';

  @override
  String get categoryLabReportDesc =>
      'Blood tests, urine tests, pathology reports';

  @override
  String get categoryScanXray => 'Scan / X-Ray';

  @override
  String get categoryScanXrayDesc =>
      'X-rays, MRI, CT scans, ultrasound reports';

  @override
  String get categoryDischargeSummary => 'Discharge Summary';

  @override
  String get categoryDischargeSummaryDesc =>
      'Hospital admission and discharge notes';

  @override
  String get categoryOther => 'Other Document';

  @override
  String get categoryOtherDesc =>
      'Vaccination records, bills, other health notes';

  @override
  String get chooseFile => 'Choose File';

  @override
  String get chooseFilePrompt => 'Select PDF or Image from your device';

  @override
  String get supportedFormatsNotice => 'Allowed: PDF, JPG, PNG (Max 10 MB)';

  @override
  String get documentPreviewTitle => 'Confirm Document';

  @override
  String get documentPreviewSubtitle =>
      'Check document details before uploading';

  @override
  String get fileNameLabel => 'File Name';

  @override
  String get fileSizeLabel => 'File Size';

  @override
  String get fileTypeLabel => 'File Type';

  @override
  String get categoryLabel => 'Category';

  @override
  String get notesLabel => 'Add a note (optional)';

  @override
  String get notesHint => 'e.g. Prescription from last visit';

  @override
  String get uploadButton => 'Upload Document';

  @override
  String get changeFileButton => 'Change File';

  @override
  String get cancel => 'Cancel';

  @override
  String get uploadingTitle => 'Uploading medical report...';

  @override
  String get uploadSuccessTitle => 'Medical record added';

  @override
  String get uploadSuccessDesc =>
      'Your medical record has been saved securely.';

  @override
  String get viewMedicalRecords => 'View Medical Records';

  @override
  String get addAnotherRecord => 'Add Another Record';

  @override
  String get noRecordsTitle => 'No medical records yet';

  @override
  String get noRecordsDesc =>
      'You can add prescriptions, lab reports, scans and other medical documents here.';

  @override
  String get openRecord => 'Open';

  @override
  String get deleteRecord => 'Delete';

  @override
  String get deleteConfirmTitle => 'Delete this medical record?';

  @override
  String get deleteConfirmDesc =>
      'Once deleted, this document cannot be recovered.';

  @override
  String get recordDeleted => 'Medical record deleted successfully';

  @override
  String get errorFileSizeExceeded =>
      'File size exceeds 10 MB limit. Please select a smaller file.';

  @override
  String get errorUnsupportedFormat =>
      'Unsupported file format. Please select PDF, JPG, or PNG.';

  @override
  String get errorUploadFailed =>
      'Couldn\'t save the document. Please try again.';

  @override
  String get errorDeleteFailed => 'Failed to delete record. Please try again.';

  @override
  String get errorLoadRecordsFailed =>
      'Could not load medical records. Pull down to refresh.';

  @override
  String get errorOpenDocumentFailed =>
      'Could not open document. Please try again.';

  @override
  String get openingDocument => 'Opening document...';

  @override
  String get refreshRecords => 'Pull down to refresh';

  @override
  String get validationPincode => 'Please enter a valid 6-digit PIN code.';

  @override
  String get validationVillage => 'Please enter your village or town name.';

  @override
  String get validationDistrict => 'Please enter your district name.';

  @override
  String get validationState => 'Please enter your state name.';

  @override
  String get fetchingGps => 'Fetching current location...';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name 👋';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Good afternoon, $name 👋';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name 👋';
  }

  @override
  String greetingGeneric(String name) {
    return 'Hello, $name 👋';
  }

  @override
  String patientIdLabel(String id) {
    return 'Patient ID: $id';
  }

  @override
  String get nurseCompanionTitle => 'AI Nurse Companion';

  @override
  String get findHospitalTitle => 'Find the Hospital';

  @override
  String get findHospitalSubtitle =>
      'Tell us what health problem you\'re facing';

  @override
  String get describeHealthProblemHint =>
      'Describe your health problem (e.g. stomach pain, toothache)...';

  @override
  String get listeningVoiceInput => 'Listening... Speak now...';

  @override
  String get speechNotAvailable => 'Voice input active. Tap to start speaking.';

  @override
  String get findHospitalButton => 'Find Nearby Hospitals';

  @override
  String get searchingHospitals => 'Searching nearby healthcare facilities...';

  @override
  String get noHospitalsFound => 'No hospitals found matching your query.';

  @override
  String get viewMap => 'View Map';

  @override
  String get getDirections => 'Get Directions';

  @override
  String get quickAccessTitle => 'Quick Access';

  @override
  String get appointmentsTitle => 'Appointments';

  @override
  String get prescriptionsTitle => 'Prescriptions';

  @override
  String get referralsTitle => 'Referrals';

  @override
  String get yourFollowUpsTitle => 'Your Follow-ups';

  @override
  String get noUpcomingFollowUps => 'No upcoming follow-ups';

  @override
  String get emergencyHelpTitle => 'Emergency Help';

  @override
  String get getEmergencyHelpButton => 'Call Emergency (108)';

  @override
  String get emergencyNotice =>
      'In case of severe medical emergency, call 108 or go to the nearest hospital immediately.';

  @override
  String get navHome => 'Home';

  @override
  String get navHealth => 'Health';

  @override
  String get navProfile => 'Profile';

  @override
  String kmAway(String distance) {
    return '$distance km away';
  }

  @override
  String get open247 => 'Open 24/7';

  @override
  String get emergencyServicesAvailable => 'Emergency Care Available';
}
