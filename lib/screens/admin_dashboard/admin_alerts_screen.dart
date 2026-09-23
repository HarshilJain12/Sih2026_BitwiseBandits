import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_health_alert.dart';
import '../../providers/admin_state_provider.dart';

/// Community health alerts inbox for the hospital admin.
/// Verify / reject village issues; jump to campaign creation.
class AdminAlertsScreen extends StatelessWidget {
  const AdminAlertsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final adminState = context.watch<AdminStateProvider>();

    final body = adminState.isLoading
        ? const Center(child: CircularProgressIndicator())
        : adminState.alerts.isEmpty
            ? const Center(
                child: Text('No community alerts.',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: adminState.alerts.length,
                itemBuilder: (context, index) =>
                    _alertCard(context, adminState, adminState.alerts[index]),
              );

    if (embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community Alerts'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _alertCard(BuildContext context, AdminStateProvider adminState,
      CommunityHealthAlert a) {
    final severityColor = switch (a.severity) {
      'high' => AppColors.error,
      'medium' => AppColors.warning,
      _ => AppColors.primary,
    };
    final isPending = a.status == 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(a.issueType,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(a.severity.toUpperCase(),
                      style: TextStyle(
                          color: severityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(a.description,
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              '${a.village}, ${a.ward} • by ${a.ashaName} • ${DateFormat('d MMM, h:mm a').format(a.createdAt)}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text('Status: ${a.status}',
                style: TextStyle(
                    color: isPending
                        ? AppColors.warning
                        : AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            if (isPending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => adminState.updateAlertStatus(
                          a.alertId, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 40),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => adminState.updateAlertStatus(
                          a.alertId, 'verified'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(64, 40),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Verify'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push(
                          RouteNames.adminCreateAwareness,
                          extra: a),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(64, 40),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Campaign'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
