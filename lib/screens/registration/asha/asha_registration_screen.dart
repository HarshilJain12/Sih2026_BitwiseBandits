import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/asha_state_provider.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../../widgets/inputs/password_field.dart';

/// ASHA Worker Registration Screen.
class AshaRegistrationScreen extends StatefulWidget {
  const AshaRegistrationScreen({super.key});

  @override
  State<AshaRegistrationScreen> createState() => _AshaRegistrationScreenState();
}

class _AshaRegistrationScreenState extends State<AshaRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ashaIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedState = 'Maharashtra';
  String _selectedDistrict = 'Pune';
  String _selectedBlock = 'Haveli';
  String _selectedVillage = 'Khed';
  String _selectedWard = 'Ward 1';

  bool _isLoading = false;
  String? _errorMessage;

  final _states = ['Maharashtra', 'Gujarat', 'Rajasthan', 'Karnataka', 'Madhya Pradesh'];
  final _districts = ['Pune', 'Mumbai', 'Nagpur', 'Nashik', 'Aurangabad'];
  final _blocks = ['Haveli', 'Mulshi', 'Bhor', 'Velhe', 'Purandar'];
  final _villages = ['Khed', 'Uruli Kanchan', 'Saswad', 'Jejuri', 'Patas'];
  final _wards = ['Ward 1', 'Ward 2', 'Ward 3', 'Ward 4', 'Ward 5'];

  @override
  void dispose() {
    _nameController.dispose();
    _ashaIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _ashaIdController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill all required fields.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ashaProvider = context.read<AshaStateProvider>();
    
    try {
      final worker = await ashaProvider.register(
        ashaId: _ashaIdController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        state: _selectedState,
        district: _selectedDistrict,
        block: _selectedBlock,
        village: _selectedVillage,
        wardId: _selectedWard,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (worker != null) {
        context.go(RouteNames.ashaDashboard);
      } else {
        setState(() => _errorMessage = 'ASHA ID already exists. Please use a unique ID.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to register: $e';
      });
      // For debugging in console
      debugPrint('Registration Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: const BackButton(),
        title: const Text('ASHA Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingLg),

              // Role Badge
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roleAshaLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: AppColors.roleAsha.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volunteer_activism_rounded,
                        color: AppColors.roleAsha,
                        size: 18,
                      ),
                      SizedBox(width: AppTheme.spacingXs),
                      Text(
                        'ASHA Worker Registration',
                        style: TextStyle(
                          color: AppColors.roleAsha,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              Text(
                'Create Account',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Register your ASHA credentials and assigned jurisdiction.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Name
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // ASHA ID
              AppTextField(
                controller: _ashaIdController,
                label: 'ASHA ID',
                hint: 'e.g. ASHA001',
                prefixIcon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Phone
              AppTextField(
                controller: _phoneController,
                label: 'Mobile Number',
                hint: '+91 XXXXXXXXXX',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Password
              PasswordField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Min 6 characters',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Confirm Password
              PasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Re-enter password',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Location Section Header
              Text(
                'Assigned Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // State Dropdown
              _buildDropdown('State', _selectedState, _states, (v) {
                setState(() => _selectedState = v!);
              }),
              const SizedBox(height: AppTheme.spacingMd),

              // District Dropdown
              _buildDropdown('District', _selectedDistrict, _districts, (v) {
                setState(() => _selectedDistrict = v!);
              }),
              const SizedBox(height: AppTheme.spacingMd),

              // Block Dropdown
              _buildDropdown('Block', _selectedBlock, _blocks, (v) {
                setState(() => _selectedBlock = v!);
              }),
              const SizedBox(height: AppTheme.spacingMd),

              // Village Dropdown
              _buildDropdown('Village', _selectedVillage, _villages, (v) {
                setState(() => _selectedVillage = v!);
              }),
              const SizedBox(height: AppTheme.spacingMd),

              // Ward Dropdown
              _buildDropdown('Ward', _selectedWard, _wards, (v) {
                setState(() => _selectedWard = v!);
              }),
              const SizedBox(height: AppTheme.spacingLg),

              // Error
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 14)),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null)
                const SizedBox(height: AppTheme.spacingMd),

              // Register Button
              PrimaryButton(
                label: 'Register as ASHA Worker',
                onPressed: _onRegister,
                isLoading: _isLoading,
                icon: Icons.how_to_reg_rounded,
              ),

              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
