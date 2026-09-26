import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/medical_ai_analysis.dart';
import 'package:healthcare_app/screens/patient_dashboard/widgets/ai_health_summary_widget.dart';
import 'package:healthcare_app/services/firestore/patient_ai_analysis_service.dart';

class FakePatientAiAnalysisService extends PatientAiAnalysisService {
  FakePatientAiAnalysisService(this.streamController);

  final StreamController<MedicalAiAnalysis> streamController;
  bool retryCalled = false;
  bool reanalyzeCalled = false;

  @override
  Stream<MedicalAiAnalysis> getAnalysisStream(String patientId) {
    return streamController.stream;
  }

  @override
  Future<MedicalAiAnalysis> retryFailedAnalysis(String patientId) async {
    retryCalled = true;
    return MedicalAiAnalysis.noData(patientId: patientId, ownerUid: 'uid');
  }

  @override
  Future<MedicalAiAnalysis> reanalyzeAllRecords(String patientId) async {
    reanalyzeCalled = true;
    return MedicalAiAnalysis.noData(patientId: patientId, ownerUid: 'uid');
  }
}

void main() {
  group('AiHealthSummaryWidget Tests', () {
    late StreamController<MedicalAiAnalysis> controller;
    late FakePatientAiAnalysisService fakeService;

    setUp(() {
      controller = StreamController<MedicalAiAnalysis>.broadcast();
      fakeService = FakePatientAiAnalysisService(controller);
    });

    tearDown(() {
      controller.close();
    });

    testWidgets('1. no_data state renders No Previous Data banner correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiHealthSummaryWidget(
              patientId: 'P-101',
              analysisService: fakeService,
            ),
          ),
        ),
      );

      controller.add(MedicalAiAnalysis.noData(patientId: 'P-101', ownerUid: 'uid'));
      await tester.pumpAndSettle();

      expect(find.text('AI Health Summary'), findsOneWidget);
      expect(find.text('No Previous Data'), findsOneWidget);
      expect(
        find.text('No previous medical records have been uploaded yet.'),
        findsOneWidget,
      );
    });

    testWidgets('2. analyzing state renders progress indicator and analyzing text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiHealthSummaryWidget(
              patientId: 'P-101',
              analysisService: fakeService,
            ),
          ),
        ),
      );

      controller.add(
        MedicalAiAnalysis(
          patientId: 'P-101',
          ownerUid: 'uid',
          status: AnalysisStatus.analyzing,
          summary: 'Analyzing records...',
          updatedAt: DateTime.now(),
        ),
      );
      await tester.pump();

      expect(
        find.text('Analyzing your medical records with Gemini AI...'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('3. failed state renders error notice and clickable retry button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiHealthSummaryWidget(
              patientId: 'P-101',
              analysisService: fakeService,
            ),
          ),
        ),
      );

      controller.add(
        MedicalAiAnalysis(
          patientId: 'P-101',
          ownerUid: 'uid',
          status: AnalysisStatus.failed,
          summary: '',
          updatedAt: DateTime.now(),
          errorMessage: 'Gemini rate limit exceeded.',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Analysis Notice'), findsOneWidget);
      expect(find.text('Gemini rate limit exceeded.'), findsOneWidget);
      expect(find.text('Retry Analysis'), findsOneWidget);

      await tester.tap(find.text('Retry Analysis'));
      expect(fakeService.retryCalled, isTrue);
    });

    testWidgets('4. completed state renders tags, summary, findings, and disclaimer', (tester) async {
      final analysis = MedicalAiAnalysis(
        patientId: 'P-101',
        ownerUid: 'uid',
        status: AnalysisStatus.completed,
        summary: 'Blood test mentions elevated HbA1c and daily Metformin.',
        updatedAt: DateTime.now(),
        tags: [
          HealthTag(
            label: 'Diabetes Mentioned',
            category: 'condition',
            evidence: 'HbA1c 7.4%',
            sourceRecordId: 'REC-01',
            sourceFileName: 'lab_test.pdf',
          ),
        ],
        conditions: [
          MedicalFinding(
            name: 'Diabetes Mentioned',
            status: 'documented',
            evidence: 'Elevated fasting blood sugar',
            sourceRecordId: 'REC-01',
            sourceFileName: 'lab_test.pdf',
          ),
        ],
        medications: [
          MedicalFinding(
            name: 'Metformin 500mg',
            status: 'active',
            evidence: 'Metformin 500mg daily',
            sourceRecordId: 'REC-01',
            sourceFileName: 'lab_test.pdf',
          ),
        ],
        importantFindings: ['HbA1c 7.4% fasting test result'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiHealthSummaryWidget(
                patientId: 'P-101',
                analysisService: fakeService,
              ),
            ),
          ),
        ),
      );

      controller.add(analysis);
      await tester.pumpAndSettle();

      expect(find.text('Diabetes Mentioned'), findsWidgets);
      expect(find.text('Summary & Key Highlights'), findsOneWidget);
      expect(find.textContaining('elevated HbA1c and daily Metformin'), findsOneWidget);
      expect(find.text('Documented Conditions'), findsOneWidget);
      expect(find.text('Current Medications'), findsOneWidget);
      expect(find.text('Important Clinical Findings'), findsOneWidget);
      expect(
        find.textContaining('This is not a medical diagnosis.'),
        findsOneWidget,
      );

      // Tap on Health Tag chip to open evidence modal
      await tester.tap(find.widgetWithText(ActionChip, 'Diabetes Mentioned'));
      await tester.pumpAndSettle();

      expect(find.text('Documented Evidence:'), findsOneWidget);
      expect(find.text('HbA1c 7.4%'), findsOneWidget);
      expect(find.textContaining('lab_test.pdf'), findsOneWidget);
    });
  });
}
