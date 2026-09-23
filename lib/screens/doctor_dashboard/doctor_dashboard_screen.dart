import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../models/patient.dart';
import '../../providers/app_state_provider.dart';
import '../../services/firestore/appointment_service.dart';
import '../../services/firestore/patient_service.dart';
import '../../services/interfaces/auth_service.dart';

/// Doctor Dashboard — the clinical workstation for authenticated doctors.
///
/// Provides:
/// 1. Appointment summary (total + current, from real Firestore data)
/// 2. Patient search by name with disambiguation
/// 3. QR scanner launch
/// 4. Current appointment list with direct patient record access
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool _isLoading = true;
  List<Appointment> _allAppointments = [];
  List<Appointment> _currentAppointments = [];
  String? _errorMessage;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreetingText(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, $name';
    if (hour < 17) return 'Good Afternoon, $name';
    return 'Good Evening, $name';
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppStateProvider>();
      final appointmentService = context.read<AppointmentService>();
      final doctorId = appState.activeDoctorId ?? '';
      final doctorName = appState.activeDoctorName ?? 'Doctor';

      // Seed appointments if empty (uses real patient data from Firestore)
      await appointmentService.seedDefaultAppointmentsIfEmpty(
        doctorId: doctorId,
        doctorName: doctorName,
      );

      final all = await appointmentService.getAppointmentsForDoctor(doctorId);
      final current = all.where((a) => a.isCurrent).toList();

      if (mounted) {
        setState(() {
          _allAppointments = all;
          _currentAppointments = current;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load dashboard data.';
        });
      }
    }
  }



  void _openPatientRecord(String patientId) {
    context.push(RouteNames.doctorPatientRecord, extra: patientId);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final doctorName = appState.activeDoctorName ?? 'Doctor';
    final specialization = appState.activeDoctorSpecialization ?? '';

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
                Icons.medical_services_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              'Doctor Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.logout();
              if (context.mounted) {
                context.read<AppStateProvider>().clearDoctorSession();
                context.go(RouteNames.roleSelection);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildDashboard(doctorName, specialization),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: AppTheme.spacingMd),
          Text(_errorMessage!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(String doctorName, String specialization) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting Header ──────────────────────────────────────
            Text(
              _getGreetingText('Dr. $doctorName'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (specialization.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  specialization,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),

            const SizedBox(height: AppTheme.spacingXl),

            // ── Appointment Summary ──────────────────────────────────
            Text(
              'APPOINTMENTS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'Total Appointments',
                    value: '${_allAppointments.length}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.access_time_rounded,
                    label: 'Current',
                    value: '${_currentAppointments.length}',
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // ── Find Patient ──────────────────────────────────────
            Text(
              'FIND PATIENT',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            Autocomplete<Patient>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                final query = textEditingValue.text.trim();
                if (query.isEmpty) {
                  return const Iterable<Patient>.empty();
                }
                // Debounce is handled natively by the user typing, but we can just fetch
                try {
                  final patientService = context.read<PatientService>();
                  return await patientService.searchPatientsByName(query);
                } catch (e) {
                  return const Iterable<Patient>.empty();
                }
              },
              displayStringForOption: (Patient p) => p.name,
              onSelected: (Patient p) {
                _openPatientRecord(p.patientId);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (String value) {
                    onFieldSubmitted();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search patient by name...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              controller.clear();
                              // Trigger a rebuild to hide the suffix icon
                              (context as Element).markNeedsBuild();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingMd,
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width - (AppTheme.spacingLg * 2),
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final patient = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(patient),
                            child: _buildPatientSearchResult(patient),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Scan QR button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(RouteNames.doctorQrScanner),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan Patient QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // ── Current Appointments ─────────────────────────────────
            Text(
              'CURRENT APPOINTMENTS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            if (_currentAppointments.isEmpty)
              _buildEmptyState('No current appointments.'),

            ..._currentAppointments.map((apt) => _buildAppointmentCard(apt)),

            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSearchResult(Patient patient) {
    final locationText = patient.location != null
        ? (patient.location!.village ?? patient.location!.district ?? '')
        : '';

    return Card(
      margin: const EdgeInsets.only(top: AppTheme.spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          patient.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patient.patientId,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (locationText.isNotEmpty)
              Text(
                locationText,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            if (patient.age != null)
              Text(
                'Age: ${patient.age}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () => _openPatientRecord(patient.patientId),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment apt) {
    final timeStr =
        '${apt.scheduledAt.hour.toString().padLeft(2, '0')}:${apt.scheduledAt.minute.toString().padLeft(2, '0')}';

    Color statusColor;
    switch (apt.status) {
      case 'current':
        statusColor = const Color(0xFF10B981);
        break;
      case 'completed':
        statusColor = AppColors.textSecondary;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Text(
            apt.patientName.isNotEmpty
                ? apt.patientName[0].toUpperCase()
                : 'P',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
        title: Text(
          apt.patientName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(timeStr, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                apt.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () => _openPatientRecord(apt.patientId),
          child: const Text('View Record'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
