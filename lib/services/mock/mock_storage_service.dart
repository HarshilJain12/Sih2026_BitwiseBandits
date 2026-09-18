import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../interfaces/storage_service.dart';

/// Mock implementation of [StorageService] using SharedPreferences.
///
/// This IS the production-ready implementation for local key-value storage.
/// The word "mock" here refers to the overall service layer being mockable;
/// SharedPreferences is the real persistence mechanism.
class MockStorageService implements StorageService {
  @override
  Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kSelectedLanguageKey, languageCode);
  }

  @override
  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.kSelectedLanguageKey);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
