import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/patient.dart';
import '../../../widgets/buttons/primary_button.dart';

/// Screen displayed upon successful location confirmation.
class PatientLocationSuccessScreen extends StatelessWidget {
  const PatientLocationSuccessScreen({super.key, required this.patient});

  final Patient patient;

  void _copyPatientId(BuildContext context, String id, String message) {
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = patient.location;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingLg),

              // ── Success Icon ──────────────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Title & Subtitle ──────────────────────────────────────
              Text(
                l10n.locationSaved,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                l10n.locationSavedDesc,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ── Patient ID Card ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.yourPatientId,
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      patient.patientId,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextButton.icon(
                      onPressed: () => _copyPatientId(
                        context,
                        patient.patientId,
                        l10n.patientIdCopied,
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(l10n.copyPatientId),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // ── Location Summary Card ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          location?.isGps == true
                              ? Icons.my_location_rounded
                              : Icons.home_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          l10n.selectedLocation,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: location?.isGps == true
                                ? AppColors.primaryLight
                                : AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: Text(
                            location?.source.toUpperCase() ?? 'MANUAL',
                            style: TextStyle(
                              color: location?.isGps == true
                                  ? AppColors.primary
                                  : AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (location?.isGps == true) ...[
                      _LocationRow(
                        label: 'Coordinates',
                        value:
                            '${location?.latitude?.toStringAsFixed(5)}, ${location?.longitude?.toStringAsFixed(5)}',
                      ),
                    ] else ...[
                      if (location?.village != null)
                        _LocationRow(
                          label: l10n.village,
                          value: location!.village!,
                        ),
                      if (location?.district != null)
                        _LocationRow(
                          label: l10n.district,
                          value: location!.district!,
                        ),
                      if (location?.state != null)
                        _LocationRow(
                          label: l10n.state,
                          value: location!.state!,
                        ),
                      if (location?.pincode != null)
                        _LocationRow(
                          label: l10n.pincode,
                          value: location!.pincode!,
                        ),
                      if (location?.address != null)
                        _LocationRow(
                          label: l10n.fullAddress,
                          value: location!.address!,
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ── Continue Button ──────────────────────────────────────
              PrimaryButton(
                label: l10n.continueButton,
                onPressed: () {
                  context.go(
                    RouteNames.medicalRecordsPlaceholder,
                    extra: patient,
                  );
                },
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
