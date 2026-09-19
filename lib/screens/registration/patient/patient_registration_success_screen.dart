import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/patient.dart';
import '../../../providers/app_state_provider.dart';
import '../../../widgets/buttons/primary_button.dart';

/// Screen displayed immediately after successful patient registration.
///
/// Prominently displays the newly created unique Patient ID and provides:
/// - One-tap clipboard copy
/// - Summary of registered details
/// - Continue button to proceed to the authenticated patient landing screen
class PatientRegistrationSuccessScreen extends StatelessWidget {
  const PatientRegistrationSuccessScreen({super.key, required this.patient});

  final Patient patient;

  void _copyPatientId(BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: patient.patientId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppTheme.spacingSm),
            Text(l10n.patientIdCopied),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingXl),

              // ── Success Icon ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // ── Title ──────────────────────────────────────────────────
              Text(
                l10n.patientProfileCreated,
                style: Theme.of(context).textTheme.displayMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Patient ID Showcase Card ───────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    children: [
                      Text(
                        l10n.yourPatientId,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLg,
                          vertical: AppTheme.spacingMd,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          patient.patientId,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      OutlinedButton.icon(
                        onPressed: () => _copyPatientId(context, l10n),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text(l10n.copyPatientId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // ── Details Summary Card ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryRow(
                            label: l10n.fullName,
                            value: patient.name,
                            icon: Icons.person_rounded,
                          ),
                          if (patient.phoneNumber.isNotEmpty) ...[
                            const Divider(height: AppTheme.spacingLg),
                            _SummaryRow(
                              label: l10n.mobileNumber,
                              value: patient.phoneNumber,
                              icon: Icons.phone_android_rounded,
                            ),
                          ],
                          if (patient.age != null) ...[
                            const Divider(height: AppTheme.spacingLg),
                            _SummaryRow(
                              label: l10n.age,
                              value: '${patient.age} ${l10n.years}',
                              icon: Icons.cake_outlined,
                            ),
                          ],
                          if (patient.weightKg != null) ...[
                            const Divider(height: AppTheme.spacingLg),
                            _SummaryRow(
                              label: l10n.weight,
                              value: '${patient.weightKg} ${l10n.kg}',
                              icon: Icons.monitor_weight_outlined,
                            ),
                          ],
                          if (patient.heightCm != null) ...[
                            const Divider(height: AppTheme.spacingLg),
                            _SummaryRow(
                              label: l10n.height,
                              value: '${patient.heightCm} ${l10n.cm}',
                              icon: Icons.height_rounded,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Continue CTA Button ────────────────────────────────────
              PrimaryButton(
                label: l10n.continueButton,
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  context.read<AppStateProvider>().setCurrentPatientId(patient.patientId);
                  context.go(
                    RouteNames.patientDashboard,
                    extra: patient,
                  );
                },
              ),

              const SizedBox(height: AppTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
