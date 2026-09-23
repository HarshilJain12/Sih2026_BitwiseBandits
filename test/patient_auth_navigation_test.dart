import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:healthcare_app/core/constants/route_names.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/l10n/app_localizations.dart';
import 'package:healthcare_app/models/medical_record.dart';
import 'package:healthcare_app/models/patient.dart';
import 'package:healthcare_app/models/patient_location.dart';
import 'package:healthcare_app/providers/app_state_provider.dart';
import 'package:healthcare_app/screens/medical_records/patient_medical_records_screen.dart';
import 'package:healthcare_app/screens/registration/patient/medical_records_placeholder_screen.dart';
import 'package:healthcare_app/screens/registration/patient/patient_registration_success_screen.dart';
import 'package:healthcare_app/services/firestore/medical_record_service.dart';
import 'package:healthcare_app/services/firestore/patient_service.dart';
import 'package:healthcare_app/services/interfaces/auth_service.dart';
import 'package:healthcare_app/services/interfaces/storage_service.dart';
import 'package:healthcare_app/services/mock/mock_auth_service.dart';
import 'package:healthcare_app/services/mock/mock_storage_service.dart';
import 'package:provider/provider.dart';

class FakePatientService implements PatientService {
  FakePatientService({this.linkedPatients = const [], this.hasProfile = false});

  final List<Patient> linkedPatients;
  final bool hasProfile;

  @override
  Future<List<Patient>> getLinkedPatients({String? uid}) async => linkedPatients;

  @override
  Future<bool> hasPatientProfile({String? uid}) async => hasProfile;

  @override
  Future<Patient> createPatient({
    required String name,
    int? age,
    double? weightKg,
    double? heightCm,
    String relationship = 'self',
  }) async {
    return Patient(
      patientId: 'P-NEW123456',
      ownerUid: 'new_uid',
      name: name,
      phoneNumber: '+919999999999',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Patient?> getPatient(String patientId) async {
    return linkedPatients.where((p) => p.patientId == patientId).firstOrNull;
  }

  @override
  Future<bool> patientIdExists(String patientId) async => false;

  @override
  Future<Patient> updatePatientLocation({
    required String patientId,
    required PatientLocation location,
  }) async {
    final p = await getPatient(patientId);
    return (p ?? linkedPatients.first).copyWith(location: location);
  }

  @override
  Future<Patient?> getPatientById(String patientId) async {
    return linkedPatients.where((p) => p.patientId == patientId).firstOrNull;
  }

  @override
  Future<List<Patient>> searchPatientsByName(String query, {int limit = 20}) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];
    return linkedPatients
        .where((p) => p.name.toLowerCase().startsWith(trimmed))
        .take(limit)
        .toList();
  }
}

