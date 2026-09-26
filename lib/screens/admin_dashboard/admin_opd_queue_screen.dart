import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../providers/admin_state_provider.dart';

/// Live OPD token queue, grouped by doctor.
///
/// Actions per token: Call Next (waiting → in-consultation),
/// Complete, Cancel. Works in `embedded` tab mode or standalone.
class AdminOpdQueueScreen extends StatelessWidget {
  const AdminOpdQueueScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final adminState = context.watch<AdminStateProvider>();

    final body = adminState.isLoading
        ? const Center(child: CircularProgressIndicator())
        : adminState.queue.isEmpty && adminState.completedToday.isEmpty
            ? _emptyState(context, adminState)
            : RefreshIndicator(
                onRefresh: () => adminState.refreshQueue(),
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  children: [
                    _newSlipActionBanner(context),
                    const SizedBox(height: 12),
                    _summaryStrip(adminState),
                    const SizedBox(height: 12),
                    ..._doctorSections(context, adminState),
                    if (adminState.completedToday.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Completed Today',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      ...adminState.completedToday
                          .map((a) => _tokenCard(context, adminState, a,
                              token: null, dimmed: true)),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              );

    if (embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OPD Queue'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _newSlipActionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.roleAdmin.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: AppColors.roleAdmin, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create OPD Slip',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Search patient & generate slip in seconds',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => context.push(RouteNames.adminOpdSlip),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('⚡ New Slip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roleAdmin,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, AdminStateProvider adminState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text('No OPD tokens today.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push(RouteNames.adminOpdSlip),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('⚡ Create First OPD Slip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roleAdmin,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => adminState.loadAll(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload Queue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStrip(AdminStateProvider adminState) {
    final waiting =
        adminState.queue.where((a) => a.status == 'upcoming').length;
    final live =
        adminState.queue.where((a) => a.status == 'current').length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.roleAdminLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('$waiting', 'Waiting', AppColors.warning),
          _summaryItem('$live', 'In Consultation', AppColors.primary),
          _summaryItem('${adminState.completedToday.length}', 'Done',
              AppColors.success),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  List<Widget> _doctorSections(
      BuildContext context, AdminStateProvider adminState) {
    final byDoctor = <String, List<Appointment>>{};
    for (final a in adminState.queue) {
      byDoctor.putIfAbsent(a.doctorId, () => []).add(a);
    }
    final sections = <Widget>[];
    byDoctor.forEach((doctorId, tokens) {
      final doctor = adminState.doctors
          .where((d) => d.doctorId == doctorId)
          .firstOrNull;
      sections.add(
        Row(
          children: [
            Expanded(
              child: Text(
                doctor == null
                    ? doctorId
                    : 'Dr. ${doctor.name} • ${doctor.specialization}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            TextButton.icon(
              onPressed: tokens.any((a) => a.status == 'upcoming')
                  ? () => adminState.callNext(doctorId)
                  : null,
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Call Next'),
            ),
          ],
        ),
      );
      var tokenNo = 0;
      for (final a in tokens) {
        tokenNo++;
        sections.add(_tokenCard(context, adminState, a, token: tokenNo));
      }
      sections.add(const SizedBox(height: 12));
    });
    return sections;
  }

  Widget _tokenCard(BuildContext context, AdminStateProvider adminState,
      Appointment a, {required int? token, bool dimmed = false}) {
    final isLive = a.status == 'current';
    final time = DateFormat('h:mm a').format(a.scheduledAt);
    return Opacity(
      opacity: dimmed ? 0.65 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
            color: isLive ? AppColors.primary : AppColors.border,
            width: isLive ? 1.5 : 1,
          ),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isLive
                      ? AppColors.primary
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  token == null ? '✓' : '#$token',
                  style: TextStyle(
                    color: isLive ? Colors.white : AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.patientName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('$time • ${a.type.replaceAll('_', ' ')} • ${a.patientId}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    _statusChip(a.status),
                  ],
                ),
              ),
              if (!dimmed) ...[
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (a.status == 'upcoming')
                      TextButton(
                        onPressed: () => adminState.updateAppointmentStatus(
                            a.appointmentId, 'current'),
                        child: const Text('Start'),
                      ),
                    if (a.status == 'current')
                      TextButton(
                        onPressed: () => adminState.updateAppointmentStatus(
                            a.appointmentId, 'completed'),
                        child: const Text('Done'),
                      ),
                    TextButton(
                      onPressed: () => adminState.updateAppointmentStatus(
                          a.appointmentId, 'cancelled'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = switch (status) {
      'current' => AppColors.primary,
      'completed' => AppColors.success,
      'cancelled' => AppColors.error,
      _ => AppColors.warning,
    };
    final label = switch (status) {
      'current' => 'In consultation',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => 'Waiting',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
