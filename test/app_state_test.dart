import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/user_role.dart';
import 'package:healthcare_app/providers/app_state_provider.dart';
import 'package:healthcare_app/services/mock/mock_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AppStateProvider initializes with default locale', () async {
    final storage = MockStorageService();
    final provider = AppStateProvider(storageService: storage);
    expect(provider.isInitialized, isFalse);

    await provider.initialize();
    expect(provider.isInitialized, isTrue);
    expect(provider.locale.languageCode, equals('en'));
  });

  test('AppStateProvider changes and persists locale', () async {
    final storage = MockStorageService();
    final provider = AppStateProvider(storageService: storage);
    await provider.initialize();

    await provider.setLocale(const Locale('mr'));
    expect(provider.locale.languageCode, equals('mr'));
    expect(provider.hasSelectedLanguage, isTrue);
    expect(await storage.getLanguage(), equals('mr'));
  });

  test('AppStateProvider sets active role', () {
    final storage = MockStorageService();
    final provider = AppStateProvider(storageService: storage);
    expect(provider.selectedRole, isNull);

    provider.selectRole(UserRole.asha);
    expect(provider.selectedRole, equals(UserRole.asha));
  });
}
