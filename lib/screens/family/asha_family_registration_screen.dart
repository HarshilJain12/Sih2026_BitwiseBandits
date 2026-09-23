import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/family.dart';
import '../../../models/family_member.dart';
import '../../../providers/asha_state_provider.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';

class AshaFamilyRegistrationScreen extends StatefulWidget {
  const AshaFamilyRegistrationScreen({super.key});

  @override
  State<AshaFamilyRegistrationScreen> createState() => _AshaFamilyRegistrationScreenState();
}

class _AshaFamilyRegistrationScreenState extends State<AshaFamilyRegistrationScreen> {
  final _headNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  final List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _headNameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _addMemberForm() {
    setState(() {
      _members.add({
        'name': '',
        'age': '',
        'gender': 'Male',
        'relationship': 'Head',
        'isPregnant': false,
        'isInfant': false,
      });
    });
  }

  Future<void> _submitFamily() async {
    if (_headNameController.text.trim().isEmpty || _members.isEmpty) {
      setState(() => _errorMessage = 'Please provide head of family and at least one member.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ashaProvider = context.read<AshaStateProvider>();
    final worker = ashaProvider.currentWorker;
    if (worker == null) return;

    try {
      final family = await ashaProvider.dataService.createFamily(
        headOfFamilyName: _headNameController.text.trim(),
        address: _addressController.text.trim(),
        village: worker.village,
        ward: worker.wardId,
        block: worker.block,
        district: worker.district,
        contactNumber: _contactController.text.trim(),
      );

      for (var member in _members) {
        if (member['name'].toString().trim().isEmpty) continue;
        await ashaProvider.dataService.addFamilyMember(
          familyId: family.familyId,
          name: member['name'],
          age: int.tryParse(member['age'].toString()) ?? 0,
          gender: member['gender'],
          relationship: member['relationship'],
          pregnancyStatus: member['isPregnant'],
          infantStatus: member['isInfant'],
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family registered successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to register family. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register New Family'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Family Details', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.spacingMd),

              AppTextField(
                controller: _headNameController,
                label: 'Head of Family Name',
                hint: 'Enter name',
              ),
              const SizedBox(height: AppTheme.spacingMd),

              AppTextField(
                controller: _addressController,
                label: 'Address / House No.',
                hint: 'Enter short address',
              ),
              const SizedBox(height: AppTheme.spacingMd),

              AppTextField(
                controller: _contactController,
                label: 'Contact Number',
                hint: 'Optional phone number',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: AppTheme.spacingXl),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Family Members (${_members.length})', 
                    style: Theme.of(context).textTheme.titleLarge),
                  TextButton.icon(
                    onPressed: _addMemberForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Member'),
                  )
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingSm),

              if (_members.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text('No members added yet.\nClick "Add Member" to begin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),

              ...List.generate(_members.length, (index) {
                final m = _members[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Member ${index + 1}', 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () => setState(() => _members.removeAt(index)),
                          )
                        ],
                      ),
                      TextFormField(
                        initialValue: m['name'],
                        decoration: const InputDecoration(labelText: 'Name'),
                        onChanged: (v) => m['name'] = v,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: m['age'],
                              decoration: const InputDecoration(labelText: 'Age'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => m['age'] = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: m['gender'],
                              decoration: const InputDecoration(labelText: 'Gender'),
                              items: ['Male', 'Female', 'Other']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => m['gender'] = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: m['relationship'],
                        decoration: const InputDecoration(labelText: 'Relationship to Head'),
                        items: ['Head', 'Spouse', 'Child', 'Parent', 'Sibling', 'Other']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => m['relationship'] = v!),
                      ),
                      const SizedBox(height: 12),
                      if (m['gender'] == 'Female' && (int.tryParse(m['age']) ?? 0) > 12)
                        CheckboxListTile(
                          title: const Text('Is Pregnant?'),
                          value: m['isPregnant'],
                          onChanged: (v) => setState(() => m['isPregnant'] = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                      if ((int.tryParse(m['age']) ?? 10) <= 2)
                        CheckboxListTile(
                          title: const Text('Is Infant/Newborn?'),
                          value: m['isInfant'],
                          onChanged: (v) => setState(() => m['isInfant'] = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                );
              }),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                ),

              const SizedBox(height: AppTheme.spacingXl),

              PrimaryButton(
                label: 'Save Family',
                onPressed: _submitFamily,
                isLoading: _isLoading,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
