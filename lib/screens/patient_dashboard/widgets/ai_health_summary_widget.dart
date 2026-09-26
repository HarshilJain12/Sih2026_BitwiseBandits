import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/medical_ai_analysis.dart';
import '../../../services/firestore/medical_record_service.dart';
import '../../../services/firestore/patient_ai_analysis_service.dart';
import '../../medical_records/widgets/document_viewer_dialog.dart';

/// Interactive UI section displaying Gemini-analyzed Health Summary and Health Tags.
///
/// Features:
/// - Real-time stream listening to `/patients/{patientId}/aiAnalysis/summary`.
/// - Automatic state management: `no_data`, `analyzing`, `completed`, `failed`.
/// - Interactive Health Tags that open an evidence & source trace sheet.
/// - Non-diagnostic safety disclaimer.
class AiHealthSummaryWidget extends StatelessWidget {
  const AiHealthSummaryWidget({
    super.key,
    required this.patientId,
    this.analysisService,
    this.recordService,
  });

  final String patientId;
  final PatientAiAnalysisService? analysisService;
  final MedicalRecordService? recordService;

  @override
  Widget build(BuildContext context) {
    final aiService = analysisService ??
        (context.read<PatientAiAnalysisService?>() ?? PatientAiAnalysisService());
    final recService = recordService ??
        (context.read<MedicalRecordService?>() ?? MedicalRecordService());

    return StreamBuilder<MedicalAiAnalysis>(
      stream: aiService.getAnalysisStream(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingCard(context);
        }

        final analysis = snapshot.data ??
            MedicalAiAnalysis.noData(patientId: patientId, ownerUid: '');

        switch (analysis.status) {
          case AnalysisStatus.no_data:
            return _buildNoDataCard(context);
          case AnalysisStatus.analyzing:
          case AnalysisStatus.pending:
            return _buildAnalyzingCard(context);
          case AnalysisStatus.failed:
            return _buildFailedCard(context, aiService, analysis);
          case AnalysisStatus.completed:
            return _buildCompletedCard(context, analysis, aiService, recService);
        }
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
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
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'AI Health Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
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
              'No previous medical records have been uploaded yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppColors.primaryContainer),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Text(
                'Analyzing your medical records with Gemini AI...',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedCard(
    BuildContext context,
    PatientAiAnalysisService aiService,
    MedicalAiAnalysis analysis,
  ) {
    return Card(
      elevation: 0,
      color: AppColors.errorContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppColors.errorContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'AI Analysis Notice',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              analysis.errorMessage ?? 'AI analysis could not be completed.',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: () => aiService.retryFailedAnalysis(patientId),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(
    BuildContext context,
    MedicalAiAnalysis analysis,
    PatientAiAnalysisService aiService,
    MedicalRecordService recService,
  ) {
    return Card(
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
            // ── Section Title & Badge ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      'AI Health Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Refresh AI Analysis',
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => aiService.reanalyzeAllRecords(patientId),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Health Tags ───────────────────────────────────────────────
            if (analysis.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: analysis.tags.map((tag) {
                  return _buildHealthTagChip(context, tag, recService);
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // ── Prominent Allergy Warning (For Doctor Safety) ─────────────
            if (analysis.allergies.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppColors.errorContainer),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Allergy Alert: ${analysis.allergies.map((a) => a.name).join(", ")}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],

            // ── AI Summary Text ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Summary & Key Highlights',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    analysis.summary,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Clinical Findings Accordions ──────────────────────────────
            if (analysis.conditions.isNotEmpty)
              _buildFindingSection(
                title: 'Documented Conditions',
                icon: Icons.healing_rounded,
                color: Colors.teal,
                items: analysis.conditions,
              ),

            if (analysis.surgeries.isNotEmpty)
              _buildFindingSection(
                title: 'Surgeries & Procedures',
                icon: Icons.local_hospital_rounded,
                color: Colors.amber.shade800,
                items: analysis.surgeries,
              ),

            if (analysis.medications.isNotEmpty)
              _buildFindingSection(
                title: 'Current Medications',
                icon: Icons.medication_rounded,
                color: Colors.indigo,
                items: analysis.medications,
              ),

            if (analysis.allergies.isNotEmpty)
              _buildFindingSection(
                title: 'Documented Allergies',
                icon: Icons.warning_amber_rounded,
                color: AppColors.error,
                items: analysis.allergies,
              ),

            if (analysis.importantFindings.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Important Clinical Findings',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              ...analysis.importantFindings.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.primary)),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Divider(height: 24),

            // ── Safety Disclaimer ─────────────────────────────────────────
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'AI-generated summary of uploaded medical records. This is not a medical diagnosis.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTagChip(
    BuildContext context,
    HealthTag tag,
    MedicalRecordService recService,
  ) {
    Color chipBg;
    Color chipText;
    Color chipBorder;

    switch (tag.category.toLowerCase()) {
      case 'surgery':
        chipBg = Colors.amber.shade50;
        chipText = Colors.amber.shade900;
        chipBorder = Colors.amber.shade200;
        break;
      case 'medication':
        chipBg = Colors.indigo.shade50;
        chipText = Colors.indigo.shade800;
        chipBorder = Colors.indigo.shade200;
        break;
      case 'allergy':
        chipBg = Colors.red.shade50;
        chipText = Colors.red.shade900;
        chipBorder = Colors.red.shade200;
        break;
      case 'condition':
      default:
        chipBg = AppColors.primaryContainer.withValues(alpha: 0.4);
        chipText = AppColors.primary;
        chipBorder = AppColors.primary.withValues(alpha: 0.3);
        break;
    }

    return ActionChip(
      onPressed: () => _showTagDetailsModal(context, tag, recService),
      backgroundColor: chipBg,
      side: BorderSide(color: chipBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      label: Text(
        tag.label,
        style: TextStyle(
          color: chipText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      avatar: Icon(
        Icons.touch_app_rounded,
        size: 14,
        color: chipText,
      ),
    );
  }

  Widget _buildFindingSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<MedicalFinding> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 22, top: 2, bottom: 2),
              child: Text(
                '${item.name} (${item.status}) — ${item.evidence}',
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTagDetailsModal(
    BuildContext context,
    HealthTag tag,
    MedicalRecordService recService,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tag.label,
                    style: Theme.of(bottomSheetContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              const Text(
                'Documented Evidence:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  tag.evidence.isNotEmpty
                      ? tag.evidence
                      : 'Factual finding derived from uploaded medical document.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              if (tag.sourceFileName != null)
                Text(
                  'Source: ${tag.sourceFileName} (${tag.sourceRecordId ?? ""})',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              const SizedBox(height: AppTheme.spacingLg),
              if (tag.sourceRecordId != null && tag.sourceRecordId!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(bottomSheetContext);
                    final records = await recService.getRecordsForPatient(patientId);
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
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('View Original Medical Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        );
      },
    );
  }
}
