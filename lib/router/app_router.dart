import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/route_names.dart';
import '../models/user_role.dart';
import '../providers/app_state_provider.dart';
import '../screens/language_selection/language_selection_screen.dart';
import '../screens/role_selection/role_selection_screen.dart';
import '../screens/login/patient/patient_login_screen.dart';
import '../screens/login/patient/patient_otp_screen.dart';
import '../screens/login/patient/patient_auth_success_screen.dart';
import '../screens/login/asha/asha_login_screen.dart';
import '../screens/login/doctor/doctor_login_screen.dart';
import '../screens/login/hospital_admin/hospital_admin_login_screen.dart';
import '../screens/registration/role_selection/registration_role_selection_screen.dart';
import '../screens/registration/placeholder/registration_placeholder_screen.dart';
import '../screens/registration/patient/patient_registration_screen.dart';
import '../screens/registration/patient/patient_registration_success_screen.dart';
import '../models/patient.dart';

/// App-wide GoRouter configuration.
///
/// Route guard: if the user has already selected a language, redirect the
/// splash/root to role selection. If no language is saved, show language screen.
///
/// Future chunks can add auth guards here (e.g. redirect to /role-select if
/// not logged in, redirect to /dashboard if already authenticated).
class AppRouter {
  static GoRouter createRouter(AppStateProvider appState) {
    return GoRouter(
      refreshListenable: appState,
      initialLocation: RouteNames.splash,
      redirect: (context, state) {
        // Wait for initialization
        if (!appState.isInitialized) return null;

        // Root '/' redirect
        if (state.matchedLocation == RouteNames.splash) {
          if (appState.hasSelectedLanguage) {
            return RouteNames.roleSelection;
          }
          return RouteNames.languageSelection;
        }
        return null;
      },
      routes: [
        // Splash (handled by redirect above — renders empty briefly)
        GoRoute(
          path: RouteNames.splash,
          builder: (context, state) => const _SplashView(),
        ),

        // Language Selection
        GoRoute(
          path: RouteNames.languageSelection,
          builder: (context, state) => const LanguageSelectionScreen(),
        ),

        // Role Selection
        GoRoute(
          path: RouteNames.roleSelection,
          builder: (context, state) => const RoleSelectionScreen(),
        ),

        // Patient Login
        GoRoute(
          path: RouteNames.patientLogin,
          builder: (context, state) => const PatientLoginScreen(),
        ),

        // Patient OTP
        GoRoute(
          path: RouteNames.patientOtp,
          builder: (context, state) {
            if (state.extra is PatientOtpArgs) {
              final args = state.extra as PatientOtpArgs;
              return PatientOtpScreen(
                phoneNumber: args.phoneNumber,
                verificationId: args.verificationId,
                resendToken: args.resendToken,
              );
            }
            final phone = state.extra as String? ?? '';
            return PatientOtpScreen(phoneNumber: phone, verificationId: '');
          },
        ),

        // Patient Auth Success (Temporary state for Phase 2C)
        GoRoute(
          path: RouteNames.patientAuthSuccess,
          builder: (context, state) {
            String? uid;
            String? phoneNumber;
            if (state.extra is Map<String, dynamic>) {
              final map = state.extra as Map<String, dynamic>;
              uid = map['uid'] as String?;
              phoneNumber = map['phoneNumber'] as String?;
            } else if (state.extra is String) {
              uid = state.extra as String;
            }
            return PatientAuthSuccessScreen(uid: uid, phoneNumber: phoneNumber);
          },
        ),

        // ASHA Login
        GoRoute(
          path: RouteNames.ashaLogin,
          builder: (context, state) => const AshaLoginScreen(),
        ),

        // Doctor Login
        GoRoute(
          path: RouteNames.doctorLogin,
          builder: (context, state) => const DoctorLoginScreen(),
        ),

        // Hospital Admin Login
        GoRoute(
          path: RouteNames.hospitalAdminLogin,
          builder: (context, state) => const HospitalAdminLoginScreen(),
        ),

        // Registration - Role Selection
        GoRoute(
          path: RouteNames.registrationRoleSelection,
          builder: (context, state) => const RegistrationRoleSelectionScreen(),
        ),

        // Registration - Patient Basic Registration
        GoRoute(
          path: RouteNames.patientRegistration,
          builder: (context, state) => const PatientRegistrationScreen(),
        ),

        // Registration - Patient Registration Success
        GoRoute(
          path: RouteNames.patientRegistrationSuccess,
          builder: (context, state) {
            final patient = state.extra as Patient;
            return PatientRegistrationSuccessScreen(patient: patient);
          },
        ),

        // Registration - Placeholder
        GoRoute(
          path: RouteNames.registrationPlaceholder,
          builder: (context, state) {
            final role = state.extra as UserRole? ?? UserRole.patient;
            return RegistrationPlaceholderScreen(role: role);
          },
        ),
      ],
    );
  }
}

/// Minimal splash view while initialization completes.
class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    // Listen to initialization and redirect automatically via GoRouter's
    // redirect guard which re-evaluates when notifyListeners fires.
    context.watch<AppStateProvider>();
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
