import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/medical_ai_analysis.dart';

void main() {
  group('MedicalAiAnalysis Model Tests', () {
    test('1. HealthTag serialization and deserialization', () {
      final tag = HealthTag(
        label: 'Diabetes Mentioned',
        category: 'condition',
        evidence: 'Blood report indicates HbA1c 7.2%',
        sourceRecordId: 'REC-001',
        sourceFileName: 'blood_test.pdf',
        sourceRecordIds: ['REC-001'],
      );

      final map = tag.toMap();
      expect(map['label'], equals('Diabetes Mentioned'));
      expect(map['category'], equals('condition'));
      expect(map['evidence'], equals('Blood report indicates HbA1c 7.2%'));
      expect(map['sourceRecordId'], equals('REC-001'));
      expect(map['sourceFileName'], equals('blood_test.pdf'));
      expect(map['sourceRecordIds'], equals(['REC-001']));

      final fromMap = HealthTag.fromMap(map);
      expect(fromMap.label, equals(tag.label));
      expect(fromMap.category, equals(tag.category));
      expect(fromMap.evidence, equals(tag.evidence));
      expect(fromMap.sourceRecordId, equals(tag.sourceRecordId));
      expect(fromMap.sourceFileName, equals(tag.sourceFileName));
      expect(fromMap.sourceRecordIds, equals(tag.sourceRecordIds));
    });

    test('2. MedicalFinding serialization and deserialization', () {
      final finding = MedicalFinding(
        name: 'Metformin 500mg',
        status: 'active',
        evidence: 'Prescribed Metformin 500mg once daily',
        sourceRecordId: 'REC-002',
        sourceFileName: 'prescription.png',
      );

      final map = finding.toMap();
      expect(map['name'], equals('Metformin 500mg'));
      expect(map['status'], equals('active'));
      expect(map['evidence'], equals('Prescribed Metformin 500mg once daily'));
      expect(map['sourceRecordId'], equals('REC-002'));
      expect(map['sourceFileName'], equals('prescription.png'));

      final fromMap = MedicalFinding.fromMap(map);
      expect(fromMap.name, equals(finding.name));
      expect(fromMap.status, equals(finding.status));
      expect(fromMap.evidence, equals(finding.evidence));
      expect(fromMap.sourceRecordId, equals(finding.sourceRecordId));
      expect(fromMap.sourceFileName, equals(finding.sourceFileName));
    });

    test('3. MedicalAiAnalysis full serialization and deserialization', () {
      final now = DateTime(2026, 9, 20, 10, 0);
      final analysis = MedicalAiAnalysis(
        patientId: 'P-12345',
        ownerUid: 'uid_123',
        summary: 'Patient records mention diabetes and hypertension.',
        tags: [
          HealthTag(
            label: 'Diabetes Mentioned',
            category: 'condition',
            evidence: 'Elevated glucose',
            sourceRecordId: 'REC-1',
            sourceFileName: 'lab.pdf',
          ),
        ],
        conditions: [
          MedicalFinding(
            name: 'Diabetes Mentioned',
            status: 'documented',
            evidence: 'Elevated fasting blood sugar',
            sourceRecordId: 'REC-1',
            sourceFileName: 'lab.pdf',
          ),
        ],
        surgeries: [
          MedicalFinding(
            name: 'Appendectomy',
            status: 'past',
            evidence: 'History of appendectomy in 2018',
            sourceRecordId: 'REC-1',
            sourceFileName: 'lab.pdf',
          ),
        ],
        medications: [
          MedicalFinding(
            name: 'Metformin',
            status: 'active',
            evidence: 'Metformin daily',
            sourceRecordId: 'REC-1',
            sourceFileName: 'lab.pdf',
          ),
        ],
        allergies: [
          MedicalFinding(
            name: 'Penicillin Allergy',
            status: 'suspected',
            evidence: 'Patient reports mild rash to penicillin',
            sourceRecordId: 'REC-1',
            sourceFileName: 'lab.pdf',
          ),
        ],
        importantFindings: [
          'Elevated Fasting Glucose: 142 mg/dL',
        ],
        sourceRecordIds: ['REC-1'],
        analyzedRecordIds: ['REC-1'],
        recordFingerprints: {'REC-1': 'REC-1_1024_1700000000_path'},
        status: AnalysisStatus.completed,
        analysisVersion: 1,
        updatedAt: now,
        errorMessage: null,
      );

      final map = analysis.toMap();
      expect(map['patientId'], equals('P-12345'));
      expect(map['ownerUid'], equals('uid_123'));
      expect(map['status'], equals('completed'));
      expect((map['tags'] as List).length, equals(1));
      expect((map['conditions'] as List).length, equals(1));
      expect((map['surgeries'] as List).length, equals(1));
      expect((map['medications'] as List).length, equals(1));
      expect((map['allergies'] as List).length, equals(1));
      expect((map['importantFindings'] as List).length, equals(1));

      final restored = MedicalAiAnalysis.fromMap(map);
      expect(restored.patientId, equals(analysis.patientId));
      expect(restored.status, equals(AnalysisStatus.completed));
      expect(restored.tags.first.label, equals('Diabetes Mentioned'));
      expect(restored.surgeries.first.name, equals('Appendectomy'));
      expect(restored.medications.first.name, equals('Metformin'));
      expect(restored.allergies.first.name, equals('Penicillin Allergy'));
      expect(restored.importantFindings.first, equals('Elevated Fasting Glucose: 142 mg/dL'));
      expect(restored.recordFingerprints['REC-1'], equals('REC-1_1024_1700000000_path'));
    });

    test('4. MedicalAiAnalysis.noData factory creates valid empty state', () {
      final noData = MedicalAiAnalysis.noData(
        patientId: 'P-999',
        ownerUid: 'uid-999',
      );

      expect(noData.patientId, equals('P-999'));
      expect(noData.ownerUid, equals('uid-999'));
      expect(noData.status, equals(AnalysisStatus.no_data));
      expect(noData.tags.isEmpty, isTrue);
      expect(noData.conditions.isEmpty, isTrue);
      expect(noData.summary, contains('No previous medical records'));
    });

    test('5. Status transitions and copyWith functionality', () {
      final initial = MedicalAiAnalysis.noData(
        patientId: 'P-001',
        ownerUid: 'uid-001',
      );

      final analyzing = initial.copyWith(
        status: AnalysisStatus.analyzing,
      );
      expect(analyzing.status, equals(AnalysisStatus.analyzing));

      final failed = analyzing.copyWith(
        status: AnalysisStatus.failed,
        errorMessage: 'Connection timeout',
      );
      expect(failed.status, equals(AnalysisStatus.failed));
      expect(failed.errorMessage, equals('Connection timeout'));

      final completed = failed.copyWith(
        status: AnalysisStatus.completed,
        clearErrorMessage: true,
        summary: 'Analysis completed successfully.',
      );
      expect(completed.status, equals(AnalysisStatus.completed));
      expect(completed.errorMessage, isNull);
      expect(completed.summary, equals('Analysis completed successfully.'));
    });
  });
}
