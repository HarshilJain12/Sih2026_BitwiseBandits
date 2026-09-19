import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_role.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/firestore/account_service.dart';
import '../../../services/firestore/patient_service.dart';
import '../../../services/interfaces/auth_service.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/inputs/otp_input.dart';

/// Arguments bundle passed to [PatientOtpScreen].
class PatientOtpArgs {
  const PatientOtpArgs({
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
}

/// Patient OTP Verification Screen using Firebase Phone Authentication.
class PatientOtpScreen extends StatefulWidget {
  const PatientOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  @override
  State<PatientOtpScreen> createState() => _PatientOtpScreenState();
}

class _PatientOtpScreenState extends State<PatientOtpScreen> {
  late String _verificationId;
  int? _resendToken;
  String _otp = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _otpError;

  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendCountdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _maskPhoneNumber(String phone) {
    final clean = phone.trim();
    if (clean.length < 5) return clean;
    final last4 = clean.substring(clean.length - 4);
    final prefixMatch = RegExp(r'^(\+\d{1,3})').firstMatch(clean);
    final prefix = prefixMatch != null ? prefixMatch.group(1)! : '+91';
    return '$prefix ******$last4';
  }

  String _resolveError(AppLocalizations l10n, AuthFailureReason? reason) {
    switch (reason) {
      case AuthFailureReason.invalidPhoneNumber:
        return l10n.errorInvalidPhone;
      case AuthFailureReason.invalidVerificationCode:
        return l10n.errorInvalidOtp;
      case AuthFailureReason.sessionExpired:
        return l10n.errorSessionExpired;
      case AuthFailureReason.tooManyRequests:
        return l10n.errorTooManyRequests;
      case AuthFailureReason.networkError:
        return l10n.errorNetwork;
      case AuthFailureReason.invalidCredentials:
        return l10n.errorInvalidCredentials;
      case AuthFailureReason.unknown:
      case null:
        return l10n.errorGeneric;
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isLoading) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final authService = context.read<AuthService>();
    await authService.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      resendToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken ?? _resendToken;
          _isLoading = false;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OTP sent to ${_maskPhoneNumber(widget.phoneNumber)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      },
      onVerificationCompleted: (uid) {
        if (!mounted) return;
        _navigateAfterAuth(uid, widget.phoneNumber);
      },
      onVerificationFailed: (reason) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = _resolveError(l10n, reason);
        });
      },
      onCodeAutoRetrievalTimeout: (timeoutVerificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = timeoutVerificationId;
        });
      },
    );
  }

  Future<void> _onVerify() async {
    final l10n = AppLocalizations.of(context)!;
    final validation = Validators.otp(_otp);
    if (validation != null) {
      setState(() => _otpError = l10n.validationOtp);
      return;
    }

    setState(() {
      _otpError = null;
      _errorMessage = null;
      _isLoading = true;
    });

    final authService = context.read<AuthService>();
    final result = await authService.verifyOtp(
      verificationId: _verificationId,
      otp: _otp,
      phoneNumber: widget.phoneNumber,
    );

    if (!mounted) return;

    if (result.success) {
      await _navigateAfterAuth(result.uid ?? '', widget.phoneNumber);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = _resolveError(l10n, result.failureReason);
      });
    }
  }

  Future<void> _navigateAfterAuth(String uid, String phoneNumber) async {
    final appState = context.read<AppStateProvider>();
    appState.selectRole(UserRole.patient);

    final authUser = context.read<AuthService>().currentUserId;
    final accountService = context.read<AccountService>();
    final patientService = context.read<PatientService>();
    final effectiveUid = uid.isNotEmpty ? uid : (authUser ?? '');

    debugPrint('════════════════ AUTH SUCCESS & IDENTITY TRACE ════════════════');
    debugPrint('1. AUTH SUCCESS: true (currentUser != null: ${effectiveUid.isNotEmpty})');
    debugPrint('2. CURRENT USER UID: $effectiveUid');
    debugPrint('3. ACCOUNT LOOKUP PATH: /accounts/$effectiveUid');

    try {
      final account = await accountService.ensureAccountExists(
        uid: effectiveUid,
        phoneNumber: phoneNumber,
      );
      debugPrint('4. ACCOUNT EXISTS: true (${account.firebaseUid})');
    } catch (e) {
      debugPrint('4. ACCOUNT LOOKUP/ENSURE ERROR: $e');
    }

    debugPrint('5. PATIENT LINKS LOOKUP PATH: /accounts/$effectiveUid/patientLinks');

    try {
      final linkedPatients = await patientService.getLinkedPatients(
        uid: effectiveUid,
      );
      debugPrint('6. PATIENT LINKS FOUND: ${linkedPatients.length}');

      if (!mounted) return;

      if (linkedPatients.isNotEmpty) {
        final patient = linkedPatients.first;
        debugPrint('7. PATIENT ID SELECTED: ${patient.patientId}');
        debugPrint('8. PATIENT PROFILE EXISTS: true (Name: ${patient.name})');
        debugPrint(
          '9. FINAL NAVIGATION: EXISTING_PATIENT_DASHBOARD (${RouteNames.patientDashboard})',
        );
        debugPrint('══════════════════════════════════════════════════════════════');

        appState.setCurrentPatientId(patient.patientId);
        context.go(
          RouteNames.patientDashboard,
          extra: patient,
        );
      } else {
        debugPrint('7. PATIENT ID SELECTED: None');
        debugPrint('8. PATIENT PROFILE EXISTS: false');
        debugPrint(
          '9. FINAL NAVIGATION: NEW_PATIENT_REGISTRATION (${RouteNames.patientRegistration})',
        );
        debugPrint('══════════════════════════════════════════════════════════════');

        context.go(RouteNames.patientRegistration);
      }
    } catch (e) {
      debugPrint('ERROR DURING PATIENT LOOKUP: $e');
      debugPrint(
        '9. FINAL NAVIGATION: ERROR_FALLBACK (${RouteNames.patientRegistration})',
      );
      debugPrint('══════════════════════════════════════════════════════════════');
      if (!mounted) return;
      context.go(RouteNames.patientRegistration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maskedPhone = _maskPhoneNumber(widget.phoneNumber);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingLg),

              // ── Heading ──────────────────────────────────────────────
              Text(
                l10n.otpTitle,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'OTP sent to $maskedPhone',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ── OTP Input ────────────────────────────────────────────
              OtpInput(
                onChanged: (val) {
                  _otp = val;
                  if (_otpError != null) setState(() => _otpError = null);
                },
                onCompleted: (val) {
                  _otp = val;
                  _onVerify();
                },
                errorText: _otpError,
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Resend OTP Row ───────────────────────────────────────
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        l10n.resendIn(_resendCountdown),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      )
                    : TextButton(
                        onPressed: _isLoading ? null : _resendOtp,
                        child: Text(
                          l10n.resendOtp,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // ── Error Banner ─────────────────────────────────────────
              if (_errorMessage != null) ...[
                ErrorMessage(message: _errorMessage!),
                const SizedBox(height: AppTheme.spacingMd),
              ],

              // ── CTA Button ───────────────────────────────────────────
              PrimaryButton(
                label: l10n.verifyButton,
                onPressed: _onVerify,
                isLoading: _isLoading,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
