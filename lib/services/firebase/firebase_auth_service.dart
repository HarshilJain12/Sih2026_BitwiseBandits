import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_role.dart';
import '../interfaces/auth_service.dart';
import '../mock/mock_auth_service.dart';

/// Real Firebase Phone Authentication service for the Civilian/Patient role.
///
/// Delegates staff login (ASHA, Doctor, Hospital Admin) to [MockAuthService]
/// to preserve Phase 1 staff functionality without changes.
///
/// Error handling maps raw Firebase exceptions strictly to typed [AuthFailureReason]
/// enums so that the UI layer remains exclusively responsible for localization.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    AuthService? staffAuthService,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _staffAuthService = staffAuthService ?? MockAuthService();

  final FirebaseAuth _firebaseAuth;
  final AuthService _staffAuthService;

  @override
  String? get currentUserId =>
      _firebaseAuth.currentUser?.uid ?? _staffAuthService.currentUserId;

  @override
  Future<AuthResult> loginWithPassword({
    required UserRole role,
    required String identifier,
    required String password,
  }) {
    // Preserve existing staff mock authentication
    return _staffAuthService.loginWithPassword(
      role: role,
      identifier: identifier,
      password: password,
    );
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    int? resendToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String uid) onVerificationCompleted,
    required void Function(AuthFailureReason reason) onVerificationFailed,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (kDebugMode) {
            debugPrint('[FirebaseAuth] Instant/auto verification completed.');
          }
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(
              credential,
            );
            final uid = userCredential.user?.uid;
            if (uid != null) {
              onVerificationCompleted(uid);
            } else {
              onVerificationFailed(AuthFailureReason.unknown);
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[FirebaseAuth] signInWithCredential error: $e');
            }
            onVerificationFailed(_mapException(e));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            debugPrint(
              '[FirebaseAuth] verificationFailed: code=${e.code}, message=${e.message}',
            );
          }
          onVerificationFailed(_mapFirebaseException(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          if (kDebugMode) {
            debugPrint(
              '[FirebaseAuth] codeSent: verificationId=$verificationId, resendToken=$resendToken',
            );
          }
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (kDebugMode) {
            debugPrint(
              '[FirebaseAuth] codeAutoRetrievalTimeout: verificationId=$verificationId',
            );
          }
          onCodeAutoRetrievalTimeout(verificationId);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebaseAuth] verifyPhoneNumber unhandled error: $e');
      }
      onVerificationFailed(_mapException(e));
    }
  }

  @override
  Future<AuthResult> verifyOtp({
    required String verificationId,
    required String otp,
    String? phoneNumber,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp.trim(),
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        if (kDebugMode) {
          debugPrint(
            '[FirebaseAuth] Verification succeeded. Firebase UID: ${user.uid}',
          );
        }
        return AuthResult.success(uid: user.uid);
      }
      return const AuthResult.failure(AuthFailureReason.unknown);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseAuth] verifyOtp FirebaseAuthException: code=${e.code}, message=${e.message}',
        );
      }
      return AuthResult.failure(_mapFirebaseException(e));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebaseAuth] verifyOtp error: $e');
      }
      return AuthResult.failure(_mapException(e));
    }
  }

  @override
  Future<AuthResult> requestOtp({required String phoneNumber}) {
    return _staffAuthService.requestOtp(phoneNumber: phoneNumber);
  }

  @override
  Future<AuthResult> resendOtp({required String phoneNumber}) {
    return _staffAuthService.resendOtp(phoneNumber: phoneNumber);
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebaseAuth] signOut error: $e');
      }
    }
    await _staffAuthService.logout();
  }

  /// Maps [FirebaseAuthException] codes into typed domain failure reasons.
  static AuthFailureReason _mapFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return AuthFailureReason.invalidPhoneNumber;
      case 'invalid-verification-code':
      case 'invalid-credential':
        return AuthFailureReason.invalidVerificationCode;
      case 'session-expired':
        return AuthFailureReason.sessionExpired;
      case 'too-many-requests':
      case 'quota-exceeded':
        return AuthFailureReason.tooManyRequests;
      case 'network-request-failed':
        return AuthFailureReason.networkError;
      default:
        return AuthFailureReason.unknown;
    }
  }

  /// Fallback mapper for general exceptions.
  static AuthFailureReason _mapException(Object e) {
    if (e is FirebaseAuthException) {
      return _mapFirebaseException(e);
    }
    return AuthFailureReason.unknown;
  }
}
