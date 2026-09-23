import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/asha_state_provider.dart';

/// ASHA Worker Dashboard — mobile-first, large touch targets.
class AshaDashboardScreen extends StatefulWidget {
  const AshaDashboardScreen({super.key});

  @override
  State<AshaDashboardScreen> createState() => _AshaDashboardScreenState();
}

class _AshaDashboardScreenState extends State<AshaDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AshaStateProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ashaState = context.watch<AshaStateProvider>();
    final worker = ashaState.currentWorker;
    final stats = ashaState.dashboardStats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ashaState.loadDashboardStats(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.roleAsha,
                      child: Text(
                        worker?.name.isNotEmpty == true
                            ? worker!.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            worker?.name ?? 'ASHA Worker',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push(RouteNames.ashaProfile),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Village/Ward badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.roleAshaLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16,
                          color: AppColors.roleAsha),
                      const SizedBox(width: 4),
                      Text(
                        '${worker?.village ?? 'Village'} • ${worker?.wardId ?? 'Ward'}',
                        style: const TextStyle(
                          color: AppColors.roleAsha,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Demo Dataset Quick Loader ────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.dataset_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Demo Test Dataset',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Pre-load sample families, infants & maternal cases',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: ashaState.isLoading
                            ? null
                            : () async {
                                final seeded =
                                    await ashaState.seedDemoData();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        seeded
                                            ? 'Demo dataset loaded! Sample families and health records ready.'
                                            : 'Could not load demo data: ${ashaState.lastError ?? 'unknown error'}. Check internet / Firestore rules.',
                                      ),
                                      backgroundColor: seeded
                                          ? AppColors.success
                                          : AppColors.error,
                                      duration:
                                          const Duration(seconds: 6),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.flash_on, size: 16),
                        label: const Text('Load Demo'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.primaryDark,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Stats Grid ──────────────────────────────
                if (ashaState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildStatsGrid(stats),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Quick Actions ────────────────────────────
                Text('Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildActionButton(
                  icon: Icons.home_work_rounded,
                  label: 'Start Home Visit',
                  subtitle: 'Conduct home-to-home visit',
                  color: AppColors.roleAsha,
                  onTap: () => context.push(RouteNames.ashaHomeVisit),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildActionButton(
                  icon: Icons.family_restroom_rounded,
                  label: 'Register Family',
                  subtitle: 'Add a new family to your ward',
                  color: AppColors.rolePatient,
                  onTap: () => context.push(RouteNames.ashaFamilyRegistration),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildActionButton(
                  icon: Icons.vaccines_rounded,
                  label: 'Vaccination',
                  subtitle: 'Manage vaccination schedules',
                  color: AppColors.primary,
                  onTap: () => context.push(RouteNames.ashaVaccination),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildActionButton(
                  icon: Icons.pregnant_woman_rounded,
                  label: 'Maternal Health',
                  subtitle: 'Track pregnant women',
                  color: const Color(0xFFE91E63),
                  onTap: () => context.push(RouteNames.ashaMaternal),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildActionButton(
                  icon: Icons.child_care_rounded,
                  label: 'Mother & Child Care',
                  subtitle: 'Newborn & infant tracking',
                  color: const Color(0xFFFF9800),
                  onTap: () => context.push(RouteNames.ashaInfantCare),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildActionButton(
                  icon: Icons.report_problem_rounded,
                  label: 'Report Village Issue',
                  subtitle: 'Report health concerns via voice/text',
                  color: AppColors.error,
                  onTap: () => context.push(RouteNames.ashaReportIssue),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildActionButton(
                  icon: Icons.campaign_rounded,
                  label: 'Awareness',
                  subtitle: 'Health awareness campaigns',
                  color: const Color(0xFF9C27B0),
                  onTap: () => context.push(RouteNames.ashaAwareness),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildActionButton(
                  icon: Icons.schedule_rounded,
                  label: 'Follow-ups',
                  subtitle: 'View and manage follow-ups',
                  color: AppColors.warning,
                  onTap: () => context.push(RouteNames.ashaFollowUps),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                _buildActionButton(
                  icon: Icons.history_rounded,
                  label: 'Visit History',
                  subtitle: 'Previous home visit records',
                  color: AppColors.textSecondary,
                  onTap: () => context.push(RouteNames.ashaVisitHistory),
                ),

                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard("Today's Visits", stats['todayVisits'] ?? 0,
            Icons.directions_walk_rounded, AppColors.roleAsha),
        _buildStatCard('Families', stats['totalFamilies'] ?? 0,
            Icons.family_restroom_rounded, AppColors.rolePatient),
        _buildStatCard('Pregnant Women', stats['pregnantWomen'] ?? 0,
            Icons.pregnant_woman_rounded, const Color(0xFFE91E63)),
        _buildStatCard('Infants', stats['infants'] ?? 0,
            Icons.child_care_rounded, const Color(0xFFFF9800)),
        _buildStatCard('Vaccination Due', stats['vaccinationsDue'] ?? 0,
            Icons.vaccines_rounded, AppColors.primary),
        _buildStatCard('Follow-ups Due', stats['followUpsDue'] ?? 0,
            Icons.schedule_rounded, AppColors.warning),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Home', true, () {}),
              _navItem(Icons.family_restroom_rounded, 'Families', false,
                  () => context.push(RouteNames.ashaFamilyRegistration)),
              _navItem(Icons.vaccines_rounded, 'Vaccine', false,
                  () => context.push(RouteNames.ashaVaccination)),
              _navItem(Icons.report_rounded, 'Alerts', false,
                  () => context.push(RouteNames.ashaReportIssue)),
              _navItem(Icons.person_rounded, 'Profile', false,
                  () => context.push(RouteNames.ashaProfile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    final color = active ? AppColors.roleAsha : AppColors.textHint;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
