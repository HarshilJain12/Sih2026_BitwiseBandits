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
