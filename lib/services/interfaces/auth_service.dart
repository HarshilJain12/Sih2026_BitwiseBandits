import '../../models/user_role.dart';

/// Typed domain failure reasons for authentication operations.
///
/// Keeps the authentication service decoupled from localization; the UI layer
/// resolves these enum values into user-facing localized messages.
enum AuthFailureReason {
  invalidPhoneNumber,
  invalidVerificationCode,
  sessionExpired,
  tooManyRequests,
  networkError,
  invalidCredentials,
  unknown,
}

/// Result object returned by authentication operations.
class AuthResult {
  const AuthResult({
    required this.success,
    this.failureReason,
    this.uid,
    this.errorKey,
  });

  const AuthResult.success({this.uid})
    : success = true,
      failureReason = null,
      errorKey = null;

  const AuthResult.failure(this.failureReason, {this.errorKey})
    : success = false,
      uid = null;

  final bool success;
  final AuthFailureReason? failureReason;
  final String? uid;

  /// Optional localization/error key for backward compatibility with earlier UI code.
  final String? errorKey;

  static const AuthResult ok = AuthResult.success();

  static AuthResult error(String key) {
    AuthFailureReason reason;
    switch (key) {
      case 'error_invalid_credentials':
        reason = AuthFailureReason.invalidCredentials;
        break;
      case 'error_invalid_otp':
        reason = AuthFailureReason.invalidVerificationCode;
        break;
      default:
        reason = AuthFailureReason.unknown;
    }
    return AuthResult.failure(reason, errorKey: key);
  }
}

/// Abstract interface for authentication operations.
abstract class AuthService {
  /// Login using username + password (ASHA, Doctor, Hospital Admin).
  Future<AuthResult> loginWithPassword({
    required UserRole role,
    required String identifier,
    required String password,
  });

  /// Initiates asynchronous phone verification lifecycle.
  ///
  /// Callbacks cleanly convey the verification lifecycle without forcing
  /// asynchronous events into a single synthetic return value:
  /// - [onCodeSent]: Verification code dispatched; provides verificationId and optional resendToken.
  /// - [onVerificationCompleted]: Instant/auto-retrieval completed; provides authenticated Firebase UID.
  /// - [onVerificationFailed]: Failed with a typed [AuthFailureReason].
  /// - [onCodeAutoRetrievalTimeout]: Auto-retrieval timeout elapsed on device; manual entry continues.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    int? resendToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String uid) onVerificationCompleted,
    required void Function(AuthFailureReason reason) onVerificationFailed,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
  });

  /// Verifies manual OTP code against verificationId.
  Future<AuthResult> verifyOtp({
    required String verificationId,
    required String otp,
    String? phoneNumber,
  });

  /// Initiates OTP-based login (legacy convenience / mock fallback).
  Future<AuthResult> requestOtp({required String phoneNumber});

  /// Resends OTP to the given phone number (legacy convenience / mock fallback).
  Future<AuthResult> resendOtp({required String phoneNumber});

  /// Signs the current user out.
  Future<void> logout();

  /// Current authenticated user ID (e.g. Firebase UID), if logged in.
  String? get currentUserId;
}
