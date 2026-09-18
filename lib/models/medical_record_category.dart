import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Supported medical document categories for patient uploads.
enum MedicalRecordCategory {
  prescription('prescription', '💊', Icons.medication_rounded),
  labReport('lab_report', '🧪', Icons.biotech_rounded),
  scanXray('scan_xray', '🩻', Icons.document_scanner_rounded),
  dischargeSummary('discharge_summary', '🏥', Icons.local_hospital_rounded),
  other('other', '📄', Icons.description_rounded);

  const MedicalRecordCategory(this.id, this.emoji, this.icon);

  final String id;
  final String emoji;
  final IconData icon;

  static MedicalRecordCategory fromId(String? id) {
    if (id == null) return MedicalRecordCategory.other;
    return MedicalRecordCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => MedicalRecordCategory.other,
    );
  }

  String getLocalizedTitle(AppLocalizations l10n) {
    switch (this) {
      case MedicalRecordCategory.prescription:
        return l10n.categoryPrescription;
      case MedicalRecordCategory.labReport:
        return l10n.categoryLabReport;
      case MedicalRecordCategory.scanXray:
        return l10n.categoryScanXray;
      case MedicalRecordCategory.dischargeSummary:
        return l10n.categoryDischargeSummary;
      case MedicalRecordCategory.other:
        return l10n.categoryOther;
    }
  }

  String getLocalizedSubtitle(AppLocalizations l10n) {
    switch (this) {
      case MedicalRecordCategory.prescription:
        return l10n.categoryPrescriptionDesc;
      case MedicalRecordCategory.labReport:
        return l10n.categoryLabReportDesc;
      case MedicalRecordCategory.scanXray:
        return l10n.categoryScanXrayDesc;
      case MedicalRecordCategory.dischargeSummary:
        return l10n.categoryDischargeSummaryDesc;
      case MedicalRecordCategory.other:
        return l10n.categoryOtherDesc;
    }
  }

  Color get accentColor {
    switch (this) {
      case MedicalRecordCategory.prescription:
        return const Color(0xFF0D7377);
      case MedicalRecordCategory.labReport:
        return const Color(0xFF2E7D32);
      case MedicalRecordCategory.scanXray:
        return const Color(0xFF1565C0);
      case MedicalRecordCategory.dischargeSummary:
        return const Color(0xFF6A1B9A);
      case MedicalRecordCategory.other:
        return const Color(0xFFE67E22);
    }
  }

  Color get containerColor {
    switch (this) {
      case MedicalRecordCategory.prescription:
        return AppColors.primaryContainer;
      case MedicalRecordCategory.labReport:
        return const Color(0xFFE8F5E9);
      case MedicalRecordCategory.scanXray:
        return const Color(0xFFE3F0FD);
      case MedicalRecordCategory.dischargeSummary:
        return const Color(0xFFF3E5F5);
      case MedicalRecordCategory.other:
        return const Color(0xFFFFF3CD);
    }
  }
}
