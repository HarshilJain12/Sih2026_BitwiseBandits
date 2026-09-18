import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medical_record.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';

/// Screen displayed after a medical record is successfully uploaded and stored.
class MedicalRecordSuccessScreen extends StatelessWidget {
  const MedicalRecordSuccessScreen({
    super.key,
    required this.patientId,
    required this.record,
    this.isRegistration = false,
  });

  final String patientId;
  final MedicalRecord record;
  final bool isRegistration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ── Success Badge ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 56,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Title & Subtitle ────────────────────────────────────────
              Text(
                l10n.uploadSuccessTitle,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                l10n.uploadSuccessDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Uploaded Record Summary Card ────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.originalFileName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${record.recordId}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Action Buttons ──────────────────────────────────────────
              if (isRegistration) ...[
                PrimaryButton(
                  label: l10n.continueButton,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    context.go(RouteNames.patientAuthSuccess);
                  },
                ),
                const SizedBox(height: AppTheme.spacingSm),
                SecondaryButton(
                  label: l10n.addAnotherRecord,
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () {
                    context.push(
                      RouteNames.addMedicalRecordCategory,
                      extra: {
                        'patientId': patientId,
                        'isRegistration': true,
                      },
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextButton(
                  onPressed: () {
                    context.go(
                      RouteNames.patientMedicalRecords,
                      extra: {
                        'patientId': patientId,
                        'isRegistration': true,
                      },
                    );
                  },
                  child: Text(
                    l10n.viewMedicalRecords,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ] else ...[
                PrimaryButton(
                  label: l10n.viewMedicalRecords,
                  icon: Icons.folder_shared_rounded,
                  onPressed: () {
                    context.go(
                      RouteNames.patientMedicalRecords,
                      extra: {
                        'patientId': patientId,
                        'isRegistration': false,
                      },
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spacingSm),
                SecondaryButton(
                  label: l10n.addAnotherRecord,
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () {
                    context.push(
                      RouteNames.addMedicalRecordCategory,
                      extra: {
                        'patientId': patientId,
                        'isRegistration': false,
                      },
                    );
                  },
                ),
              ],

              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}
