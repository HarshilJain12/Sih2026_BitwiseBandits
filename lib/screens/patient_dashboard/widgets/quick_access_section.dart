import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/patient.dart';

/// Grid section providing quick access to patient health modules.
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key, required this.patient});

  final Patient patient;

  void _showPlaceholder(BuildContext context, String title) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title - ${l10n.comingSoon}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = [
      {
        'title': l10n.medicalRecordsTitle,
        'icon': Icons.folder_shared_rounded,
        'color': AppColors.primary,
        'bgColor': AppColors.primaryContainer,
        'onTap': () => context.go(
              RouteNames.medicalRecordsPlaceholder,
              extra: patient,
            ),
      },
      {
        'title': l10n.appointmentsTitle,
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF1565C0),
        'bgColor': const Color(0xFFE3F0FD),
        'onTap': () => _showPlaceholder(context, l10n.appointmentsTitle),
      },
      {
        'title': l10n.prescriptionsTitle,
        'icon': Icons.medication_rounded,
        'color': const Color(0xFF2E7D32),
        'bgColor': const Color(0xFFE8F5E9),
        'onTap': () => _showPlaceholder(context, l10n.prescriptionsTitle),
      },
      {
        'title': l10n.referralsTitle,
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFF6A1B9A),
        'bgColor': const Color(0xFFF3E5F5),
        'onTap': () => _showPlaceholder(context, l10n.referralsTitle),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bolt_rounded,
              color: AppColors.secondary,
              size: 24,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              l10n.quickAccessTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppTheme.spacingMd,
            crossAxisSpacing: AppTheme.spacingMd,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final color = item['color'] as Color;
            final bgColor = item['bgColor'] as Color;

            return InkWell(
              onTap: item['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      item['title'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