class FakeMedicalRecordService implements MedicalRecordService {
  @override
  Future<List<MedicalRecord>> getRecordsForPatient(String patientId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testExistingPatient = Patient(
    patientId: 'P-1G9I7YHB2H',
    ownerUid: 'P5CeG63YI8UQ4BRQs8MfTGGJ9sX2',
    name: 'Rahul Kumar',
    phoneNumber: '+919876543210',
    age: 28,
    weightKg: 70.0,
    heightCm: 175.0,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  group('Patient Auth & Navigation Unit/Widget Tests', () {
    late StorageService storageService;
    late AppStateProvider appState;
    late AuthService authService;

    setUp(() {
      storageService = MockStorageService();
      appState = AppStateProvider(storageService: storageService);
      authService = MockAuthService();
    });

    test('Canonical Identity Flow: UID -> patientLinks -> Patient ID -> Patient Profile', () {
      const firebaseUid = 'P5CeG63YI8UQ4BRQs8MfTGGJ9sX2';
      const patientId = 'P-1G9I7YHB2H';

      expect(testExistingPatient.ownerUid, equals(firebaseUid));
      expect(testExistingPatient.patientId, equals(patientId));
      expect(testExistingPatient.name, equals('Rahul Kumar'));
      expect(testExistingPatient.patientId, isNot(equals(firebaseUid)));
      expect(testExistingPatient.patientId, isNot(equals(testExistingPatient.phoneNumber)));
    });

    test('Patient Service retrieves linked patients by Firebase UID links', () async {
      final fakeService = FakePatientService(
        linkedPatients: [testExistingPatient],
        hasProfile: true,
      );

      final hasProfile = await fakeService.hasPatientProfile();
      expect(hasProfile, isTrue);

      final linked = await fakeService.getLinkedPatients();
      expect(linked.length, equals(1));
      expect(linked.first.patientId, equals('P-1G9I7YHB2H'));
      expect(linked.first.name, equals('Rahul Kumar'));
    });

    testWidgets('Skip on Medical Records Screen navigates directly to Patient Dashboard', (tester) async {
      String navigatedRoute = '';
      Patient? passedPatient;

      final router = GoRouter(
        initialLocation: '/test-medical-records',
        routes: [
          GoRoute(
            path: '/test-medical-records',
            builder: (context, state) => PatientMedicalRecordsScreen(
              patientId: testExistingPatient.patientId,
              patient: testExistingPatient,
              isRegistration: true,
            ),
          ),
          GoRoute(
            path: RouteNames.patientDashboard,
            builder: (context, state) {
              navigatedRoute = RouteNames.patientDashboard;
              passedPatient = state.extra as Patient?;
              return const Scaffold(body: Text('DASHBOARD_SCREEN'));
            },
          ),
        ],
      );

      final fakePatientService = FakePatientService(linkedPatients: [testExistingPatient]);
      final fakeMedService = FakeMedicalRecordService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppStateProvider>.value(value: appState),
            Provider<AuthService>.value(value: authService),
            Provider<PatientService>.value(value: fakePatientService),
            Provider<MedicalRecordService>.value(value: fakeMedService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find "Skip for now" button
      final skipBtn = find.text('Skip for now');
      expect(skipBtn, findsOneWidget);

      await tester.tap(skipBtn);
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(RouteNames.patientDashboard));
      expect(passedPatient?.patientId, equals('P-1G9I7YHB2H'));
      expect(passedPatient?.name, equals('Rahul Kumar'));
      expect(find.text('DASHBOARD_SCREEN'), findsOneWidget);
    });

    testWidgets('Medical Records Placeholder Finish navigates to Patient Dashboard', (tester) async {
      String navigatedRoute = '';
      Patient? passedPatient;

      final router = GoRouter(
        initialLocation: '/test-placeholder',
        routes: [
          GoRoute(
            path: '/test-placeholder',
            builder: (context, state) => MedicalRecordsPlaceholderScreen(
              patient: testExistingPatient,
            ),
          ),
          GoRoute(
            path: RouteNames.patientDashboard,
            builder: (context, state) {
              navigatedRoute = RouteNames.patientDashboard;
              passedPatient = state.extra as Patient?;
              return const Scaffold(body: Text('DASHBOARD_SCREEN'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppStateProvider>.value(value: appState),
            Provider<AuthService>.value(value: authService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final finishBtn = find.text('Complete Registration');
      expect(finishBtn, findsOneWidget);

      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(RouteNames.patientDashboard));
      expect(passedPatient?.patientId, equals('P-1G9I7YHB2H'));
      expect(find.text('DASHBOARD_SCREEN'), findsOneWidget);
    });

    testWidgets('Patient Registration Success Continue navigates to Patient Dashboard', (tester) async {
      String navigatedRoute = '';
      Patient? passedPatient;

      final router = GoRouter(
        initialLocation: '/test-reg-success',
        routes: [
          GoRoute(
            path: '/test-reg-success',
            builder: (context, state) => PatientRegistrationSuccessScreen(
              patient: testExistingPatient,
            ),
          ),
          GoRoute(
            path: RouteNames.patientDashboard,
            builder: (context, state) {
              navigatedRoute = RouteNames.patientDashboard;
              passedPatient = state.extra as Patient?;
              return const Scaffold(body: Text('DASHBOARD_SCREEN'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppStateProvider>.value(value: appState),
            Provider<AuthService>.value(value: authService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(RouteNames.patientDashboard));
      expect(passedPatient?.patientId, equals('P-1G9I7YHB2H'));
      expect(appState.currentPatientId, equals('P-1G9I7YHB2H'));
      expect(find.text('DASHBOARD_SCREEN'), findsOneWidget);
    });
  });
}
