import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../widgets/inputs/app_text_field.dart';
import 'patient_otp_screen.dart';

/// Patient Login Screen — Phone number entry for Firebase Phone Authentication.
class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _resolveValidationError(AppLocalizations l10n, String? key) {
    if (key == null) return null;
    switch (key) {
      case 'validation_required':
        return l10n.validationRequired;
      case 'validation_phone':
        return l10n.validationPhone;
      default:
        return l10n.errorGeneric;
    }
  }

  String _resolveAuthError(AppLocalizations l10n, AuthFailureReason? reason) {
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

  Future<void> _onContinue() async {
    if (_isLoading) return;

    final l10n = AppLocalizations.of(context)!;
    final phoneVal = Validators.phoneNumber(_phoneController.text);
    if (phoneVal != null) {
      setState(() => _phoneError = _resolveValidationError(l10n, phoneVal));
      return;
    }

    final normalizedPhone = Validators.normalizePhoneNumber(
      _phoneController.text,
    );

    setState(() {
      _phoneError = null;
      _errorMessage = null;
      _isLoading = true;
    });

    final authService = context.read<AuthService>();
    await authService.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        context.push(
          RouteNames.patientOtp,
          extra: PatientOtpArgs(
            phoneNumber: normalizedPhone,
            verificationId: verificationId,
            resendToken: resendToken,
          ),
        );
      },
      onVerificationCompleted: (uid) async {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final appState = context.read<AppStateProvider>();
        appState.selectRole(UserRole.patient);

        final authUser = context.read<AuthService>().currentUserId;
        final accountService = context.read<AccountService>();
        final patientService = context.read<PatientService>();
        final effectiveUid = uid.isNotEmpty ? uid : (authUser ?? '');

        debugPrint('════════════════ AUTO-AUTH SUCCESS & IDENTITY TRACE ════════════════');
        debugPrint('1. AUTH SUCCESS: true (currentUser != null: ${effectiveUid.isNotEmpty})');
        debugPrint('2. CURRENT USER UID: $effectiveUid');
        debugPrint('3. ACCOUNT LOOKUP PATH: /accounts/$effectiveUid');

        try {
          final account = await accountService.ensureAccountExists(
            uid: effectiveUid,
            phoneNumber: normalizedPhone,
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
      },
      onVerificationFailed: (reason) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = _resolveAuthError(l10n, reason);
        });
      },
      onCodeAutoRetrievalTimeout: (_) {
        // Normal timeout on Android auto-retrieval; user will enter OTP manually
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacingLg),

                // ── Role Badge ───────────────────────────────────────────
                _RoleBadge(
                  icon: Icons.person_rounded,
                  label: l10n.rolePatient,
                  color: AppColors.rolePatient,
                  lightColor: AppColors.rolePatientLight,
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // ── Heading ──────────────────────────────────────────────
                Text(
                  l10n.login,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  l10n.mobileNumberHint,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // ── Phone Input ──────────────────────────────────────────
                AppTextField(
                  controller: _phoneController,
                  label: l10n.mobileNumber,
                  hint: l10n.mobileNumberHint,
                  errorText: _phoneError,
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[\d\+\s\-\(\)]'),
                    ),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  onChanged: (_) {
                    if (_phoneError != null) {
                      setState(() => _phoneError = null);
                    }
                  },
                  onFieldSubmitted: (_) => _onContinue(),
                ),

                const SizedBox(height: AppTheme.spacingSm),

                // ── User Consent / Informational Notice ───────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Expanded(
                      child: Text(
                        l10n.phoneAuthNotice,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── Error Banner ─────────────────────────────────────────
                if (_errorMessage != null) ...[
                  ErrorMessage(message: _errorMessage!),
                  const SizedBox(height: AppTheme.spacingMd),
                ],

                // ── CTA Button ───────────────────────────────────────────
                PrimaryButton(
                  label: l10n.getOtp,
                  onPressed: _isLoading ? null : _onContinue,
                  isLoading: _isLoading,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact role indicator badge shown at the top of login screens.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.lightColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color lightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
