import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// Temporary placeholder app title
  ///
  /// In en, this message translates to:
  /// **'Healthcare App'**
  String get appTitle;

  /// Language selection heading
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// Multilingual subtitle on language screen
  ///
  /// In en, this message translates to:
  /// **'भाषा चुनें · भाषा निवडा'**
  String get chooseLanguageSubtitle;

  /// Role selection screen heading
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get chooseRole;

  /// Role selection screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Select your role to continue'**
  String get chooseRoleSubtitle;

  /// Patient role name
  ///
  /// In en, this message translates to:
  /// **'Patient / Citizen'**
  String get rolePatient;

  /// Patient role description
  ///
  /// In en, this message translates to:
  /// **'Access healthcare services'**
  String get rolePatientDesc;

  /// ASHA Worker role name
  ///
  /// In en, this message translates to:
  /// **'ASHA Worker'**
  String get roleAsha;

  /// ASHA role description
  ///
  /// In en, this message translates to:
  /// **'Community health worker'**
  String get roleAshaDesc;

  /// Doctor role name
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get roleDoctor;

  /// Doctor role description
  ///
  /// In en, this message translates to:
  /// **'Medical professional'**
  String get roleDoctorDesc;

  /// Hospital Admin role name
  ///
  /// In en, this message translates to:
  /// **'Hospital Admin'**
  String get roleHospitalAdmin;

  /// Hospital Admin role description
  ///
  /// In en, this message translates to:
  /// **'Facility management'**
  String get roleHospitalAdminDesc;

  /// Generic login heading
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Phone number input label
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// Phone number input hint
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number'**
  String get mobileNumberHint;

  /// Continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Get OTP button label
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get getOtp;

  /// OTP screen heading
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get otpTitle;

  /// OTP sent confirmation message
  ///
  /// In en, this message translates to:
  /// **'OTP sent to +91 {phone}'**
  String otpSentTo(String phone);

  /// OTP input hint
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get otpHint;

  /// OTP verify button
  ///
  /// In en, this message translates to:
  /// **'Verify & Login'**
  String get verifyButton;

  /// Resend OTP link
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// Resend countdown timer
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// ASHA ID field label
  ///
  /// In en, this message translates to:
  /// **'ASHA ID'**
  String get ashaId;

  /// ASHA ID hint
  ///
  /// In en, this message translates to:
  /// **'Enter your ASHA Worker ID'**
  String get ashaIdHint;

  /// Doctor ID field label
  ///
  /// In en, this message translates to:
  /// **'Doctor ID'**
  String get doctorId;

  /// Doctor ID hint
  ///
  /// In en, this message translates to:
  /// **'Enter your Doctor ID'**
  String get doctorIdHint;

  /// Hospital ID field label
  ///
  /// In en, this message translates to:
  /// **'Hospital ID'**
  String get hospitalId;

  /// Hospital ID hint
  ///
  /// In en, this message translates to:
  /// **'Enter your Hospital ID'**
  String get hospitalIdHint;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// Registration CTA on role selection screen
  ///
  /// In en, this message translates to:
  /// **'First time? Register'**
  String get firstTimeRegister;

  /// Registration screen heading
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// Registration role selection subtitle
  ///
  /// In en, this message translates to:
  /// **'Select your role to register'**
  String get registerSubtitle;

  /// Coming soon placeholder heading
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Placeholder message for unimplemented registration
  ///
  /// In en, this message translates to:
  /// **'Registration for {role} will be implemented in the next phase.'**
  String comingSoonDesc(String role);

  /// Back navigation label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Loading state message
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get loading;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Wrong credentials error
  ///
  /// In en, this message translates to:
  /// **'Invalid ID or password. Please try again.'**
  String get errorInvalidCredentials;

  /// Wrong OTP error
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please check and try again.'**
  String get errorInvalidOtp;

  /// Required field validation
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get validationRequired;

  /// Phone validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit mobile number.'**
  String get validationPhone;

  /// OTP validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit OTP.'**
  String get validationOtp;

  /// Min length validation message
  ///
  /// In en, this message translates to:
  /// **'Must be at least 6 characters.'**
  String get validationMinLength;

  /// Development hint for mock OTP
  ///
  /// In en, this message translates to:
  /// **'Use 123456 for testing'**
  String get mockOtpHint;

  /// Shows selected role on login screen
  ///
  /// In en, this message translates to:
  /// **'Selected role: {role}'**
  String selectedRole(String role);

  /// Informational consent note regarding phone verification and SMS
  ///
  /// In en, this message translates to:
  /// **'Your phone number will be used to verify your account. SMS charges may apply depending on your mobile operator.'**
  String get phoneAuthNotice;

  /// Error when phone number format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get errorInvalidPhone;

  /// Error when OTP session has expired
  ///
  /// In en, this message translates to:
  /// **'This OTP has expired. Please request a new OTP.'**
  String get errorSessionExpired;

  /// Error when rate limit is exceeded
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a while and try again.'**
  String get errorTooManyRequests;

  /// Error when network connection fails
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get errorNetwork;

  /// Title on temporary success screen
  ///
  /// In en, this message translates to:
  /// **'Phone verified successfully'**
  String get phoneVerifiedSuccess;

  /// Subtitle on temporary success screen
  ///
  /// In en, this message translates to:
  /// **'Your account has been authenticated.'**
  String get phoneVerifiedSubtitle;

  /// Debug card title for Firebase authentication
  ///
  /// In en, this message translates to:
  /// **'Firebase authentication successful'**
  String get firebaseAuthSuccess;

  /// Debug text displaying the authenticated Firebase UID
  ///
  /// In en, this message translates to:
  /// **'Firebase UID: {uid}'**
  String debugFirebaseUid(String uid);

  /// Sign out button text
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Patient registration heading
  ///
  /// In en, this message translates to:
  /// **'Create your patient profile'**
  String get createPatientProfileTitle;

  /// Patient registration subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter a few basic details to get started.'**
  String get createPatientProfileSubtitle;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Full name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get fullNameHint;

  /// Age field label
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// Age field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 25'**
  String get ageHint;

  /// Years unit label
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// Weight field label
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// Weight field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 65'**
  String get weightHint;

  /// Kilograms unit label
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// Height field label
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// Height field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 170'**
  String get heightHint;

  /// Centimeters unit label
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get cm;

  /// Submit button on patient registration screen
  ///
  /// In en, this message translates to:
  /// **'Create Patient Profile'**
  String get createProfileButton;

  /// Label for verified phone indicator
  ///
  /// In en, this message translates to:
  /// **'Verified phone'**
  String get verifiedPhone;

  /// Patient registration success title
  ///
  /// In en, this message translates to:
  /// **'Patient profile created'**
  String get patientProfileCreated;

  /// Label above generated unique patient ID
  ///
  /// In en, this message translates to:
  /// **'Your Patient ID'**
  String get yourPatientId;

  /// Copy patient ID button text
  ///
  /// In en, this message translates to:
  /// **'Copy Patient ID'**
  String get copyPatientId;

  /// Snackbar message when patient ID is copied
  ///
  /// In en, this message translates to:
  /// **'Patient ID copied to clipboard'**
  String get patientIdCopied;

  /// Validation error for name field
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get validationName;

  /// Validation error for age field
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age (1–120).'**
  String get validationAge;

  /// Validation error for weight field
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight in kg.'**
  String get validationWeight;

  /// Validation error for height field
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid height in cm.'**
  String get validationHeight;

  /// No description provided for @existingProfileFound.
  ///
  /// In en, this message translates to:
  /// **'Existing patient profile found.'**
  String get existingProfileFound;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get locationTitle;

  /// No description provided for @locationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to provide your location'**
  String get locationSubtitle;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @useCurrentLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Fetch location automatically using GPS'**
  String get useCurrentLocationDesc;

  /// No description provided for @enterLocationManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Location Manually'**
  String get enterLocationManually;

  /// No description provided for @enterLocationManuallyDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter village, district, and PIN code'**
  String get enterLocationManuallyDesc;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// No description provided for @adjustPinPrompt.
  ///
  /// In en, this message translates to:
  /// **'Move map to place the pin on your exact location'**
  String get adjustPinPrompt;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village / Town'**
  String get village;

  /// No description provided for @villageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter village or town name'**
  String get villageHint;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @districtHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pune, Satara, Nagpur'**
  String get districtHint;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @stateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Maharashtra'**
  String get stateHint;

  /// No description provided for @pincode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get pincode;

  /// No description provided for @pincodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit postal code'**
  String get pincodeHint;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address (Optional)'**
  String get fullAddress;

  /// No description provided for @fullAddressHint.
  ///
  /// In en, this message translates to:
  /// **'House no., street, landmark'**
  String get fullAddressHint;

  /// No description provided for @saveLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get saveLocationButton;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location Saved'**
  String get locationSaved;

  /// No description provided for @locationSavedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your location details have been linked to your patient profile.'**
  String get locationSavedDesc;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to detect your current position.'**
  String get locationPermissionRequired;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Device location services are turned off. Please turn on GPS.'**
  String get locationServicesDisabled;

  /// No description provided for @locationFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch GPS location. Please check your signal or enter manually.'**
  String get locationFetchFailed;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @orEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Or Enter Location Manually'**
  String get orEnterManually;

  /// No description provided for @medicalRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get medicalRecordsTitle;

  /// No description provided for @medicalRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your medical documents'**
  String get medicalRecordsSubtitle;

  /// No description provided for @medicalRecordsComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'In the upcoming phase, you will be able to upload prescriptions, lab reports, and medical history.'**
  String get medicalRecordsComingSoonDesc;

  /// No description provided for @finishRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get finishRegistration;

  /// No description provided for @addMedicalRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your medical records'**
  String get addMedicalRecordsTitle;

  /// No description provided for @addMedicalRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can upload prescriptions, lab reports, scans and other medical documents.'**
  String get addMedicalRecordsSubtitle;

  /// No description provided for @addMedicalRecordButton.
  ///
  /// In en, this message translates to:
  /// **'Add Medical Record'**
  String get addMedicalRecordButton;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @selectCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Document Category'**
  String get selectCategoryTitle;

  /// No description provided for @selectCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what type of document you are adding'**
  String get selectCategorySubtitle;

  /// No description provided for @categoryPrescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get categoryPrescription;

  /// No description provided for @categoryPrescriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Doctor\'s prescriptions and medication advice'**
  String get categoryPrescriptionDesc;

  /// No description provided for @categoryLabReport.
  ///
  /// In en, this message translates to:
  /// **'Lab Report'**
  String get categoryLabReport;

  /// No description provided for @categoryLabReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Blood tests, urine tests, pathology reports'**
  String get categoryLabReportDesc;

  /// No description provided for @categoryScanXray.
  ///
  /// In en, this message translates to:
  /// **'Scan / X-Ray'**
  String get categoryScanXray;

  /// No description provided for @categoryScanXrayDesc.
  ///
  /// In en, this message translates to:
  /// **'X-rays, MRI, CT scans, ultrasound reports'**
  String get categoryScanXrayDesc;

  /// No description provided for @categoryDischargeSummary.
  ///
  /// In en, this message translates to:
  /// **'Discharge Summary'**
  String get categoryDischargeSummary;

  /// No description provided for @categoryDischargeSummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Hospital admission and discharge notes'**
  String get categoryDischargeSummaryDesc;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other Document'**
  String get categoryOther;

  /// No description provided for @categoryOtherDesc.
  ///
  /// In en, this message translates to:
  /// **'Vaccination records, bills, other health notes'**
  String get categoryOtherDesc;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @chooseFilePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select PDF or Image from your device'**
  String get chooseFilePrompt;

  /// No description provided for @supportedFormatsNotice.
  ///
  /// In en, this message translates to:
  /// **'Allowed: PDF, JPG, PNG (Max 10 MB)'**
  String get supportedFormatsNotice;

  /// No description provided for @documentPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Document'**
  String get documentPreviewTitle;

  /// No description provided for @documentPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check document details before uploading'**
  String get documentPreviewSubtitle;

  /// No description provided for @fileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileNameLabel;

  /// No description provided for @fileSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSizeLabel;

  /// No description provided for @fileTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'File Type'**
  String get fileTypeLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Prescription from last visit'**
  String get notesHint;

  /// No description provided for @uploadButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadButton;

  /// No description provided for @changeFileButton.
  ///
  /// In en, this message translates to:
  /// **'Change File'**
  String get changeFileButton;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @uploadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Uploading medical report...'**
  String get uploadingTitle;

  /// No description provided for @uploadSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical record added'**
  String get uploadSuccessTitle;

  /// No description provided for @uploadSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Your medical record has been saved securely.'**
  String get uploadSuccessDesc;

  /// No description provided for @viewMedicalRecords.
  ///
  /// In en, this message translates to:
  /// **'View Medical Records'**
  String get viewMedicalRecords;

  /// No description provided for @addAnotherRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Another Record'**
  String get addAnotherRecord;

  /// No description provided for @noRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'No medical records yet'**
  String get noRecordsTitle;

  /// No description provided for @noRecordsDesc.
  ///
  /// In en, this message translates to:
  /// **'You can add prescriptions, lab reports, scans and other medical documents here.'**
  String get noRecordsDesc;

  /// No description provided for @openRecord.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openRecord;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteRecord;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this medical record?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Once deleted, this document cannot be recovered.'**
  String get deleteConfirmDesc;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Medical record deleted successfully'**
  String get recordDeleted;

  /// No description provided for @errorFileSizeExceeded.
  ///
  /// In en, this message translates to:
  /// **'File size exceeds 10 MB limit. Please select a smaller file.'**
  String get errorFileSizeExceeded;

  /// No description provided for @errorUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format. Please select PDF, JPG, or PNG.'**
  String get errorUnsupportedFormat;

  /// No description provided for @errorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload document. Please check your internet connection and try again.'**
  String get errorUploadFailed;

  /// No description provided for @errorDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete record. Please try again.'**
  String get errorDeleteFailed;

  /// No description provided for @errorLoadRecordsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load medical records. Pull down to refresh.'**
  String get errorLoadRecordsFailed;

  /// No description provided for @errorOpenDocumentFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open document. Please try again.'**
  String get errorOpenDocumentFailed;

  /// No description provided for @openingDocument.
  ///
  /// In en, this message translates to:
  /// **'Opening document...'**
  String get openingDocument;

  /// No description provided for @refreshRecords.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get refreshRecords;

  /// No description provided for @validationPincode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit PIN code.'**
  String get validationPincode;

  /// No description provided for @validationVillage.
  ///
  /// In en, this message translates to:
  /// **'Please enter your village or town name.'**
  String get validationVillage;

  /// No description provided for @validationDistrict.
  ///
  /// In en, this message translates to:
  /// **'Please enter your district name.'**
  String get validationDistrict;

  /// No description provided for @validationState.
  ///
  /// In en, this message translates to:
  /// **'Please enter your state name.'**
  String get validationState;

  /// No description provided for @fetchingGps.
  ///
  /// In en, this message translates to:
  /// **'Fetching current location...'**
  String get fetchingGps;

  /// Morning greeting on dashboard
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name} 👋'**
  String greetingMorning(String name);

  /// Afternoon greeting on dashboard
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name} 👋'**
  String greetingAfternoon(String name);

  /// Evening greeting on dashboard
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name} 👋'**
  String greetingEvening(String name);

  /// Generic greeting on dashboard
  ///
  /// In en, this message translates to:
  /// **'Hello, {name} 👋'**
  String greetingGeneric(String name);

  /// Dashboard Patient ID label
  ///
  /// In en, this message translates to:
  /// **'Patient ID: {id}'**
  String patientIdLabel(String id);

  /// No description provided for @nurseCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Nurse Companion'**
  String get nurseCompanionTitle;

  /// No description provided for @findHospitalTitle.
  ///
  /// In en, this message translates to:
  /// **'Find the Hospital'**
  String get findHospitalTitle;

  /// No description provided for @findHospitalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what health problem you\'re facing'**
  String get findHospitalSubtitle;

  /// No description provided for @describeHealthProblemHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your health problem (e.g. stomach pain, toothache)...'**
  String get describeHealthProblemHint;

  /// No description provided for @listeningVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Listening... Speak now...'**
  String get listeningVoiceInput;

  /// No description provided for @speechNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input active. Tap to start speaking.'**
  String get speechNotAvailable;

  /// No description provided for @findHospitalButton.
  ///
  /// In en, this message translates to:
  /// **'Find Nearby Hospitals'**
  String get findHospitalButton;

  /// No description provided for @searchingHospitals.
  ///
  /// In en, this message translates to:
  /// **'Searching nearby healthcare facilities...'**
  String get searchingHospitals;

  /// No description provided for @noHospitalsFound.
  ///
  /// In en, this message translates to:
  /// **'No hospitals found matching your query.'**
  String get noHospitalsFound;

  /// No description provided for @viewMap.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get viewMap;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @quickAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccessTitle;

  /// No description provided for @appointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointmentsTitle;

  /// No description provided for @prescriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptionsTitle;

  /// No description provided for @referralsTitle.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get referralsTitle;

  /// No description provided for @yourFollowUpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Follow-ups'**
  String get yourFollowUpsTitle;

  /// No description provided for @noUpcomingFollowUps.
  ///
  /// In en, this message translates to:
  /// **'No upcoming follow-ups'**
  String get noUpcomingFollowUps;

  /// No description provided for @emergencyHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Help'**
  String get emergencyHelpTitle;

  /// No description provided for @getEmergencyHelpButton.
  ///
  /// In en, this message translates to:
  /// **'Call Emergency (108)'**
  String get getEmergencyHelpButton;

  /// No description provided for @emergencyNotice.
  ///
  /// In en, this message translates to:
  /// **'In case of severe medical emergency, call 108 or go to the nearest hospital immediately.'**
  String get emergencyNotice;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get navHealth;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Hospital distance label
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String kmAway(String distance);

  /// No description provided for @open247.
  ///
  /// In en, this message translates to:
  /// **'Open 24/7'**
  String get open247;

  /// No description provided for @emergencyServicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Emergency Care Available'**
  String get emergencyServicesAvailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
