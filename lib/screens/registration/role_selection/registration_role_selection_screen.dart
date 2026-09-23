import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_role.dart';
import '../../../widgets/cards/role_card.dart';

/// Registration Role Selection Screen.
///
/// Users select the role they wish to register for, leading to the
/// registration placeholder screen in this chunk.
class RegistrationRoleSelectionScreen extends StatelessWidget {
  const RegistrationRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 380;

    final roles = [
      _RegistrationRoleData(
        role: UserRole.patient,
        icon: Icons.person_rounded,
        title: l10n.rolePatient,
        description: l10n.rolePatientDesc,
        accentColor: AppColors.rolePatient,
        accentLightColor: AppColors.rolePatientLight,
      ),
      _RegistrationRoleData(
        role: UserRole.asha,
        icon: Icons.volunteer_activism_rounded,
        title: l10n.roleAsha,
        description: l10n.roleAshaDesc,
        accentColor: AppColors.roleAsha,
        accentLightColor: AppColors.roleAshaLight,
      ),
      _RegistrationRoleData(
        role: UserRole.doctor,
        icon: Icons.medical_services_rounded,
        title: l10n.roleDoctor,
        description: l10n.roleDoctorDesc,
        accentColor: AppColors.roleDoctor,
        accentLightColor: AppColors.roleDoctorLight,
      ),
      _RegistrationRoleData(
        role: UserRole.hospitalAdmin,
        icon: Icons.local_hospital_rounded,
        title: l10n.roleHospitalAdmin,
        description: l10n.roleHospitalAdminDesc,
        accentColor: AppColors.roleAdmin,
        accentLightColor: AppColors.roleAdminLight,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingMd),

              // ── Heading ──────────────────────────────────────────────
              Text(
                l10n.registerTitle,
                style: Theme.of(context).textTheme.displayMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                l10n.registerSubtitle,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Role Cards ───────────────────────────────────────────
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
                                onTap: () {
                                  if (r.role == UserRole.patient) {
                                    context.push(RouteNames.patientLogin);
                                  } else if (r.role == UserRole.asha) {
                                    context.push(RouteNames.ashaRegister);
                                  } else {
                                    context.push(
                                      RouteNames.registrationPlaceholder,
                                      extra: r.role,
                                    );
                                  }
                                },
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
                              onTap: () {
                                if (r.role == UserRole.patient) {
                                  context.push(RouteNames.patientLogin);
                                } else if (r.role == UserRole.asha) {
                                  context.push(RouteNames.ashaRegister);
                                } else {
                                  context.push(
                                    RouteNames.registrationPlaceholder,
                                    extra: r.role,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegistrationRoleData {
  const _RegistrationRoleData({
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
