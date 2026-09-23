import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/supabase_initializer.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/firebase/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_state_provider.dart';
import 'router/app_router.dart';
import 'services/firebase/firebase_auth_service.dart';
import 'services/firestore/account_service.dart';
import 'services/firestore/medical_record_service.dart';
import 'services/firestore/patient_service.dart';
import 'services/interfaces/auth_service.dart';
import 'services/interfaces/storage_service.dart';
import 'services/mock/mock_storage_service.dart';
import 'services/storage/medical_record_storage.dart';
import 'services/storage/supabase_medical_record_storage.dart';
import 'services/firestore/asha_data_service.dart';
import 'providers/asha_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before the application renders
  await FirebaseInitializer.initialize();

  // Initialize Supabase with Firebase Third-Party Auth integration
  await SupabaseInitializer.initialize();

  const firebaseService = FirebaseService();
  final storageService = MockStorageService();
  final authService = FirebaseAuthService();
  final accountService = AccountService();
  final patientService = PatientService();
  final medicalRecordStorage = SupabaseMedicalRecordStorage();
  final medicalRecordService = MedicalRecordService(storage: medicalRecordStorage);
  final ashaDataService = AshaDataService();
  final appState = AppStateProvider(storageService: storageService);
  final ashaState = AshaStateProvider(dataService: ashaDataService);

  await appState.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseService>.value(value: firebaseService),
        Provider<StorageService>.value(value: storageService),
        Provider<AuthService>.value(value: authService),
        Provider<AccountService>.value(value: accountService),
        Provider<PatientService>.value(value: patientService),
        Provider<MedicalRecordStorage>.value(value: medicalRecordStorage),
        Provider<MedicalRecordService>.value(value: medicalRecordService),
        Provider<AshaDataService>.value(value: ashaDataService),
        ChangeNotifierProvider<AppStateProvider>.value(value: appState),
        ChangeNotifierProvider<AshaStateProvider>.value(value: ashaState),
      ],
      child: const HealthcareApp(),
    ),
  );
}

class HealthcareApp extends StatefulWidget {
  const HealthcareApp({super.key});

  @override
  State<HealthcareApp> createState() => _HealthcareAppState();
}

class _HealthcareAppState extends State<HealthcareApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(context.read<AppStateProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return MaterialApp.router(
      title: 'Arogya Seva - Maharashtra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: appState.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth > 500) {
          return Container(
            color: const Color(0xFF1E293B),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                  maxHeight: 900,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
