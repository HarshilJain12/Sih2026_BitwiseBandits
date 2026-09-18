import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare_app/core/firebase/firebase_service.dart';
import 'package:healthcare_app/main.dart';
import 'package:healthcare_app/providers/app_state_provider.dart';
import 'package:healthcare_app/services/interfaces/auth_service.dart';
import 'package:healthcare_app/services/interfaces/storage_service.dart';
import 'package:healthcare_app/services/mock/mock_auth_service.dart';
import 'package:healthcare_app/services/mock/mock_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App smoke test - boots to initial screen', (
    WidgetTester tester,
  ) async {
    final storageService = MockStorageService();
    final authService = MockAuthService();
    final appState = AppStateProvider(storageService: storageService);
    await appState.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseService>.value(value: const FirebaseService()),
          Provider<StorageService>.value(value: storageService),
          Provider<AuthService>.value(value: authService),
          ChangeNotifierProvider<AppStateProvider>.value(value: appState),
        ],
        child: const HealthcareApp(),
      ),
    );

    // Pump frames to allow animations and routing
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Verify app renders
    expect(find.byType(HealthcareApp), findsOneWidget);
  });
}
