import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/follow_up.dart';
import '../../../providers/asha_state_provider.dart';

class AshaFollowUpsScreen extends StatefulWidget {
  const AshaFollowUpsScreen({super.key});

  @override
  State<AshaFollowUpsScreen> createState() => _AshaFollowUpsScreenState();
}

class _AshaFollowUpsScreenState extends State<AshaFollowUpsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<FollowUp> _followUps = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFollowUps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowUps() async {
    setState(() => _isLoading = true);
    final ashaProvider = context.read<AshaStateProvider>();
    final worker = ashaProvider.currentWorker;
    try {
      final followUps = await ashaProvider.dataService.getFollowUpsByAsha(worker.ashaId);
      if (mounted) {
        setState(() {
          _followUps = followUps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markComplete(FollowUp followUp) async {
    final ashaProvider = context.read<AshaStateProvider>();
    try {
      await ashaProvider.dataService.completeFollowUp(followUp.followUpId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow-up marked as completed!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadFollowUps();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _followUps.where((f) => f.status == 'pending').toList();
    final completed = _followUps.where((f) => f.status == 'completed').toList();

    // Sort pending by scheduled date
    pending.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    completed.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Follow-ups',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Completed (${completed.length})'),
          ],
          labelColor: AppColors.warning,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.warning,
        ),
        actions: [
          IconButton(
            onPressed: _loadFollowUps,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFollowUpList(pending, isPending: true),
                _buildFollowUpList(completed, isPending: false),
              ],
            ),
    );
  }

  Widget _buildFollowUpList(List<FollowUp> followUps, {required bool isPending}) {
    if (followUps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.schedule_rounded : Icons.check_circle_rounded,
              size: 60,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending follow-ups.' : 'No completed follow-ups yet.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            if (isPending) ...[
              const SizedBox(height: 8),
              const Text(
                'Great work! All caught up.',
                style: TextStyle(color: AppColors.textHint, fontSize: 13),
              ),
            ]
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowUps,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        itemCount: followUps.length,
        itemBuilder: (context, index) {
          final followUp = followUps[index];
          return _buildFollowUpCard(followUp, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildFollowUpCard(FollowUp followUp, {required bool isPending}) {
    final now = DateTime.now();
    final isOverdue = isPending && followUp.scheduledDate.isBefore(now);
    final isDueToday = isPending &&
        followUp.scheduledDate.year == now.year &&
        followUp.scheduledDate.month == now.month &&
        followUp.scheduledDate.day == now.day;

    Color borderColor = AppColors.border;
    Color typeColor = AppColors.warning;
    if (isOverdue) {
      borderColor = AppColors.error;
      typeColor = AppColors.error;
    } else if (isDueToday) {
      borderColor = AppColors.warning;
    }

    IconData typeIcon;
    switch (followUp.type) {
      case 'pregnancy':
        typeIcon = Icons.pregnant_woman_rounded;
        typeColor = const Color(0xFFE91E63);
        break;
      case 'vaccination':
        typeIcon = Icons.vaccines_rounded;
        typeColor = AppColors.primary;
        break;
      case 'hypertension':
        typeIcon = Icons.favorite_rounded;
        typeColor = AppColors.error;
        break;
      case 'general':
        typeIcon = Icons.health_and_safety_rounded;
        break;
      default:
        typeIcon = Icons.schedule_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        followUp.type.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(followUp.scheduledDate),
                        style: TextStyle(
                          color: isOverdue ? AppColors.error : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  )
                else if (isDueToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  )
                else if (!isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              followUp.description,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            if (isPending) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markComplete(followUp),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
