import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_role.dart';
import '../../widgets/cards/role_card.dart';

/// Screen 2 — Role Selection.
///
/// Shown after language is selected. Fully localized to the selected language.
/// Displays 4 role cards in a responsive grid (2×2 on wide screens, list on narrow).
/// "First time? Register" link at bottom navigates to registration flow.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 380;

    final roles = _buildRoleData(l10n);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(RouteNames.languageSelection),
          tooltip: l10n.back,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingMd),

              // ── Heading ────────────────────────────────────────────────
              Text(
                l10n.chooseRole,
                style: Theme.of(context).textTheme.displayMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                l10n.chooseRoleSubtitle,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Role Cards Grid ────────────────────────────────────────
              Expanded(
                child: isWide
                    ? GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppTheme.spacingMd,
                        mainAxisSpacing: AppTheme.spacingMd,
                        childAspectRatio: 1.0,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: roles
                            .map(
                              (r) => RoleCard(
                                icon: r.icon,
                                title: r.title,
                                description: r.description,
                                accentColor: r.accentColor,
                                accentLightColor: r.accentLightColor,
                                onTap: () => _navigateToLogin(context, r.role),
                              ),
                            )
                            .toList(),
                      )
                    : ListView.separated(
                        itemCount: roles.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppTheme.spacingMd),
                        itemBuilder: (context, i) {
                          final r = roles[i];
                          return SizedBox(
                            height: AppTheme.roleCardMinHeight,
                            child: RoleCard(
                              icon: r.icon,
                              title: r.title,
                              description: r.description,
                              accentColor: r.accentColor,
                              accentLightColor: r.accentLightColor,
                              onTap: () => _navigateToLogin(context, r.role),
                            ),
                          );
                        },
                      ),
              ),

              // ── Register CTA ───────────────────────────────────────────
              const SizedBox(height: AppTheme.spacingMd),
              Center(
                child: TextButton(
                  onPressed: () =>
                      context.push(RouteNames.registrationRoleSelection),
                  child: Text(
                    l10n.firstTimeRegister,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.patient:
        context.push(RouteNames.patientLogin);
      case UserRole.asha:
        context.push(RouteNames.ashaLogin);
      case UserRole.doctor:
        context.push(RouteNames.doctorLogin);
      case UserRole.hospitalAdmin:
        context.push(RouteNames.hospitalAdminLogin);
    }
  }

  List<_RoleData> _buildRoleData(AppLocalizations l10n) {
    return [
      _RoleData(
        role: UserRole.patient,
        icon: Icons.person_rounded,
        title: l10n.rolePatient,
        description: l10n.rolePatientDesc,
        accentColor: AppColors.rolePatient,
        accentLightColor: AppColors.rolePatientLight,
      ),
      _RoleData(
        role: UserRole.asha,
        icon: Icons.volunteer_activism_rounded,
        title: l10n.roleAsha,
        description: l10n.roleAshaDesc,
        accentColor: AppColors.roleAsha,
        accentLightColor: AppColors.roleAshaLight,
      ),
      _RoleData(
        role: UserRole.doctor,
        icon: Icons.medical_services_rounded,
        title: l10n.roleDoctor,
        description: l10n.roleDoctorDesc,
        accentColor: AppColors.roleDoctor,
        accentLightColor: AppColors.roleDoctorLight,
      ),
      _RoleData(
        role: UserRole.hospitalAdmin,
        icon: Icons.local_hospital_rounded,
        title: l10n.roleHospitalAdmin,
        description: l10n.roleHospitalAdminDesc,
        accentColor: AppColors.roleAdmin,
        accentLightColor: AppColors.roleAdminLight,
      ),
    ];
  }
}

class _RoleData {
  const _RoleData({
    required this.role,
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.accentLightColor,
  });

  final UserRole role;
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final Color accentLightColor;
}
