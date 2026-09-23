import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/hospital_doctor.dart';
import '../../providers/admin_state_provider.dart';

/// Doctor roster: specialization, today's load and on-duty toggle.
class AdminDoctorsScreen extends StatelessWidget {
  const AdminDoctorsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final adminState = context.watch<AdminStateProvider>();

    final body = adminState.isLoading
        ? const Center(child: CircularProgressIndicator())
        : adminState.doctors.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        size: 48, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    const Text('No doctors on roster.',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => adminState.loadAll(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reload'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: adminState.doctors.length,
                itemBuilder: (context, index) =>
                    _doctorCard(context, adminState, adminState.doctors[index]),
              );

    if (embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctors'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _doctorCard(BuildContext context, AdminStateProvider adminState,
      HospitalDoctor d) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.roleAdminLight,
                  child: Text(
                    d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: AppColors.roleAdmin,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${d.name}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(d.specialization,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12)),
                      if (d.phone != null)
                        Text(d.phone!,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('${d.todayLoad}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.roleAdmin)),
                    const Text('today',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (d.onDuty ? AppColors.success : AppColors.textHint)
                        .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(d.onDuty ? 'On duty' : 'Off duty',
                      style: TextStyle(
                          color: d.onDuty
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                const Text('Duty',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Switch(
                  value: d.onDuty,
                  activeThumbColor: AppColors.roleAdmin,
                  onChanged: (v) =>
                      adminState.setDoctorDuty(d.doctorId, v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
