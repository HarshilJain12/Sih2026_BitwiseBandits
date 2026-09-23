import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/community_health_alert.dart';
import '../../../services/firestore/asha_data_service.dart';
import '../../../widgets/buttons/primary_button.dart';

class AdminCommunityAlertsScreen extends StatefulWidget {
  const AdminCommunityAlertsScreen({super.key});

  @override
  State<AdminCommunityAlertsScreen> createState() => _AdminCommunityAlertsScreenState();
}

class _AdminCommunityAlertsScreenState extends State<AdminCommunityAlertsScreen> {
  final AshaDataService _dataService = AshaDataService();
  bool _isLoading = true;
  List<CommunityHealthAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _dataService.getAllAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String alertId, String newStatus) async {
    await _dataService.updateAlertStatus(alertId, newStatus);
    _loadAlerts();
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      case 'low': return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community Health Alerts'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? const Center(child: Text('No community alerts found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    final isPending = alert.status == 'pending';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        side: BorderSide(color: AppColors.border),
                      ),
                      elevation: 0,
                      color: AppColors.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getSeverityColor(alert.severity).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    alert.severity.toUpperCase(),
                                    style: TextStyle(
                                      color: _getSeverityColor(alert.severity),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM, HH:mm').format(alert.createdAt),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alert.issueType,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.description,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text('${alert.village}, ${alert.ward}', style: const TextStyle(fontSize: 13)),
                                const Spacer(),
                                const Icon(Icons.person_outline, size: 16, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(alert.ashaName, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            
                            const Divider(height: 24),
                            
                            if (isPending) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _updateStatus(alert.alertId, 'rejected'),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateStatus(alert.alertId, 'verified'),
                                      child: const Text('Verify'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (alert.status == 'verified') ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.successContainer,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    ),
                                    child: const Text('Verified', style: TextStyle(color: AppColors.success)),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      context.push(RouteNames.adminCreateAwareness, extra: alert);
                                    },
                                    icon: const Icon(Icons.campaign_outlined),
                                    label: const Text('Create Awareness Campaign'),
                                  )
                                ],
                              ),
                            ] else ...[
                               Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: Text(alert.status.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary)),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
