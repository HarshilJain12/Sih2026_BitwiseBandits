import '../../core/constants/app_constants.dart';
import '../../models/user_role.dart';
import '../interfaces/auth_service.dart';

/// ⚠️  MOCK IMPLEMENTATION — NOT FOR PRODUCTION ⚠️
///
/// Simulates authentication responses with artificial delays.
/// - Password login: accepts any non-empty credentials.
/// - OTP: hardcoded to [AppConstants.kMockOtp] = '123456'.
///
/// Replace this class with a real API/Firebase implementation in a later chunk.
/// All UI code depends only on [AuthService] interface — no UI changes needed.
class MockAuthService implements AuthService {
  /// Simulated network delay
  static const _delay = Duration(milliseconds: 1200);
  String? _currentUserId;

  /// Simulated staff credentials with metadata for dashboard display.
  static const _staffCredentials = {
    'DOC001': {'name': 'Rajesh Sharma', 'specialization': 'General Medicine'},
    'DOC002': {'name': 'Priya Mehta', 'specialization': 'Pediatrics'},
    'DOC003': {'name': 'Amit Deshmukh', 'specialization': 'Orthopedics'},
    'DOCTOR1@GMAIL.COM': {'name': 'Dr. First Doctor', 'specialization': 'Neurology'},
  };

  @override
  String? get currentUserId => _currentUserId;

  @override
  Future<AuthResult> loginWithPassword({
    required UserRole role,
    required String identifier,
    required String password,
  }) async {
    await Future.delayed(_delay);
    // Mock: accept any non-empty credentials
    if (identifier.trim().isEmpty || password.trim().isEmpty) {
      return AuthResult.failure(AuthFailureReason.invalidCredentials);
    }
    _currentUserId = 'mock_staff_${role.name}_123';

    // For doctors, attach metadata for dashboard display
    if (role == UserRole.doctor) {
      final trimmedId = identifier.trim().toUpperCase();
      final creds = _staffCredentials[trimmedId] ?? {
        'name': identifier.trim(),
        'specialization': 'General Medicine',
      };
      return AuthResult.success(uid: _currentUserId, metadata: creds);
    }

    return AuthResult.success(uid: _currentUserId);
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
    await Future.delayed(_delay);
    if (phoneNumber.trim().isEmpty) {
      onVerificationFailed(AuthFailureReason.invalidPhoneNumber);
      return;
    }
    onCodeSent('mock_verification_id_123', 9999);
  }

  @override
  Future<AuthResult> requestOtp({required String phoneNumber}) async {
    await Future.delayed(_delay);
    return AuthResult.ok;
  }

  @override
  Future<AuthResult> verifyOtp({
    String? verificationId,
    required String otp,
    String? phoneNumber,
  }) async {
    await Future.delayed(_delay);
    if (otp.trim() == AppConstants.kMockOtp) {
      _currentUserId = 'mock_patient_user_123';
      return AuthResult.success(uid: _currentUserId);
    }
    return AuthResult.failure(AuthFailureReason.invalidVerificationCode);
  }

  @override
  Future<AuthResult> resendOtp({required String phoneNumber}) async {
    await Future.delayed(_delay);
    return AuthResult.ok;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUserId = null;
  }
}
