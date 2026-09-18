import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_initializer.dart';

/// Foundation service for Firebase infrastructure.
///
/// Provides centralized access to the underlying [FirebaseApp] and initialization state.
/// Subsequent phases will build on this service foundation to connect:
/// - Firebase Authentication
/// - Cloud Firestore
/// - Firebase Storage
/// - Backend Cloud Functions
class FirebaseService {
  const FirebaseService();

  /// Whether Firebase has been initialized and is ready for use.
  bool get isInitialized => FirebaseInitializer.isInitialized;

  /// Returns the default [FirebaseApp] instance.
  ///
  /// Throws a [StateError] if Firebase has not yet been initialized.
  FirebaseApp get app {
    if (!isInitialized && Firebase.apps.isEmpty) {
      throw StateError(
        'Firebase has not been initialized. Ensure FirebaseInitializer.initialize() '
        'is called and awaited before accessing FirebaseService.',
      );
    }
    return Firebase.app();
  }

  /// Development-only diagnostics map.
  /// Safe to inspect during development; contains no sensitive keys or tokens.
  Map<String, dynamic> get diagnostics {
    if (!kDebugMode) return const {};

    return {
      'isInitialized': isInitialized,
      'appsCount': Firebase.apps.length,
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
    };
  }
}
