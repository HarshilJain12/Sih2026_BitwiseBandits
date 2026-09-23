import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/family.dart';
import '../../../models/family_member.dart';
import '../../../models/vaccination_record.dart';
import '../../../providers/asha_state_provider.dart';

class AshaVaccinationScreen extends StatefulWidget {
  const AshaVaccinationScreen({super.key});

  @override
  State<AshaVaccinationScreen> createState() => _AshaVaccinationScreenState();
}

class _AshaVaccinationScreenState extends State<AshaVaccinationScreen> {
  bool _isLoading = true;
  List<VaccinationRecord> _vaccinations = [];
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
    if (worker == null) return;

    try {
      final vaccinations = await ashaProvider.dataService.getVaccinationsByChw(worker.ashaId);
      final infants = await ashaProvider.dataService.getInfants(worker.village);
      
      if (mounted) {
        setState(() {
          _vaccinations = vaccinations;
          _infants = infants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _administerVaccine(VaccinationRecord record) async {
    final ashaProvider = context.read<AshaStateProvider>();
    await ashaProvider.dataService.administerVaccination(record.vaccinationId);
    _loadData(); // Refresh list
  }

  Future<void> _scheduleVaccination(FamilyMember infant) async {
    final ashaProvider = context.read<AshaStateProvider>();
    final worker = ashaProvider.currentWorker;
    if (worker == null) return;

    await ashaProvider.dataService.scheduleVaccination(
      patientId: infant.patientId ?? 'UNKNOWN',
      memberId: infant.memberId,
      chwId: worker.ashaId,
      vaccineName: 'Polio / BCG', // Simplified for prototype
      vaccineType: 'Routine Infant',
      scheduledDate: DateTime.now().add(const Duration(days: 7)),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Vaccination Management'),
          backgroundColor: AppColors.background,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Due Vaccinations'),
              Tab(text: 'Infant Roster'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildDueVaccinationsTab(),
                  _buildInfantRosterTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildDueVaccinationsTab() {
    final pending = _vaccinations.where((v) => v.status == 'scheduled' || v.status == 'pending').toList();

    if (pending.isEmpty) {
      return const Center(child: Text('No pending vaccinations.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final record = pending[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(Icons.vaccines, color: AppColors.primaryDark),
            ),
            title: Text(record.vaccineName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Due: ${DateFormat('dd MMM yyyy').format(record.scheduledDate)}'),
            trailing: ElevatedButton(
              onPressed: () => _administerVaccine(record),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark Done'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfantRosterTab() {
    if (_infants.isEmpty) {
      return const Center(child: Text('No infants registered in your assigned village.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _infants.length,
      itemBuilder: (context, index) {
        final infant = _infants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFE0B2),
              child: Icon(Icons.child_care, color: Color(0xFFE65100)),
            ),
            title: Text(infant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${infant.age} months • ${infant.gender}'),
            trailing: TextButton.icon(
              onPressed: () => _scheduleVaccination(infant),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('Schedule'),
            ),
          ),
        );
      },
    );
  }
}
