import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_role.dart';
import '../../../widgets/buttons/primary_button.dart';

/// Placeholder screen for registration, which will be implemented in a future chunk.
class RegistrationPlaceholderScreen extends StatelessWidget {
  const RegistrationPlaceholderScreen({super.key, required this.role});

  final UserRole role;

  String _getRoleName(AppLocalizations l10n, UserRole r) {
    switch (r) {
      case UserRole.patient:
        return l10n.rolePatient;
      case UserRole.asha:
        return l10n.roleAsha;
      case UserRole.doctor:
        return l10n.roleDoctor;
      case UserRole.hospitalAdmin:
        return l10n.roleHospitalAdmin;
    }
  }

  IconData _getRoleIcon(UserRole r) {
    switch (r) {
      case UserRole.patient:
        return Icons.person_rounded;
      case UserRole.asha:
        return Icons.volunteer_activism_rounded;
      case UserRole.doctor:
        return Icons.medical_services_rounded;
      case UserRole.hospitalAdmin:
        return Icons.local_hospital_rounded;
    }
  }

  Color _getRoleColor(UserRole r) {
    switch (r) {
      case UserRole.patient:
        return AppColors.rolePatient;
      case UserRole.asha:
        return AppColors.roleAsha;
      case UserRole.doctor:
        return AppColors.roleDoctor;
      case UserRole.hospitalAdmin:
        return AppColors.roleAdmin;
    }
  }

  Color _getRoleLightColor(UserRole r) {
    switch (r) {
      case UserRole.patient:
        return AppColors.rolePatientLight;
      case UserRole.asha:
        return AppColors.roleAshaLight;
      case UserRole.doctor:
        return AppColors.roleDoctorLight;
      case UserRole.hospitalAdmin:
        return AppColors.roleAdminLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roleName = _getRoleName(l10n, role);
    final roleColor = _getRoleColor(role);
    final roleLightColor = _getRoleLightColor(role);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon illustration
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: roleLightColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: roleColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(_getRoleIcon(role), size: 48, color: roleColor),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Title
              Text(
                l10n.comingSoon,
                style: Theme.of(context).textTheme.displayMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Description
              Text(
                l10n.comingSoonDesc(roleName),
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingXxl),

              // Back to Role Selection Button
              PrimaryButton(
                label: l10n.back,
                onPressed: () => context.go(RouteNames.roleSelection),
                icon: Icons.arrow_back_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
