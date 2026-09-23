import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/medical_ai_analysis.dart';
import '../../../models/patient.dart';
import '../../../services/firestore/medical_record_service.dart';
import '../../../services/firestore/patient_ai_analysis_service.dart';
import '../../medical_records/widgets/document_viewer_dialog.dart';

/// Doctor-facing component for viewing a patient's verified AI Health Summary & Tags.
///
/// Ensures every clinical finding is traceable to its source medical record.
class DoctorPatientAiSummaryView extends StatelessWidget {
  const DoctorPatientAiSummaryView({
    super.key,
    required this.patient,
    this.analysisService,
    this.recordService,
  });

  final Patient patient;
  final PatientAiAnalysisService? analysisService;
  final MedicalRecordService? recordService;

  @override
  Widget build(BuildContext context) {
    final aiService = analysisService ?? PatientAiAnalysisService();
    final recService = recordService ?? MedicalRecordService();

    return StreamBuilder<MedicalAiAnalysis>(
      stream: aiService.getAnalysisStream(patient.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final analysis = snapshot.data ??
            MedicalAiAnalysis.noData(patientId: patient.patientId, ownerUid: '');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Patient Header ───────────────────────────────────────────
              Card(
                elevation: 0,
                color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  side: const BorderSide(color: AppColors.secondaryContainer),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.secondary,
                        child: Icon(Icons.person_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Patient ID: ${patient.patientId}',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // ── AI Medical Summary ─────────────────────────────────────────
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.medical_services_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(
                            'AI Medical Insights & Summary',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMd),

                      if (analysis.hasNoData) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'No Previous Data',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        const Text(
                          'No medical records have been uploaded by this patient yet.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ] else ...[
                        // Health Tags
                        if (analysis.tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: analysis.tags.map((tag) {
                              return ActionChip(
                                onPressed: () => _showEvidenceDialog(context, tag, recService),
                                label: Text(tag.label),
                                avatar: const Icon(Icons.info_outline_rounded, size: 14),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                        ],

                        // Summary
                        Text(
                          analysis.summary,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),

                        // Documented Conditions
                        if (analysis.conditions.isNotEmpty) ...[
                          const Text(
                            'Documented Conditions:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          ...analysis.conditions.map(
                            (c) => Text('• ${c.name} (${c.status}) — ${c.evidence}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                        ],

                        // Surgeries
                        if (analysis.surgeries.isNotEmpty) ...[
                          const Text(
                            'Documented Surgeries & History:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          ...analysis.surgeries.map(
                            (s) => Text('• ${s.name} (${s.status}) — ${s.evidence}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                        ],

                        // Medications
                        if (analysis.medications.isNotEmpty) ...[
                          const Text(
                            'Documented Medications:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          ...analysis.medications.map(
                            (m) => Text('• ${m.name} — ${m.evidence}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                        ],

                        // Allergies
                        if (analysis.allergies.isNotEmpty) ...[
                          const Text(
                            'Documented Allergies:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...analysis.allergies.map(
                            (a) => Text('• ${a.name} — ${a.evidence}',
                                style: const TextStyle(fontSize: 12, color: AppColors.error)),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                        ],
                      ],

                      const Divider(height: 24),
                      const Text(
                        'Information extracted strictly from patient-provided documents. Clinical verification recommended.',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEvidenceDialog(
    BuildContext context,
    HealthTag tag,
    MedicalRecordService recService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tag.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documented Evidence:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(tag.evidence, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            if (tag.sourceFileName != null)
              Text(
                'Source File: ${tag.sourceFileName} (${tag.sourceRecordId ?? ""})',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (tag.sourceRecordId != null && tag.sourceRecordId!.isNotEmpty)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final records = await recService.getRecordsForPatient(patient.patientId);
                final matched = records
                    .where((r) => r.recordId == tag.sourceRecordId)
                    .firstOrNull;
                if (matched != null && context.mounted) {
                  DocumentViewerDialog.openRecord(
                    context: context,
                    record: matched,
                    service: recService,
                  );
                }
              },
              child: const Text('View Source Record'),
            ),
        ],
      ),
    );
  }
}
