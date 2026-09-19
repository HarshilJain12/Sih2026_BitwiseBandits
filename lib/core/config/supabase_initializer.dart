import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Handles safe and idempotent Supabase initialization with Firebase Third-Party Auth.
class SupabaseInitializer {
  SupabaseInitializer._();

  static bool _isInitialized = false;

  /// Returns whether Supabase has been successfully initialized.
  static bool get isInitialized => _isInitialized;

  /// Initializes the default Supabase instance configured with Firebase Third-Party Auth.
  static Future<void> initialize({
    String? url,
    String? anonKey,
    FirebaseAuth? auth,
  }) async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('[Supabase] Already initialized.');
      }
      return;
    }

    final targetUrl = url ?? SupabaseConfig.supabaseUrl;
    final targetKey = anonKey ?? SupabaseConfig.supabasePublishableKey;
    final firebaseAuth = auth ?? FirebaseAuth.instance;

    try {
      await Supabase.initialize(
        url: targetUrl,
        publishableKey: targetKey,
        accessToken: () async {
          final user = firebaseAuth.currentUser;
          if (user == null) {
            if (kDebugMode) {
              debugPrint('[SupabaseAccessToken] No authenticated Firebase user (currentUser is null).');
            }
            return null;
          }
          try {
            var result = await user.getIdTokenResult();
            var roleClaim = result.claims?['role'];

            // If the role claim is not present in cached token, force-refresh from Firebase backend
            if (roleClaim != 'authenticated') {
              result = await user.getIdTokenResult(true);
              roleClaim = result.claims?['role'];
            }

            final token = await user.getIdToken();
            if (kDebugMode) {
              debugPrint('[SupabaseAccessToken] Sourced token for Firebase UID: ${user.uid}');
              debugPrint('[SupabaseAccessToken] Has "role" claim: ${roleClaim != null} (role: $roleClaim)');
              debugPrint('[SupabaseAccessToken] Claims keys: ${result.claims?.keys.toList()}');
            }
            return token;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[SupabaseAccessToken] Error obtaining Firebase ID token: $e');
            }
            return null;
          }
        },
      );
      _isInitialized = true;

      if (kDebugMode) {
        final uri = Uri.tryParse(targetUrl);
        final projectRef = uri?.host.split('.').firstOrNull ?? 'unknown';
        debugPrint('[Supabase] Initialized successfully with Firebase Third-Party Auth.');
        debugPrint('[Supabase] Supabase URL: $targetUrl');
        debugPrint('[Supabase] Supabase project ref: $projectRef');
      }
    } catch (e, stackTrace) {
      _isInitialized = false;
      if (kDebugMode) {
        debugPrint('[Supabase] Initialization failed: $e');
        debugPrint('[Supabase] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}
