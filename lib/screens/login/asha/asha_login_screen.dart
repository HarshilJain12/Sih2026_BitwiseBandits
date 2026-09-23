import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/asha_worker.dart';
import '../../../models/user_role.dart';
import '../../../providers/app_state_provider.dart';
import '../../../providers/asha_state_provider.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../../widgets/inputs/password_field.dart';

/// ASHA Worker Login Screen.
class AshaLoginScreen extends StatefulWidget {
  const AshaLoginScreen({super.key});

  @override
  State<AshaLoginScreen> createState() => _AshaLoginScreenState();
}

class _AshaLoginScreenState extends State<AshaLoginScreen> {
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

    final ashaProvider = context.read<AshaStateProvider>();
    final worker = await ashaProvider.login(
      _idController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (worker != null) {
      context.read<AppStateProvider>().selectRole(UserRole.asha);
      context.go(RouteNames.ashaDashboard);
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
                    color: AppColors.roleAshaLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: AppColors.roleAsha.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.volunteer_activism_rounded,
                        color: AppColors.roleAsha,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        l10n.roleAsha,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.roleAsha,
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
                l10n.roleAshaDesc,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ── ASHA ID Input ────────────────────────────────────────
              AppTextField(
                controller: _idController,
                label: l10n.ashaId,
                hint: l10n.ashaIdHint,
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

              const SizedBox(height: AppTheme.spacingMd),

              // ── Quick Demo Mode Button ──────────────────────────────
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final ashaProvider =
                            context.read<AshaStateProvider>();
                        final appState =
                            context.read<AppStateProvider>();
                        setState(() => _isLoading = true);
                        try {
                          ashaProvider.setWorker(AshaWorker.demoWorker);
                          appState.selectRole(UserRole.asha);
                          final seeded =
                              await ashaProvider.seedDemoData();
                          if (!mounted) return;
                          setState(() => _isLoading = false);
                          if (!seeded) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Demo login OK, but sample data could not sync: '
                                  '${ashaProvider.lastError ?? 'unknown error'}. '
                                  'Check internet / Firestore rules.',
                                ),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 6),
                              ),
                            );
                          }
                          context.go(RouteNames.ashaDashboard);
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Demo mode failed: $e'),
                              backgroundColor: AppColors.error,
                              duration: const Duration(seconds: 6),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.flash_on_rounded, color: AppColors.roleAsha),
                label: const Text(
                  '⚡ One-Click Demo Mode (ASHA001)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.roleAsha,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.roleAsha, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),
              
              TextButton(
                onPressed: () => context.push(RouteNames.ashaRegister),
                child: const Text('New ASHA Worker? Register Here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
