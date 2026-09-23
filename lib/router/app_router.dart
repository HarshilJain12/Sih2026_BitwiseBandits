import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/route_names.dart';
import '../models/hospital_result.dart';
import '../models/medical_record.dart';
import '../models/medical_record_category.dart';
import '../models/patient.dart';
import '../models/user_role.dart';
import '../providers/app_state_provider.dart';
import '../screens/doctor_dashboard/doctor_dashboard_screen.dart';
import '../screens/doctor_dashboard/doctor_patient_record_screen.dart';
import '../screens/doctor_dashboard/doctor_qr_scanner_screen.dart';
import '../screens/language_selection/language_selection_screen.dart';
import '../screens/login/asha/asha_login_screen.dart';
import '../screens/login/doctor/doctor_login_screen.dart';
import '../screens/login/hospital_admin/hospital_admin_login_screen.dart';
import '../screens/login/patient/patient_auth_success_screen.dart';
import '../screens/login/patient/patient_login_screen.dart';
import '../screens/login/patient/patient_otp_screen.dart';
import '../screens/registration/asha/asha_registration_screen.dart';
import '../screens/asha_dashboard/asha_dashboard_screen.dart';
import '../screens/family/asha_family_registration_screen.dart';
import '../screens/home_visit/asha_home_visit_screen.dart';
import '../screens/home_visit/asha_health_survey_screen.dart';
import '../screens/alerts/asha_report_issue_screen.dart';
import '../screens/vaccination/asha_vaccination_screen.dart';
import '../screens/maternal/asha_maternal_screen.dart';
import '../screens/follow_ups/asha_follow_ups_screen.dart';
import '../screens/placeholders/asha_placeholders.dart';
import '../screens/alerts/asha_awareness_screen.dart';
import '../screens/alerts/admin_community_alerts_screen.dart';
import '../screens/alerts/admin_create_awareness_screen.dart';
import '../screens/alerts/patient_awareness_screen.dart';
import '../models/family.dart';
import '../models/community_health_alert.dart';
import '../screens/medical_records/add_medical_record_category_screen.dart';
import '../screens/medical_records/medical_record_preview_screen.dart';
import '../screens/medical_records/medical_record_success_screen.dart';
import '../screens/medical_records/patient_medical_records_screen.dart';
import '../screens/patient_dashboard/hospital_map_screen.dart';
import '../screens/patient_dashboard/patient_dashboard_screen.dart';
import '../screens/patient_dashboard/patient_qr_display_screen.dart';
import '../screens/registration/patient/patient_location_choice_screen.dart';
import '../screens/registration/patient/patient_location_manual_screen.dart';
import '../screens/registration/patient/patient_location_map_screen.dart';
import '../screens/registration/patient/patient_location_success_screen.dart';
import '../screens/registration/patient/patient_registration_screen.dart';
import '../screens/registration/patient/patient_registration_success_screen.dart';
import '../screens/registration/placeholder/registration_placeholder_screen.dart';
import '../screens/registration/role_selection/registration_role_selection_screen.dart';
import '../screens/role_selection/role_selection_screen.dart';

