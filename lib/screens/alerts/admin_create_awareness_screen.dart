import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/community_health_alert.dart';
import '../../../services/firestore/asha_data_service.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';

class AdminCreateAwarenessScreen extends StatefulWidget {
  const AdminCreateAwarenessScreen({super.key, this.alert});

  final CommunityHealthAlert? alert;

  @override
  State<AdminCreateAwarenessScreen> createState() => _AdminCreateAwarenessScreenState();
}

class _AdminCreateAwarenessScreenState extends State<AdminCreateAwarenessScreen> {
  final AshaDataService _dataService = AshaDataService();
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _safetyController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.alert != null) {
      _titleController.text = 'Alert: ${widget.alert!.issueType} in ${widget.alert!.village}';
      _descController.text = 'We have received reports of ${widget.alert!.issueType.toLowerCase()} in ${widget.alert!.village}, Ward ${widget.alert!.ward}. Please take necessary precautions.';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _safetyController.dispose();
    super.dispose();
  }

  Future<void> _publishCampaign() async {
    if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty || _safetyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final campaign = await _dataService.createCampaign(
        alertId: widget.alert?.alertId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        safetyInstructions: _safetyController.text.trim(),
        hospitalName: 'District Central Hospital', // Mock for prototype
        contactInfo: '104 (Health Helpline)',
        targetVillages: widget.alert != null ? [widget.alert!.village] : ['All'],
        targetWards: widget.alert != null ? [widget.alert!.ward] : ['All'],
        targetType: widget.alert != null ? 'ward' : 'all',
        createdBy: 'ADMIN_001',
      );

      await _dataService.publishCampaign(campaign.campaignId);

      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Awareness Campaign Published!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to publish campaign.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Awareness Campaign'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.alert != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.roleAshaLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppColors.roleAsha.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Linked to ASHA Alert', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.roleAsha)),
                      const SizedBox(height: 4),
                      Text(widget.alert!.issueType, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Reported by ${widget.alert!.ashaName} in ${widget.alert!.village}'),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
              ],

              AppTextField(
                controller: _titleController,
                label: 'Campaign Title',
                hint: 'e.g. Dengue Prevention Drive',
              ),
              const SizedBox(height: AppTheme.spacingMd),

              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description / Situation Update',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              TextField(
                controller: _safetyController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Safety Instructions & Guidelines',
                  hintText: '1. Boil water before drinking\n2. Use mosquito nets...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              PrimaryButton(
                label: 'Publish Campaign',
                onPressed: _publishCampaign,
                isLoading: _isLoading,
                icon: Icons.campaign_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
