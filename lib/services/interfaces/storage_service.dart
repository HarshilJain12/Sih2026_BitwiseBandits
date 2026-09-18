/// Abstract interface for local key-value storage.
///
/// Currently implemented by [MockStorageService] using SharedPreferences.
/// Swap implementations without touching any UI code.
abstract class StorageService {
  /// Saves the selected language code (e.g. 'en', 'hi', 'mr').
  Future<void> saveLanguage(String languageCode);

  /// Returns the previously saved language code, or null if not set.
  Future<String?> getLanguage();

  /// Clears all stored data (e.g. on logout).
  Future<void> clear();
}
