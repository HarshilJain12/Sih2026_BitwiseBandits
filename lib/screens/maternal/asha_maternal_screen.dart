import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/family_member.dart';
import '../../../providers/asha_state_provider.dart';

class AshaMaternalScreen extends StatefulWidget {
  const AshaMaternalScreen({super.key});

  @override
  State<AshaMaternalScreen> createState() => _AshaMaternalScreenState();
}

class _AshaMaternalScreenState extends State<AshaMaternalScreen> {
  bool _isLoading = true;
  List<FamilyMember> _pregnantWomen = [];

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
      final women = await ashaProvider.dataService.getPregnantWomen(worker.village);
      if (mounted) {
        setState(() {
          _pregnantWomen = women;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scheduleCheckup(FamilyMember woman) async {
    final ashaProvider = context.read<AshaStateProvider>();
    final worker = ashaProvider.currentWorker;
    if (worker == null) return;

    await ashaProvider.dataService.createFollowUp(
      ashaId: worker.ashaId,
      memberId: woman.memberId,
      familyId: woman.familyId,
      type: 'pregnancy',
      description: 'Routine Antenatal Checkup for ${woman.name}',
      scheduledDate: DateTime.now().add(const Duration(days: 5)),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Antenatal Checkup scheduled for ${woman.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Maternal Health Roster'),
        backgroundColor: AppColors.background,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pregnantWomen.isEmpty
              ? const Center(child: Text('No pregnant women registered in your village.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: _pregnantWomen.length,
                  itemBuilder: (context, index) {
                    final woman = _pregnantWomen[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFCE4EC), // Pink light
                          child: Icon(Icons.pregnant_woman, color: Color(0xFFE91E63)),
                        ),
                        title: Text(woman.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Age: ${woman.age} • Expected: ${woman.expectedDeliveryMonth ?? "Unknown"}'),
                        trailing: TextButton.icon(
                          onPressed: () => _scheduleCheckup(woman),
                          icon: const Icon(Icons.calendar_month, size: 16),
                          label: const Text('Schedule Checkup'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
