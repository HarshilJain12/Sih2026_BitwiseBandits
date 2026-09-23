import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/family_member.dart';
import '../../../models/home_visit.dart';
import '../../../providers/asha_state_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Infant Care Screen
// ─────────────────────────────────────────────────────────────────────────────

class AshaInfantCareScreen extends StatefulWidget {
  const AshaInfantCareScreen({super.key});

  @override
  State<AshaInfantCareScreen> createState() => _AshaInfantCareScreenState();
}

class _AshaInfantCareScreenState extends State<AshaInfantCareScreen> {
  bool _isLoading = true;
  List<FamilyMember> _infants = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final ashaProvider = context.read<AshaStateProvider>();
    final worker = ashaProvider.currentWorker;
    try {
      final infants = await ashaProvider.dataService.getInfants(worker.village);
      if (mounted) {
        setState(() {
          _infants = infants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scheduleFollowUp(FamilyMember infant) async {
    final ashaProvider = context.read<AshaStateProvider>();
    final worker = ashaProvider.currentWorker;
    await ashaProvider.dataService.createFollowUp(
      ashaId: worker.ashaId,
      memberId: infant.memberId,
      familyId: infant.familyId,
      type: 'general',
      description: 'Infant nutrition & growth monitoring for ${infant.name}',
      scheduledDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Follow-up scheduled for ${infant.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mother & Child Care',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _infants.isEmpty
                  ? _buildEmptyState()
                  : _buildInfantList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.child_care_rounded, size: 72, color: Color(0xFFFF9800)),
              SizedBox(height: 16),
              Text(
                'No infants registered in your village.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Register families with infants to track them here.',
                style: TextStyle(color: AppColors.textHint, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfantList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _infants.length,
      itemBuilder: (context, index) {
        final infant = _infants[index];
        final ageLabel = infant.age == 0 ? 'Newborn' : '${infant.age} months';
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: const BorderSide(color: Color(0xFFFFCC80), width: 1.5),
          ),
          color: AppColors.surface,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0B2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.child_care_rounded,
                          color: Color(0xFFE65100), size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(infant.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            '$ageLabel • ${infant.gender}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (infant.nutritionStatus != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monitor_weight_rounded,
                            size: 16, color: Color(0xFFFF9800)),
                        const SizedBox(width: 6),
                        Text(
                          infant.nutritionStatus!,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFFE65100)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _scheduleFollowUp(infant),
                        icon: const Icon(Icons.add_alarm_rounded, size: 16),
                        label: const Text('Schedule Visit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF9800),
                          side: const BorderSide(color: Color(0xFFFF9800)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visit History Screen
// ─────────────────────────────────────────────────────────────────────────────

class AshaVisitHistoryScreen extends StatefulWidget {
  const AshaVisitHistoryScreen({super.key});

  @override
  State<AshaVisitHistoryScreen> createState() => _AshaVisitHistoryScreenState();
}

class _AshaVisitHistoryScreenState extends State<AshaVisitHistoryScreen> {
  bool _isLoading = true;
  List<HomeVisit> _visits = [];

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() => _isLoading = true);
    final ashaProvider = context.read<AshaStateProvider>();
    final worker = ashaProvider.currentWorker;
    try {
      final visits = await ashaProvider.dataService.getVisitsByAsha(worker.ashaId);
      if (mounted) {
        setState(() {
          _visits = visits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group visits by month
    final Map<String, List<HomeVisit>> grouped = {};
    for (final v in _visits) {
      final key = DateFormat('MMMM yyyy').format(v.date);
      grouped.putIfAbsent(key, () => []).add(v);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Visit History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: _loadVisits,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visits.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVisits,
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    children: [
                      // Summary card
                      _buildSummaryCard(),
                      const SizedBox(height: AppTheme.spacingMd),
                      // Grouped visit cards
                      ...grouped.entries.map((entry) => _buildMonthGroup(
                            entry.key,
                            entry.value,
                          )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 72, color: AppColors.textHint),
          SizedBox(height: 16),
          Text(
            'No visit records yet.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Start a home visit to see history here.',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final now = DateTime.now();
    final thisMonth = _visits.where((v) =>
        v.date.year == now.year && v.date.month == now.month).length;
    final today = _visits.where((v) =>
        v.date.year == now.year &&
        v.date.month == now.month &&
        v.date.day == now.day).length;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.roleAshaLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total', '${_visits.length}', Icons.home_work_rounded),
          _summaryItem('This Month', '$thisMonth', Icons.calendar_month_rounded),
          _summaryItem('Today', '$today', Icons.today_rounded),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.roleAsha, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.roleAsha)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildMonthGroup(String monthLabel, List<HomeVisit> visits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
          child: Text(
            monthLabel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ...visits.map((v) => _buildVisitTile(v)),
      ],
    );
  }

  Widget _buildVisitTile(HomeVisit visit) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.roleAshaLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.home_work_rounded,
              color: AppColors.roleAsha, size: 20),
        ),
        title: Text(
          'Home Visit',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy, hh:mm a').format(visit.date),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            visit.status.toUpperCase(),
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ASHA Profile Screen
// ─────────────────────────────────────────────────────────────────────────────

class AshaProfileScreen extends StatelessWidget {
  const AshaProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ashaProvider = context.watch<AshaStateProvider>();
    final worker = ashaProvider.currentWorker;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar + Name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.roleAsha,
                    child: Text(
                      worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'A',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    worker.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.roleAshaLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ASHA ID: ${worker.ashaId}',
                      style: const TextStyle(
                          color: AppColors.roleAsha,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Info Cards
            _buildSection('Personal Information', [
              _buildInfoRow(Icons.phone_rounded, 'Phone', worker.phone),
              _buildInfoRow(Icons.badge_rounded, 'ASHA ID', worker.ashaId),
            ]),

            const SizedBox(height: AppTheme.spacingMd),

            _buildSection('Assigned Area', [
              _buildInfoRow(Icons.location_city_rounded, 'Village', worker.village),
              _buildInfoRow(Icons.grid_3x3_rounded, 'Ward', worker.wardId),
              _buildInfoRow(Icons.business_rounded, 'Block', worker.block),
              _buildInfoRow(Icons.map_rounded, 'District', worker.district),
              _buildInfoRow(Icons.public_rounded, 'State', worker.state),
            ]),

            const SizedBox(height: AppTheme.spacingMd),

            _buildSection('Account Actions', [
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text('Sign Out',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Sign Out?'),
                      content: const Text('You will be returned to the login screen.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ashaProvider.logout();
                            context.go(RouteNames.ashaLogin);
                          },
                          child: const Text('Sign Out',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 40),

            // Version note
            const Center(
              child: Text(
                'SIH 2026 • BitWise Bandits • ASHA Health System',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.roleAsha, size: 20),
      title: Text(label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      subtitle: Text(value,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14)),
    );
  }
}
