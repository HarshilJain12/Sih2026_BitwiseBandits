import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Handles safe and idempotent Firebase initialization before the app launches.
class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _isInitialized = false;

  /// Returns whether Firebase has been successfully initialized.
  static bool get isInitialized => _isInitialized;

  /// Initializes the default Firebase application instance using options generated
  /// by the FlutterFire CLI for the current platform.
  ///
  /// Logs diagnostic status in debug mode without exposing sensitive keys or tokens.
  static Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('[Firebase] Already initialized.');
      }
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('[Firebase] Firebase initialized successfully.');
      }
    } catch (e, stackTrace) {
      _isInitialized = false;
      if (kDebugMode) {
        debugPrint('[Firebase] Firebase initialization failed: $e');
        debugPrint('[Firebase] Stack trace: $stackTrace');
      }
      // Rethrow to allow app startup error boundary handling
      rethrow;
    }
  }
}
