import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/medical_ai_analysis.dart';
import 'package:healthcare_app/models/medical_record.dart';
import 'package:healthcare_app/services/firestore/patient_ai_analysis_service.dart';

void main() {
  group('PatientAiAnalysisService Unit Tests', () {
    final recordA = MedicalRecord(
      recordId: 'REC-A',
      patientId: 'P-100',
      ownerUid: 'uid-100',
      category: 'lab_reports',
      originalFileName: 'report_a.pdf',
      fileSizeBytes: 4096,
      storagePath: 'patients/P-100/REC-A.pdf',
      mimeType: 'application/pdf',
      uploadedAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    final recordB = MedicalRecord(
      recordId: 'REC-B',
      patientId: 'P-100',
      ownerUid: 'uid-100',
      category: 'prescriptions',
      originalFileName: 'rx_b.pdf',
      fileSizeBytes: 2048,
      storagePath: 'patients/P-100/REC-B.pdf',
      mimeType: 'application/pdf',
      uploadedAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

    test('1. computeFingerprint generates deterministic key based on record metadata', () {
      final fp1 = PatientAiAnalysisService.computeFingerprint(recordA);
      final fp2 = PatientAiAnalysisService.computeFingerprint(recordA);

      expect(fp1, equals(fp2));
      expect(fp1, contains('REC-A'));
      expect(fp1, contains('4096'));

      // If updatedAt or size changes, fingerprint changes
      final modifiedRecordA = recordA.copyWith(fileSizeBytes: 5000);
      final fpModified = PatientAiAnalysisService.computeFingerprint(modifiedRecordA);
      expect(fp1, isNot(equals(fpModified)));
    });

    test('2. MedicalAiAnalysis.noData creates valid baseline when 0 records exist', () {
      final analysis = MedicalAiAnalysis.noData(
        patientId: 'P-EMPTY',
        ownerUid: 'uid-empty',
      );

      expect(analysis.status, equals(AnalysisStatus.no_data));
      expect(analysis.hasNoData, isTrue);
      expect(analysis.tags, isEmpty);
      expect(analysis.conditions, isEmpty);
      expect(analysis.sourceRecordIds, isEmpty);
      expect(analysis.summary, contains('No previous medical records'));
    });

    test('3. Tag deduplication merges duplicate conditions into one tag with all source IDs preserved', () {
      final tag1 = HealthTag(
        label: 'Diabetes Mentioned',
        category: 'condition',
        evidence: 'Report A shows elevated fasting blood sugar',
        sourceRecordId: 'REC-A',
        sourceFileName: 'report_a.pdf',
        sourceRecordIds: ['REC-A'],
      );

      final tag2 = HealthTag(
        label: 'Diabetes Mentioned',
        category: 'condition',
        evidence: 'Prescription B lists Metformin for glucose control',
        sourceRecordId: 'REC-B',
        sourceFileName: 'rx_b.pdf',
        sourceRecordIds: ['REC-B'],
      );

      // Merge logic simulation
      final tags = <HealthTag>[tag1];
      final idx = tags.indexWhere((t) => t.label.toLowerCase() == tag2.label.toLowerCase());
      expect(idx, equals(0));

      final mergedTag = tags[idx].copyWith(
        sourceRecordIds: <String>{...tags[idx].allSourceRecordIds, ...tag2.allSourceRecordIds}.toList(),
        evidence: '${tags[idx].evidence}\n${tag2.evidence}',
      );

      expect(mergedTag.label, equals('Diabetes Mentioned'));
      expect(mergedTag.allSourceRecordIds, containsAll(['REC-A', 'REC-B']));
      expect(mergedTag.evidence, contains('Report A'));
      expect(mergedTag.evidence, contains('Prescription B'));
    });

    test('4. Conflicting information is preserved with individual source references', () {
      final allergy1 = MedicalFinding(
        name: 'No Known Drug Allergies',
        status: 'documented',
        evidence: 'Intake form says NKDA',
        sourceRecordId: 'REC-A',
        sourceFileName: 'report_a.pdf',
      );

      final allergy2 = MedicalFinding(
        name: 'Penicillin Allergy',
        status: 'suspected',
        evidence: 'Prescription notes mild reaction to Penicillin',
        sourceRecordId: 'REC-B',
        sourceFileName: 'rx_b.pdf',
      );

      final analysis = MedicalAiAnalysis(
        patientId: 'P-100',
        ownerUid: 'uid-100',
        summary: 'Allergy records indicate possible conflict between NKDA and Penicillin reaction.',
        tags: [
          HealthTag(
            label: 'Penicillin Allergy Suspected',
            category: 'allergy',
            evidence: 'Prescription notes mild reaction',
            sourceRecordId: 'REC-B',
            sourceFileName: 'rx_b.pdf',
          ),
        ],
        allergies: [allergy1, allergy2],
        sourceRecordIds: ['REC-A', 'REC-B'],
        status: AnalysisStatus.completed,
        updatedAt: DateTime.now(),
      );

      expect(analysis.allergies.length, equals(2));
      expect(analysis.allergies.any((a) => a.sourceRecordId == 'REC-A'), isTrue);
      expect(analysis.allergies.any((a) => a.sourceRecordId == 'REC-B'), isTrue);
      expect(analysis.allergies.first.evidence, contains('NKDA'));
      expect(analysis.allergies.last.evidence, contains('Penicillin'));
    });

    test('5. Deletion updates analysis and filters out findings from deleted record', () {
      final findingA = MedicalFinding(
        name: 'High Cholesterol Mentioned',
        status: 'documented',
        evidence: 'Lipid panel elevated',
        sourceRecordId: 'REC-A',
        sourceFileName: 'report_a.pdf',
      );

      final findingB = MedicalFinding(
        name: 'Hypertension Mentioned',
        status: 'documented',
        evidence: 'Blood pressure 140/90',
        sourceRecordId: 'REC-B',
        sourceFileName: 'rx_b.pdf',
      );

      final initialAnalysis = MedicalAiAnalysis(
        patientId: 'P-100',
        ownerUid: 'uid-100',
        summary: 'Patient has cholesterol and hypertension noted.',
        conditions: [findingA, findingB],
        sourceRecordIds: ['REC-A', 'REC-B'],
        status: AnalysisStatus.completed,
        updatedAt: DateTime.now(),
      );

      // Simulate deleting REC-A
      const deletedId = 'REC-A';
      final remainingConditions = initialAnalysis.conditions
          .where((c) => c.sourceRecordId != deletedId)
          .toList();

      final updatedAnalysis = initialAnalysis.copyWith(
        conditions: remainingConditions,
        sourceRecordIds: ['REC-B'],
      );

      expect(updatedAnalysis.conditions.length, equals(1));
      expect(updatedAnalysis.conditions.first.name, equals('Hypertension Mentioned'));
      expect(updatedAnalysis.sourceRecordIds, equals(['REC-B']));
      expect(recordB.recordId, equals('REC-B'));
    });
  });
}
