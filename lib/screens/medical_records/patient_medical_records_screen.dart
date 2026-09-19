import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medical_record.dart';
import '../../models/patient.dart';
import '../../services/firestore/medical_record_service.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import 'widgets/delete_record_dialog.dart';
import 'widgets/document_viewer_dialog.dart';
import 'widgets/medical_record_card.dart';

/// Main Medical Records screen supporting both:
/// 1. Registration Mode (optional step during registration with Skip / Continue)
/// 2. Standalone Mode (view & manage records from patient dashboard)
class PatientMedicalRecordsScreen extends StatefulWidget {
  const PatientMedicalRecordsScreen({
    super.key,
    required this.patientId,
    this.patient,
    this.isRegistration = false,
  });

  final String patientId;
  final Patient? patient;
  final bool isRegistration;

  @override
  State<PatientMedicalRecordsScreen> createState() =>
      _PatientMedicalRecordsScreenState();
}

class _PatientMedicalRecordsScreenState
    extends State<PatientMedicalRecordsScreen> {
  bool _isLoading = true;
  List<MedicalRecord> _records = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = context.read<MedicalRecordService>();
      final records = await service.getRecordsForPatient(widget.patientId);
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.errorLoadRecordsFailed;
        });
      }
    }
  }

  void _navigateToAddRecord() {
    context.push(
      RouteNames.addMedicalRecordCategory,
      extra: {
        'patientId': widget.patientId,
        'isRegistration': widget.isRegistration,
      },
    ).then((_) {
      if (mounted) _loadRecords();
    });
  }

  Future<void> _handleDeleteRecord(MedicalRecord record) async {
    final service = context.read<MedicalRecordService>();
    final confirmed = await DeleteRecordDialog.show(
      context,
      record: record,
      service: service,
    );

    if (confirmed == true && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.recordDeleted),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadRecords();
    }
  }

  void _handleOpenRecord(MedicalRecord record) {
    final service = context.read<MedicalRecordService>();
    DocumentViewerDialog.openRecord(
      context: context,
      record: record,
      service: service,
    );
  }

  void _handleFinishOrSkip() {
    if (widget.patient != null) {
      context.go(RouteNames.patientDashboard, extra: widget.patient);
    } else {
      context.go(RouteNames.patientDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: widget.isRegistration
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        title: Text(
          widget.isRegistration
              ? l10n.addMedicalRecordsTitle
              : l10n.medicalRecordsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refreshRecords,
            onPressed: _isLoading ? null : _loadRecords,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadRecords,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header Subtitle / Intro ─────────────────────────
                      if (widget.isRegistration) ...[
                        Text(
                          l10n.addMedicalRecordsSubtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                      ],

                      // ── Error Banner ────────────────────────────────────
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          margin: const EdgeInsets.only(
                            bottom: AppTheme.spacingMd,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Empty State OR Records List ─────────────────────
                      if (_records.isEmpty) ...[
                        _buildEmptyState(context, l10n),
                      ] else ...[
                        _buildRecordList(context, l10n),
                      ],

                      const SizedBox(height: AppTheme.spacingLg),

                      // ── Registration Flow Footer Buttons ────────────────
                      if (widget.isRegistration) ...[
                        if (_records.isNotEmpty) ...[
                          PrimaryButton(
                            label: l10n.finishRegistration,
                            icon: Icons.check_circle_rounded,
                            onPressed: _handleFinishOrSkip,
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          SecondaryButton(
                            label: l10n.addMedicalRecordButton,
                            icon: Icons.add_rounded,
                            onPressed: _navigateToAddRecord,
                          ),
                        ] else ...[
                          PrimaryButton(
                            label: l10n.addMedicalRecordButton,
                            icon: Icons.add_rounded,
                            onPressed: _navigateToAddRecord,
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          TextButton(
                            onPressed: _handleFinishOrSkip,
                            child: Text(
                              l10n.skipForNow,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: (!widget.isRegistration && _records.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddRecord,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                l10n.addMedicalRecordButton,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            l10n.noRecordsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            l10n.noRecordsDesc,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
            textAlign: TextAlign.center,
          ),
          if (!widget.isRegistration) ...[
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: _navigateToAddRecord,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addMedicalRecordButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingSm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordList(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: Row(
            children: [
              Text(
                '${_records.length} ${l10n.medicalRecordsTitle}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        ..._records.map(
          (record) => MedicalRecordCard(
            record: record,
            onOpen: () => _handleOpenRecord(record),
            onDelete: () => _handleDeleteRecord(record),
          ),
        ),
      ],
    );
  }
}
