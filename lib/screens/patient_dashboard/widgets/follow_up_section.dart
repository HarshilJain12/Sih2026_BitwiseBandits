import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Section rendering patient follow-up appointments / empty state.
class FollowUpSection extends StatelessWidget {
  const FollowUpSection({super.key, this.followUps});

  final List<Map<String, dynamic>>? followUps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasFollowUps = followUps != null && followUps!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.event_available_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              l10n.yourFollowUpsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (!hasFollowUps) ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.textHint,
                  size: 36,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  l10n.noUpcomingFollowUps,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ] else ...[
          ...followUps!.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: const Icon(Icons.medical_services_rounded, color: AppColors.primary),
                title: Text(item['doctor'] as String? ?? 'Doctor'),
                subtitle: Text(item['date'] as String? ?? ''),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
