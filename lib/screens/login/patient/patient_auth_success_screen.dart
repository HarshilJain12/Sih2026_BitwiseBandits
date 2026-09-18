import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/patient.dart';
import '../../../services/firestore/patient_service.dart';
import '../../../services/interfaces/auth_service.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/secondary_button.dart';

/// Authenticated state screen for Phase 2C.
///
/// Displays confirmation of Firebase Phone Authentication, account status,
/// and linked Patient profiles (including unique Patient ID).
class PatientAuthSuccessScreen extends StatefulWidget {
  const PatientAuthSuccessScreen({super.key, this.uid, this.phoneNumber});

  final String? uid;
  final String? phoneNumber;

  @override
  State<PatientAuthSuccessScreen> createState() =>
      _PatientAuthSuccessScreenState();
}

class _PatientAuthSuccessScreenState extends State<PatientAuthSuccessScreen> {
  bool _isLoading = true;
  List<Patient> _linkedPatients = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatientProfiles();
  }

  Future<void> _loadPatientProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final patientService = context.read<PatientService>();
      final patients = await patientService.getLinkedPatients();
      if (mounted) {
        setState(() {
          _linkedPatients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        '[PatientAuthSuccessScreen] Error loading patient profiles: $e',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final resolvedUid = widget.uid ?? authService.currentUserId ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingLg),

              // ── Success Header ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              Text(
                l10n.phoneVerifiedSuccess,
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                l10n.phoneVerifiedSubtitle,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Patient Identity Card / Status ───────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_isLoading) ...[
                        const Padding(
                          padding: EdgeInsets.all(AppTheme.spacingXl),
                          child: CircularProgressIndicator(),
                        ),
                      ] else if (_linkedPatients.isNotEmpty) ...[
                        // Display list of linked patients
                        ..._linkedPatients.map(
                          (patient) => Card(
                            margin: const EdgeInsets.only(
                              bottom: AppTheme.spacingMd,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLg,
                              ),
                              side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            color: AppColors.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(
                                          AppTheme.spacingSm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMd,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.badge_rounded,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spacingMd),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.yourPatientId,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                            Text(
                                              patient.patientId,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                    letterSpacing: 1.1,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy_rounded,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                        tooltip: l10n.copyPatientId,
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: patient.patientId,
                                            ),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l10n.patientIdCopied,
                                                  ),
                                                  backgroundColor:
                                                      AppColors.success,
                                                ),
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(height: AppTheme.spacingLg),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${l10n.fullName}: ${patient.name}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingSm,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.successContainer,
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusSm,
                                          ),
                                        ),
                                        child: Text(
                                          patient.status.toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (patient.age != null ||
                                      patient.weightKg != null ||
                                      patient.heightCm != null) ...[
                                    const SizedBox(height: AppTheme.spacingSm),
                                    Wrap(
                                      spacing: AppTheme.spacingMd,
                                      runSpacing: AppTheme.spacingXs,
                                      children: [
                                        if (patient.age != null)
                                          Text(
                                            '${l10n.age}: ${patient.age} ${l10n.years}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        if (patient.weightKg != null)
                                          Text(
                                            '${l10n.weight}: ${patient.weightKg} ${l10n.kg}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        if (patient.heightCm != null)
                                          Text(
                                            '${l10n.height}: ${patient.heightCm} ${l10n.cm}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: AppTheme.spacingMd),
                                  PrimaryButton(
                                    label: 'Go to Patient Dashboard',
                                    icon: Icons.dashboard_rounded,
                                    onPressed: () => context.go(
                                      RouteNames.patientDashboard,
                                      extra: patient,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // No patient profile linked yet
                        Card(
                          elevation: 0,
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg,
                            ),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingLg),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.account_circle_outlined,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: AppTheme.spacingSm),
                                Text(
                                  'Account Identity Ready',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: AppTheme.spacingXs),
                                Text(
                                  'Complete your basic registration to create your patient profile.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: AppTheme.spacingMd),
                                PrimaryButton(
                                  label: l10n.createProfileButton,
                                  icon: Icons.person_add_rounded,
                                  onPressed: () => context.go(
                                    RouteNames.patientRegistration,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppTheme.spacingMd),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      // ── Debug Info (Development Only) ────────────────────
                      if (kDebugMode && resolvedUid.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacingMd),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.developer_mode_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppTheme.spacingXs),
                                  Text(
                                    l10n.firebaseAuthSuccess,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              Text(
                                l10n.debugFirebaseUid(resolvedUid),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Sign Out / Return Button ─────────────────────────────────
              SecondaryButton(
                label: l10n.signOut,
                icon: Icons.logout_rounded,
                onPressed: () async {
                  await authService.logout();
                  if (context.mounted) {
                    context.go(RouteNames.roleSelection);
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}
