/// All named route paths used by GoRouter.
/// Centralizing them here prevents typos and makes refactoring safe.
class RouteNames {
  RouteNames._();

  static const String intro = '/';
  static const String splash = '/splash';
  static const String languageSelection = '/language';
  static const String roleSelection = '/role-select';

  // Login routes
  static const String patientLogin = '/login/patient';
  static const String patientOtp = '/login/patient/otp';
  static const String patientAuthSuccess = '/login/patient/success';
  static const String ashaLogin = '/login/asha';
  static const String doctorLogin = '/login/doctor';
  static const String hospitalAdminLogin = '/login/hospital-admin';

  // Registration routes
  static const String registrationRoleSelection = '/register';
  static const String registrationPlaceholder = '/register/placeholder';
  static const String patientRegistration = '/register/patient';
  static const String patientRegistrationSuccess = '/register/patient/success';
  static const String patientLocationChoice = '/register/patient/location';
  static const String patientLocationMap = '/register/patient/location/map';
  static const String patientLocationManual =
      '/register/patient/location/manual';
  static const String patientLocationSuccess =
      '/register/patient/location/success';
  static const String medicalRecordsPlaceholder =
      '/register/patient/medical-records';
  // Patient Dashboard routes
  static const String patientDashboard = '/patient/dashboard';
  static const String hospitalMap = '/patient/hospital-map';

  // Medical Records routes
  static const String patientMedicalRecords =
      '/patient/medical-records';
  static const String addMedicalRecordCategory =
      '/patient/medical-records/category';
  static const String medicalRecordPreview =
      '/patient/medical-records/preview';
  static const String medicalRecordSuccess =
      '/patient/medical-records/success';

  // ASHA Worker routes
  static const String ashaRegister = '/register/asha';
  static const String ashaDashboard = '/asha/dashboard';
  static const String ashaFamilyRegistration = '/asha/family/register';
  static const String ashaHomeVisit = '/asha/visit';
  static const String ashaHealthSurvey = '/asha/visit/survey';
  static const String ashaVisitHistory = '/asha/visits/history';
  static const String ashaVaccination = '/asha/vaccination';
  static const String ashaMaternal = '/asha/maternal';
  static const String ashaInfantCare = '/asha/infant-care';
  static const String ashaReportIssue = '/asha/report-issue';
  static const String ashaAwareness = '/asha/awareness';
  static const String ashaFollowUps = '/asha/follow-ups';
  static const String ashaProfile = '/asha/profile';

  // Hospital Admin - Community Health Alerts & OPD
  static const String adminCommunityAlerts = '/admin/community-alerts';
  static const String adminCreateAwareness = '/admin/create-awareness';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminOpdSlip = '/admin/opd-slip';

  // Patient - Health Awareness
  static const String patientAwareness = '/patient/awareness';

  // Patient QR Display
  static const String patientQrDisplay = '/patient/qr-code';

  // Doctor Dashboard routes
  static const String doctorDashboard = '/doctor/dashboard';
  static const String doctorQrScanner = '/doctor/scan-qr';
  static const String doctorPatientRecord = '/doctor/patient-record';
}
