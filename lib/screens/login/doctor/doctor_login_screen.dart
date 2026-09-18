import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_role.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/interfaces/auth_service.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../../widgets/inputs/password_field.dart';

/// Doctor Login Screen.
class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _idError;
  String? _passwordError;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _resolveError(AppLocalizations l10n, String? key) {
    if (key == null) return null;
    switch (key) {
      case 'validation_required':
        return l10n.validationRequired;
      case 'validation_min_length':
        return l10n.validationMinLength;
      default:
        return l10n.errorGeneric;
    }
  }

  Future<void> _onLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final idVal = Validators.required(_idController.text);
    final pwVal = Validators.password(_passwordController.text);

    setState(() {
      _idError = _resolveError(l10n, idVal);
      _passwordError = _resolveError(l10n, pwVal);
    });

    if (idVal != null || pwVal != null) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final authService = context.read<AuthService>();
    final result = await authService.loginWithPassword(
      role: UserRole.doctor,
      identifier: _idController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      context.read<AppStateProvider>().selectRole(UserRole.doctor);

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 48,
          ),
          title: Text(l10n.login),
          content: Text(
            '${l10n.roleDoctor} — ${_idController.text.trim()}\n\nAuthentication successful! Doctor dashboard will be available in later chunks.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(l10n.back),
            ),
          ],
        ),
      );
    } else {
      setState(() => _errorMessage = l10n.errorInvalidCredentials);
    }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingLg),

              // ── Role Badge ───────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roleDoctorLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: AppColors.roleDoctor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.medical_services_rounded,
                        color: AppColors.roleDoctor,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        l10n.roleDoctor,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.roleDoctor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ── Heading ──────────────────────────────────────────────
              Text(
                l10n.login,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                l10n.roleDoctorDesc,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ── Doctor ID Input ──────────────────────────────────────
              AppTextField(
                controller: _idController,
                label: l10n.doctorId,
                hint: l10n.doctorIdHint,
                errorText: _idError,
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_idError != null) setState(() => _idError = null);
                },
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Password Input ───────────────────────────────────────
              PasswordField(
                controller: _passwordController,
                label: l10n.password,
                hint: l10n.passwordHint,
                errorText: _passwordError,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onLogin(),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Error Banner ─────────────────────────────────────────
              if (_errorMessage != null) ...[
                ErrorMessage(message: _errorMessage!),
                const SizedBox(height: AppTheme.spacingMd),
              ],

              // ── CTA Button ───────────────────────────────────────────
              PrimaryButton(
                label: l10n.loginButton,
                onPressed: _onLogin,
                isLoading: _isLoading,
                icon: Icons.login_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
