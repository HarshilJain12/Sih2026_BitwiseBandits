import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_state_provider.dart';
import 'admin_alerts_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_opd_queue_screen.dart';
import 'admin_patients_screen.dart';

/// Hospital Admin dashboard shell with bottom-tab navigation.
///
/// Tabs: Home (stats + actions), OPD Queue, Patients, Doctors, Alerts.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStateProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = context.watch<AdminStateProvider>();

    final tabs = <Widget>[
      _AdminHomeTab(onGoTab: (i) => setState(() => _tab = i)),
      const AdminOpdQueueScreen(embedded: true),
      const AdminPatientsScreen(embedded: true),
      const AdminDoctorsScreen(embedded: true),
      const AdminAlertsScreen(embedded: true),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => adminState.loadAll(),
          child: tabs[_tab],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.roleAdmin,
        unselectedItemColor: AppColors.textHint,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded), label: 'OPD'),
          BottomNavigationBarItem(
              icon: Icon(Icons.personal_injury_rounded), label: 'Patients'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_rounded), label: 'Doctors'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
        ],
      ),
    );
  }
}

/// Home tab: greeting, demo loader, stats grid, quick actions, live snapshot.
class _AdminHomeTab extends StatelessWidget {
  const _AdminHomeTab({required this.onGoTab});

  final void Function(int tab) onGoTab;

  @override
  Widget build(BuildContext context) {
    final adminState = context.watch<AdminStateProvider>();
    final stats = adminState.overview;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // ── Header ──────────────────────────────────────────────
        Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.roleAdminLight,
              child: Text('A',
                  style: TextStyle(
                      color: AppColors.roleAdmin,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome,',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const Text('Hospital Admin',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text(
                    'Kondhwa PHC Health Center • ${DateFormat('EEE, d MMM').format(DateTime.now())}',
                    style: const TextStyle(
                        color: AppColors.roleAdmin,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            if (adminState.usedLocalDemo)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text('Demo data',
                    style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Demo Dataset Quick Loader ───────────────────────────
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.dataset_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Demo Hospital Dataset',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    Text('Load sample OPD queue, patients & doctors',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: adminState.isLoading
                    ? null
                    : () async {
                        final ok = await adminState.loadAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Demo hospital dataset loaded!'
                                  : 'Could not load data: ${adminState.lastError ?? 'unknown error'}'),
                              backgroundColor:
                                  ok ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.flash_on, size: 16),
                label: const Text('Load Demo'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.primaryDark,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingLg),

        // ── Stats Grid ──────────────────────────────────────────
        if (adminState.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _statCard("Today's OPD", stats['todayAppointments'] ?? 0,
                  Icons.groups_rounded, AppColors.roleAdmin),
              _statCard('Waiting', stats['opdWaiting'] ?? 0,
                  Icons.hourglass_bottom_rounded, AppColors.warning),
              _statCard('In Consultation', stats['opdInConsultation'] ?? 0,
                  Icons.local_hospital_rounded, AppColors.primary),
              _statCard('Completed Today', stats['completedToday'] ?? 0,
                  Icons.check_circle_rounded, AppColors.success),
              _statCard('Patients', stats['totalPatients'] ?? 0,
                  Icons.personal_injury_rounded, const Color(0xFF0288D1)),
              _statCard('Doctors On Duty',
                  '${stats['doctorsOnDuty'] ?? 0}/${stats['totalDoctors'] ?? 0}',
                  Icons.medical_services_rounded, const Color(0xFFE91E63)),
              _statCard('Pending Alerts', stats['pendingAlerts'] ?? 0,
                  Icons.warning_rounded, AppColors.error),
              _statCard('ASHA Workers', stats['activeAshaWorkers'] ?? 0,
                  Icons.volunteer_activism_rounded,
                  const Color(0xFF2E7D32)),
            ],
          ),

        const SizedBox(height: AppTheme.spacingLg),

        // ── Quick Actions ───────────────────────────────────────
        const Text('Quick Actions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: AppTheme.spacingMd),

        _actionButton(
          icon: Icons.groups_rounded,
          label: 'OPD Queue',
          subtitle: 'Live token queue by doctor',
          color: AppColors.roleAdmin,
          onTap: () => onGoTab(1),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _actionButton(
          icon: Icons.personal_injury_rounded,
          label: 'Patient Directory',
          subtitle: 'Search all patient records',
          color: const Color(0xFF0288D1),
          onTap: () => onGoTab(2),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _actionButton(
          icon: Icons.medical_services_rounded,
          label: 'Doctor Roster',
          subtitle: 'Duty status & daily load',
          color: const Color(0xFFE91E63),
          onTap: () => onGoTab(3),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _actionButton(
          icon: Icons.warning_rounded,
          label: 'Community Alerts',
          subtitle: 'Verify village health issues',
          color: AppColors.error,
          onTap: () => onGoTab(4),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _actionButton(
          icon: Icons.campaign_rounded,
          label: 'Awareness Campaigns',
          subtitle: 'Create & publish drives',
          color: const Color(0xFF9C27B0),
          onTap: () => context.push(RouteNames.adminCreateAwareness),
        ),

        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  Widget _statCard(
      String label, Object value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text('$value',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
            ],
          ),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
