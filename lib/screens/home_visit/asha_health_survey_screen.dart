import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/family.dart';
import '../../../models/family_member.dart';
import '../../../providers/asha_state_provider.dart';
import '../../../widgets/buttons/primary_button.dart';

class AshaHealthSurveyScreen extends StatefulWidget {
  const AshaHealthSurveyScreen({super.key, required this.family});

  final Family family;

  @override
  State<AshaHealthSurveyScreen> createState() => _AshaHealthSurveyScreenState();
}

class _AshaHealthSurveyScreenState extends State<AshaHealthSurveyScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<FamilyMember> _members = [];
  final Map<String, Map<String, dynamic>> _observations = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final ashaProvider = context.read<AshaStateProvider>();
    try {
      final members = await ashaProvider.dataService.getFamilyMembers(widget.family.familyId);
      if (mounted) {
        setState(() {
          _members = members;
          for (var m in members) {
            _observations[m.memberId] = {
              'generalHealth': '',
              'maternalHealth': '',
              'infantHealth': '',
              'nutrition': '',
              'followUpRequired': false,
            };
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitSurvey() async {
    setState(() => _isSubmitting = true);
    final ashaProvider = context.read<AshaStateProvider>();
    final worker = ashaProvider.currentWorker;
    if (worker == null) return;

    try {
      // 1. Create a Visit record
      final visit = await ashaProvider.dataService.createHomeVisit(
        ashaId: worker.ashaId,
        familyId: widget.family.familyId,
      );

      // 2. Create Observations for each member that has data
      for (var member in _members) {
        final obsData = _observations[member.memberId]!;
        
        final hasData = (obsData['generalHealth'] as String).isNotEmpty ||
                        (obsData['maternalHealth'] as String).isNotEmpty ||
                        (obsData['infantHealth'] as String).isNotEmpty ||
                        (obsData['nutrition'] as String).isNotEmpty ||
                        (obsData['followUpRequired'] as bool);
                        
        if (hasData) {
          await ashaProvider.dataService.createObservation(
            visitId: visit.visitId,
            memberId: member.memberId,
            generalHealth: obsData['generalHealth'] as String,
            maternalHealth: obsData['maternalHealth'] as String,
            infantHealth: obsData['infantHealth'] as String,
            nutrition: obsData['nutrition'] as String,
            followUpRequired: obsData['followUpRequired'] as bool,
          );

          // If follow up required, create follow up task
          if (obsData['followUpRequired'] as bool) {
            await ashaProvider.dataService.createFollowUp(
              ashaId: worker.ashaId,
              memberId: member.memberId,
              familyId: widget.family.familyId,
              type: 'general',
              description: 'Follow-up requested from health survey for ${member.name}',
              scheduledDate: DateTime.now().add(const Duration(days: 3)),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Home visit and health observations recorded successfully!')),
      );
      Navigator.pop(context); // Go back to Home Visit search list
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit survey.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health Survey'),
        backgroundColor: AppColors.background,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Family info header
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.roleAshaLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Visiting Family', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.roleAsha)),
                        const SizedBox(height: 4),
                        Text(widget.family.headOfFamilyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('${widget.family.address}, ${widget.family.ward}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),
                  Text('Family Members', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),

                  ..._members.map((member) => _buildMemberSurveyCard(member)),

                  const SizedBox(height: AppTheme.spacingXl),

                  PrimaryButton(
                    label: 'Complete Visit',
                    onPressed: _submitSurvey,
                    isLoading: _isSubmitting,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMemberSurveyCard(FamilyMember member) {
    final obs = _observations[member.memberId]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: ExpansionTile(
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${member.age} yrs • ${member.gender} • ${member.relationship}'),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'General Health (e.g. fever, cough)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              filled: true,
              fillColor: AppColors.background,
            ),
            onChanged: (v) => obs['generalHealth'] = v,
          ),
          
          if (member.pregnancyStatus) ...[
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Maternal Health Observations',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (v) => obs['maternalHealth'] = v,
            ),
          ],
          
          if (member.infantStatus) ...[
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Infant Health / Growth',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (v) => obs['infantHealth'] = v,
            ),
          ],

          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Nutrition Advice Given',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              filled: true,
              fillColor: AppColors.background,
            ),
            onChanged: (v) => obs['nutrition'] = v,
          ),

          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Follow-up Required (Schedule Visit)'),
            value: obs['followUpRequired'] as bool,
            onChanged: (v) {
              setState(() {
                obs['followUpRequired'] = v;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}
