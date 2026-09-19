import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/hospital_result.dart';
import '../../models/patient.dart';
import '../../providers/app_state_provider.dart';
import '../../services/firestore/patient_service.dart';
import '../../services/interfaces/auth_service.dart';
import 'widgets/ai_health_summary_widget.dart';
import 'widgets/emergency_help_section.dart';
import 'widgets/find_hospital_section.dart';
import 'widgets/follow_up_section.dart';
import 'widgets/nurse_companion_widget.dart';
import 'widgets/quick_access_section.dart';

/// Main Patient Home Dashboard Screen (SIH 2026).
class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key, this.patient});

  final Patient? patient;

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentBottomNavIndex = 0;
  Patient? _activePatient;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _activePatient = widget.patient;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context
              .read<AppStateProvider>()
              .setCurrentPatientId(widget.patient!.patientId);
        }
      });
    } else {
      _loadPatientData();
    }
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);
    try {
      final patientService = context.read<PatientService>();
      final appState = context.read<AppStateProvider>();
      final linkedPatients = await patientService.getLinkedPatients();
      if (mounted) {
        setState(() {
          if (linkedPatients.isNotEmpty) {
            final targetPatientId = appState.currentPatientId;
            final matched = targetPatientId != null
                ? linkedPatients
                    .where((p) => p.patientId == targetPatientId)
                    .firstOrNull
                : null;
            _activePatient = matched ?? linkedPatients.first;
            appState.setCurrentPatientId(_activePatient!.patientId);
          } else {
            // Fallback default profile if no Firestore document exists yet
            _activePatient = Patient(
              patientId: 'P-1002348912',
              ownerUid: 'temp_uid',
              name: 'Rahul Sharma',
              phoneNumber: '+919876543210',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activePatient = Patient(
            patientId: 'P-1002348912',
            ownerUid: 'temp_uid',
            name: 'Rahul Sharma',
            phoneNumber: '+919876543210',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _isLoading = false;
        });
      }
    }
  }

  String _getGreetingText(AppLocalizations l10n, String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.greetingMorning(name);
    } else if (hour < 17) {
      return l10n.greetingAfternoon(name);
    } else {
      return l10n.greetingEvening(name);
    }
  }

  void _onOpenMap(
    HospitalResult selected,
    List<HospitalResult> allResults, {
    double? userLat,
    double? userLng,
  }) {
    context.push(
      RouteNames.hospitalMap,
      extra: {
        'selectedHospital': selected,
        'allHospitals': allResults,
        'userLat': userLat,
        'userLng': userLng,
      },
    );
  }

  Future<void> _onGetDirections(HospitalResult hospital) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map for ${hospital.name}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final patient = _activePatient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentBottomNavIndex,
              children: [
                // ── Tab 0: Home Dashboard ────────────────────────────────
                _buildHomeTab(context, l10n, patient!),

                // ── Tab 1: Health / Records Summary ──────────────────────
                _buildHealthTab(context, l10n, patient),

                // ── Tab 2: Profile ──────────────────────────────────────
                _buildProfileTab(context, l10n, patient),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) => setState(() => _currentBottomNavIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.medical_information_rounded),
            label: l10n.navHealth,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, AppLocalizations l10n, Patient patient) {
    final patientName = patient.name.isNotEmpty ? patient.name : 'Patient';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting Header ─────────────────────────────────────────
          Text(
            _getGreetingText(l10n, patientName),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.patientIdLabel(patient.patientId),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
          ),

          // ── 1. AI Nurse Companion Section ────────────────────────────
          NurseCompanionWidget(patient: patient),

          const SizedBox(height: AppTheme.spacingLg),

          // ── 2. Find the Hospital Section ──────────────────────────────
          FindHospitalSection(
            onOpenMap: (selected, allResults, userLat, userLng) {
              _onOpenMap(
                selected,
                allResults,
                userLat: userLat,
                userLng: userLng,
              );
            },
            onGetDirections: _onGetDirections,
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // ── 3. Quick Access Section ──────────────────────────────────
          QuickAccessSection(patient: patient),

          const SizedBox(height: AppTheme.spacingXl),

          // ── 4. Your Follow-ups Section ───────────────────────────────
          const FollowUpSection(),

          const SizedBox(height: AppTheme.spacingXl),

          // ── 5. Emergency Help Section ────────────────────────────────
          const EmergencyHelpSection(),

          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }

  Widget _buildHealthTab(BuildContext context, AppLocalizations l10n, Patient patient) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.medicalRecordsTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          AiHealthSummaryWidget(
            patientId: patient.patientId,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: ListTile(
              leading: const Icon(Icons.folder_open_rounded, color: AppColors.primary),
              title: const Text('Access Health Records & Prescriptions'),
              subtitle: const Text('View and manage uploaded medical documents.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => context.go(
                RouteNames.medicalRecordsPlaceholder,
                extra: patient,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, AppLocalizations l10n, Patient patient) {
    final authService = context.read<AuthService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.navProfile,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(Icons.person_rounded, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    patient.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    l10n.patientIdLabel(patient.patientId),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.phone_rounded),
                    title: const Text('Phone Number'),
                    subtitle: Text(patient.phoneNumber),
                  ),
                  if (patient.location != null)
                    ListTile(
                      leading: const Icon(Icons.location_on_rounded),
                      title: const Text('Saved Location'),
                      subtitle: Text(
                        patient.location?.isGps == true
                            ? 'GPS Location (${patient.location?.latitude?.toStringAsFixed(4)}, ${patient.location?.longitude?.toStringAsFixed(4)})'
                            : '${patient.location?.village ?? ''}, ${patient.location?.district ?? ''}',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          ElevatedButton.icon(
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                context.go(RouteNames.roleSelection);
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.signOut),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorContainer,
              foregroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