/// App-wide GoRouter configuration.
///
/// Route guard: if the user has already selected a language, redirect the
/// splash/root to role selection. If no language is saved, show language screen.
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

        // Registration - Patient Registration Success (Phase 2D legacy)
        GoRoute(
          path: RouteNames.patientRegistrationSuccess,
          builder: (context, state) {
            final patient = state.extra as Patient;
            return PatientRegistrationSuccessScreen(patient: patient);
          },
        ),

        // Registration - Patient Location Choice
        GoRoute(
          path: RouteNames.patientLocationChoice,
          builder: (context, state) {
            final patient = state.extra as Patient;
            return PatientLocationChoiceScreen(patient: patient);
          },
        ),

        // Registration - Patient Location Map
        GoRoute(
          path: RouteNames.patientLocationMap,
          builder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            final patient = map['patient'] as Patient;
            final initialLat = (map['initialLat'] as num).toDouble();
            final initialLng = (map['initialLng'] as num).toDouble();
            return PatientLocationMapScreen(
              patient: patient,
              initialLat: initialLat,
              initialLng: initialLng,
            );
          },
        ),

        // Registration - Patient Location Manual
        GoRoute(
          path: RouteNames.patientLocationManual,
          builder: (context, state) {
            final patient = state.extra as Patient;
            return PatientLocationManualScreen(patient: patient);
          },
        ),

        // Registration - Patient Location Success
        GoRoute(
          path: RouteNames.patientLocationSuccess,
          builder: (context, state) {
            final patient = state.extra as Patient;
            return PatientLocationSuccessScreen(patient: patient);
          },
        ),

        // Medical Records (Registration & Standalone)
        GoRoute(
          path: RouteNames.medicalRecordsPlaceholder,
          builder: (context, state) {
            if (state.extra is Patient) {
              final patient = state.extra as Patient;
              return PatientMedicalRecordsScreen(
                patientId: patient.patientId,
                patient: patient,
                isRegistration: true,
              );
            } else if (state.extra is Map<String, dynamic>) {
              final map = state.extra as Map<String, dynamic>;
              return PatientMedicalRecordsScreen(
                patientId: map['patientId'] as String,
                isRegistration: map['isRegistration'] as bool? ?? false,
              );
            }
            final patientId = state.extra as String? ?? '';
            return PatientMedicalRecordsScreen(
              patientId: patientId,
              isRegistration: false,
            );
          },
        ),

        GoRoute(
          path: RouteNames.patientMedicalRecords,
          builder: (context, state) {
            if (state.extra is Patient) {
              final patient = state.extra as Patient;
              return PatientMedicalRecordsScreen(
                patientId: patient.patientId,
                patient: patient,
                isRegistration: false,
              );
            } else if (state.extra is Map<String, dynamic>) {
              final map = state.extra as Map<String, dynamic>;
              return PatientMedicalRecordsScreen(
                patientId: map['patientId'] as String,
                isRegistration: map['isRegistration'] as bool? ?? false,
              );
            }
            final patientId = state.extra as String? ?? '';
            return PatientMedicalRecordsScreen(
              patientId: patientId,
              isRegistration: false,
            );
          },
        ),

        // Add Medical Record - Category Selection
        GoRoute(
          path: RouteNames.addMedicalRecordCategory,
          builder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            final patientId = map['patientId'] as String;
            final isRegistration = map['isRegistration'] as bool? ?? false;
            return AddMedicalRecordCategoryScreen(
              patientId: patientId,
              isRegistration: isRegistration,
            );
          },
        ),

        // Medical Record Preview & Confirmation
        GoRoute(
          path: RouteNames.medicalRecordPreview,
          builder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            return MedicalRecordPreviewScreen(
              patientId: map['patientId'] as String,
              category: map['category'] as MedicalRecordCategory,
              fileName: map['fileName'] as String,
              fileSizeBytes: map['fileSizeBytes'] as int,
              mimeType: map['mimeType'] as String,
              bytes: map['bytes'] as Uint8List,
              isRegistration: map['isRegistration'] as bool? ?? false,
            );
          },
        ),

        // Medical Record Upload Success
        GoRoute(
          path: RouteNames.medicalRecordSuccess,
          builder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            return MedicalRecordSuccessScreen(
              patientId: map['patientId'] as String,
              record: map['record'] as MedicalRecord,
              isRegistration: map['isRegistration'] as bool? ?? false,
            );
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

        // Patient Home Dashboard
        GoRoute(
          path: RouteNames.patientDashboard,
          builder: (context, state) {
            final patient =
                state.extra is Patient ? state.extra as Patient : null;
            return PatientDashboardScreen(patient: patient);
          },
        ),

        // Hospital Map Screen
        GoRoute(
          path: RouteNames.hospitalMap,
          builder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            final selected = map['selectedHospital'] as HospitalResult;
            final all = map['allHospitals'] as List<HospitalResult>;
            final userLat = map['userLat'] as double?;
            final userLng = map['userLng'] as double?;
            return HospitalMapScreen(
              selectedHospital: selected,
              allHospitals: all,
              userLat: userLat,
              userLng: userLng,
            );
          },
        ),

        // ASHA Routes
        GoRoute(
          path: RouteNames.ashaRegister,
          builder: (context, state) => const AshaRegistrationScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaDashboard,
          builder: (context, state) => const AshaDashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaFamilyRegistration,
          builder: (context, state) => const AshaFamilyRegistrationScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaHomeVisit,
          builder: (context, state) => const AshaHomeVisitScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaHealthSurvey,
          builder: (context, state) {
            final family = state.extra as Family;
            return AshaHealthSurveyScreen(family: family);
          },
        ),
        GoRoute(
          path: RouteNames.ashaReportIssue,
          builder: (context, state) => const AshaReportIssueScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaVaccination,
          builder: (context, state) => const AshaVaccinationScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaMaternal,
          builder: (context, state) => const AshaMaternalScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaFollowUps,
          builder: (context, state) => const AshaFollowUpsScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaInfantCare,
          builder: (context, state) => const AshaInfantCareScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaVisitHistory,
          builder: (context, state) => const AshaVisitHistoryScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaProfile,
          builder: (context, state) => const AshaProfileScreen(),
        ),
        GoRoute(
          path: RouteNames.ashaAwareness,
          builder: (context, state) => const AshaAwarenessScreen(),
        ),

        // Admin Routes
        GoRoute(
          path: RouteNames.adminCommunityAlerts,
          builder: (context, state) => const AdminCommunityAlertsScreen(),
        ),
        GoRoute(
          path: RouteNames.adminCreateAwareness,
          builder: (context, state) {
            final alert = state.extra as CommunityHealthAlert?;
            return AdminCreateAwarenessScreen(alert: alert);
          },
        ),

        // Patient Awareness Route
        GoRoute(
          path: RouteNames.patientAwareness,
          builder: (context, state) => const PatientAwarenessScreen(),
        ),

        // Patient QR Display
        GoRoute(
          path: RouteNames.patientQrDisplay,
          builder: (context, state) {
            final patient = state.extra is Patient ? state.extra as Patient : null;
            return PatientQrDisplayScreen(patient: patient);
          },
        ),

        // Doctor Dashboard
        GoRoute(
          path: RouteNames.doctorDashboard,
          builder: (context, state) => const DoctorDashboardScreen(),
        ),

        // Doctor QR Scanner
        GoRoute(
          path: RouteNames.doctorQrScanner,
          builder: (context, state) => const DoctorQrScannerScreen(),
        ),

        // Doctor Patient Record
        GoRoute(
          path: RouteNames.doctorPatientRecord,
          builder: (context, state) {
            final patientId = state.extra as String? ?? '';
            return DoctorPatientRecordScreen(patientId: patientId);
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
    context.watch<AppStateProvider>();
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
