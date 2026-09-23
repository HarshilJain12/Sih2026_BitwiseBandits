import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/patient.dart';
import '../../providers/admin_state_provider.dart';

/// Searchable patient directory for the hospital admin.
class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
  List<Patient>? _results;
  bool _searching = false;

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    final adminState = context.read<AdminStateProvider>();
    final results = await adminState.searchPatients(q);
    if (mounted) {
      setState(() {
        _results = results;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = context.watch<AdminStateProvider>();
    final list = _results ?? adminState.patients;

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, patient ID or phone...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: _runSearch,
          ),
        ),
        if (_searching)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else if (list.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No patients found.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd),
              itemCount: list.length,
              itemBuilder: (context, index) =>
                  _patientCard(list[index]),
            ),
          ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patients'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _patientCard(Patient p) {
    final initial =
        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: Text(initial,
                  style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '${p.patientId}${p.age != null ? ' • ${p.age} yrs' : ''} • ${p.phoneNumber}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (p.healthTags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: p.healthTags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusFull),
                                ),
                                child: Text(t,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(p.status,
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
