/// All named route paths used by GoRouter.
/// Centralizing them here prevents typos and makes refactoring safe.
class RouteNames {
  RouteNames._();

  static const String splash = '/';
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
}
