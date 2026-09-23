import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/awareness_campaign.dart';
import '../../../providers/asha_state_provider.dart';

/// ASHA Worker's view of Awareness Campaigns.
/// Shows all published campaigns and lets ASHA workers view their details.
/// Admin campaign creation is accessible via the Admin route.
class AshaAwarenessScreen extends StatefulWidget {
  const AshaAwarenessScreen({super.key});

  @override
  State<AshaAwarenessScreen> createState() => _AshaAwarenessScreenState();
}

class _AshaAwarenessScreenState extends State<AshaAwarenessScreen> {
  bool _isLoading = true;
  List<AwarenessCampaign> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);
    final ashaProvider = context.read<AshaStateProvider>();
    try {
      final campaigns = await ashaProvider.dataService.getPublishedCampaigns();
      if (mounted) {
        setState(() {
          _campaigns = campaigns;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health Awareness',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: _loadCampaigns,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          // Admin-only shortcut
          IconButton(
            onPressed: () => context.push(RouteNames.adminCommunityAlerts),
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: 'Manage Alerts (Admin)',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCampaigns,
              child: _campaigns.isEmpty
                  ? _buildEmptyState()
                  : _buildCampaignList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              const Icon(Icons.campaign_rounded,
                  size: 72, color: Color(0xFF9C27B0)),
              const SizedBox(height: 16),
              const Text(
                'No awareness campaigns published yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Campaigns published by Hospital Admin will appear here.',
                style: TextStyle(color: AppColors.textHint, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push(RouteNames.adminCommunityAlerts),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('View Community Alerts'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9C27B0),
                  side: const BorderSide(color: Color(0xFF9C27B0)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _campaigns.length,
      itemBuilder: (context, index) {
        final campaign = _campaigns[index];
        return _buildCampaignCard(campaign);
      },
    );
  }

  Widget _buildCampaignCard(AwarenessCampaign campaign) {
    const purple = Color(0xFF9C27B0);
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: Color(0xFFCE93D8), width: 1.5),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.campaign_rounded, color: purple, size: 24),
        ),
        title: Text(
          campaign.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd MMM yyyy').format(campaign.createdAt),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('PUBLISHED',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 9)),
              ),
            ],
          ),
        ),
        children: [
          // Description
          const Text('Description',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(campaign.description,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.5)),

          const SizedBox(height: 12),

          // Safety instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, size: 16, color: purple),
                    SizedBox(width: 6),
                    Text('Safety Instructions',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: purple,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(campaign.safetyInstructions,
                    style: const TextStyle(
                        color: AppColors.textPrimary, height: 1.4)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Target areas
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Villages: ${campaign.targetVillages.join(", ")}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(Icons.local_hospital_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'By: ${campaign.hospitalName}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),

          if (campaign.contactInfo != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Helpline: ${campaign.contactInfo}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
