import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/medical_ai_analysis.dart';
import '../../models/medical_record.dart';
import '../ai/gemini_medical_analysis_service.dart';
import '../storage/medical_record_storage.dart';
import '../storage/supabase_medical_record_storage.dart';
import 'medical_record_service.dart';

/// Coordinates Firestore AI Analysis documents and incremental analysis workflows.
///
/// Firestore Location:
/// `/patients/{patientId}/aiAnalysis/summary`
class PatientAiAnalysisService {
  PatientAiAnalysisService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    MedicalRecordService? recordService,
    MedicalRecordStorage? storage,
    GeminiMedicalAnalysisService? geminiService,
  })  : _customFirestore = firestore,
        _customAuth = auth,
        _recordService = recordService ??
            MedicalRecordService(firestore: firestore, auth: auth),
        _storage = storage ?? SupabaseMedicalRecordStorage(),
        _geminiService = geminiService ?? GeminiMedicalAnalysisService();

  static final PatientAiAnalysisService instance = PatientAiAnalysisService();

  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;
  final MedicalRecordService _recordService;
  final MedicalRecordStorage _storage;
  final GeminiMedicalAnalysisService _geminiService;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>>? _summaryDocRef(String patientId) {
    final firestore = _firestore;
    if (firestore == null) return null;
    return firestore
        .collection('patients')
        .doc(patientId)
        .collection('aiAnalysis')
        .doc('summary');
  }

  /// Real-time stream of the patient's AI Analysis summary document.
  Stream<MedicalAiAnalysis> getAnalysisStream(String patientId) {
    final docRef = _summaryDocRef(patientId);
    if (docRef == null) {
      return Stream.value(
        MedicalAiAnalysis.noData(patientId: patientId, ownerUid: ''),
      );
    }
    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return MedicalAiAnalysis.noData(
          patientId: patientId,
          ownerUid: _auth?.currentUser?.uid ?? '',
        );
      }
      return MedicalAiAnalysis.fromFirestore(
        snapshot,
        fallbackPatientId: patientId,
        fallbackOwnerUid: _auth?.currentUser?.uid ?? '',
      );
    }).transform(
      StreamTransformer<MedicalAiAnalysis, MedicalAiAnalysis>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
        handleError: (error, stackTrace, sink) {
          if (kDebugMode) {
            debugPrint('[PatientAiAnalysisService] Stream error for $patientId: $error');
          }
          sink.add(
            MedicalAiAnalysis.noData(
              patientId: patientId,
              ownerUid: _auth?.currentUser?.uid ?? '',
            ),
          );
        },
      ),
    );
  }

  /// Fetches the current AI analysis for a patient.
  Future<MedicalAiAnalysis> getAnalysis(String patientId) async {
    final docRef = _summaryDocRef(patientId);
    if (docRef == null) {
      return MedicalAiAnalysis.noData(
        patientId: patientId,
        ownerUid: _auth?.currentUser?.uid ?? '',
      );
    }
    try {
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        return MedicalAiAnalysis.noData(
          patientId: patientId,
          ownerUid: _auth?.currentUser?.uid ?? '',
        );
      }
      return MedicalAiAnalysis.fromFirestore(
        doc,
        fallbackPatientId: patientId,
        fallbackOwnerUid: _auth?.currentUser?.uid ?? '',
      );
    } catch (_) {
      return MedicalAiAnalysis.noData(
        patientId: patientId,
        ownerUid: _auth?.currentUser?.uid ?? '',
      );
    }
  }

  /// Deterministic fingerprint for a medical record file to prevent duplicate Gemini calls.
  static String computeFingerprint(MedicalRecord record) {
    return '${record.recordId}_${record.fileSizeBytes}_${record.updatedAt.millisecondsSinceEpoch}';
  }

  /// Incremental analysis: Analyzes a newly uploaded [record] and merges findings into summary.
  Future<MedicalAiAnalysis> analyzeNewRecord({
    required String patientId,
    required MedicalRecord record,
  }) async {
    final user = _auth?.currentUser;
    final uid = user?.uid ?? record.ownerUid;

    // 1. Mark status as analyzing in Firestore
    final currentAnalysis = await getAnalysis(patientId);
    final analyzingState = currentAnalysis.copyWith(
      patientId: patientId,
      ownerUid: uid,
      status: AnalysisStatus.analyzing,
      updatedAt: DateTime.now(),
      errorMessage: null,
    );
    await _saveAnalysis(analyzingState);

    try {
      // 2. Fetch file bytes securely from storage
      final bytes = await _storage.getFileBytes(record.storagePath);
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Unable to retrieve document bytes for ${record.storagePath}');
      }

      // 3. Process document with Gemini
      final docResult = await _geminiService.analyzeDocument(
        record: record,
        fileBytes: bytes,
      );

      // 4. Compute fingerprint
      final fingerprint = computeFingerprint(record);
      final updatedFingerprints = Map<String, String>.from(currentAnalysis.recordFingerprints)
        ..[record.recordId] = fingerprint;

      // 5. Merge findings
      final merged = _mergeSingleResultIntoAnalysis(
        baseAnalysis: currentAnalysis,
        newResult: docResult,
        patientId: patientId,
        ownerUid: uid,
        updatedFingerprints: updatedFingerprints,
      );

      await _saveAnalysis(merged);
      return merged;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientAiAnalysisService] Failed analyzing new record ${record.recordId}: $e');
      }
      final failedState = currentAnalysis.copyWith(
        status: AnalysisStatus.failed,
        updatedAt: DateTime.now(),
        errorMessage: 'AI analysis could not be completed for ${record.originalFileName}.',
      );
      await _saveAnalysis(failedState);
      return failedState;
    }
  }

  /// Checks all medical records for a patient and analyzes any unanalyzed/changed records.
  Future<MedicalAiAnalysis> analyzePatientRecords(String patientId) async {
    final user = _auth?.currentUser;
    final uid = user?.uid ?? '';

    // 1. Fetch current active medical records
    final records = await _recordService.getRecordsForPatient(patientId);

    // Scenario B: No medical records
    if (records.isEmpty) {
      final noDataAnalysis = MedicalAiAnalysis.noData(
        patientId: patientId,
        ownerUid: uid,
      );
      await _saveAnalysis(noDataAnalysis);
      return noDataAnalysis;
    }

    final currentAnalysis = await getAnalysis(patientId);
    final activeFingerprints = <String, String>{};
    final recordsToAnalyze = <MedicalRecord>[];

    for (final r in records) {
      final fp = computeFingerprint(r);
      activeFingerprints[r.recordId] = fp;

      final previousFp = currentAnalysis.recordFingerprints[r.recordId];
      if (previousFp != fp || !currentAnalysis.analyzedRecordIds.contains(r.recordId)) {
        recordsToAnalyze.add(r);
      }
    }

    // If all records are already analyzed and unchanged, reuse existing analysis
    if (recordsToAnalyze.isEmpty && currentAnalysis.status == AnalysisStatus.completed) {
      return currentAnalysis;
    }

    // Set status to analyzing
    await _saveAnalysis(
      currentAnalysis.copyWith(
        patientId: patientId,
        ownerUid: uid,
        status: AnalysisStatus.analyzing,
        updatedAt: DateTime.now(),
        errorMessage: null,
      ),
    );

    try {
      final docResults = <SingleDocumentAnalysisResult>[];

      for (final r in records) {
        final bytes = await _storage.getFileBytes(r.storagePath);
        if (bytes != null && bytes.isNotEmpty) {
          final res = await _geminiService.analyzeDocument(
            record: r,
            fileBytes: bytes,
          );
          docResults.add(res);
        }
      }

      final combined = _combineAllDocumentResults(
        docResults: docResults,
        patientId: patientId,
        ownerUid: uid,
        fingerprints: activeFingerprints,
      );

      await _saveAnalysis(combined);
      return combined;
    } catch (e) {
      final failedState = currentAnalysis.copyWith(
        status: AnalysisStatus.failed,
        updatedAt: DateTime.now(),
        errorMessage: 'AI analysis could not be completed.',
      );
      await _saveAnalysis(failedState);
      return failedState;
    }
  }

  /// Retries failed or unprocessed analysis for a patient.
  Future<MedicalAiAnalysis> retryFailedAnalysis(String patientId) async {
    return analyzePatientRecords(patientId);
  }

  /// Forces a complete re-analysis of all records for a patient.
  Future<MedicalAiAnalysis> reanalyzeAllRecords(String patientId) async {
    final user = _auth?.currentUser;
    final uid = user?.uid ?? '';
    final clearedState = MedicalAiAnalysis(
      patientId: patientId,
      ownerUid: uid,
      summary: 'Preparing full re-analysis...',
      status: AnalysisStatus.analyzing,
      updatedAt: DateTime.now(),
    );
    await _saveAnalysis(clearedState);
    return analyzePatientRecords(patientId);
  }

  /// Handles deletion of a medical record by removing findings supported ONLY by that record.
  Future<MedicalAiAnalysis> handleRecordDeletion({
    required String patientId,
    required String deletedRecordId,
  }) async {
    final records = await _recordService.getRecordsForPatient(patientId);
    if (records.isEmpty) {
      final user = _auth?.currentUser;
      final noData = MedicalAiAnalysis.noData(
        patientId: patientId,
        ownerUid: user?.uid ?? '',
      );
      await _saveAnalysis(noData);
      return noData;
    }

    // Re-aggregate findings from remaining active records
    return analyzePatientRecords(patientId);
  }

  Future<void> _saveAnalysis(MedicalAiAnalysis analysis) async {
    final docRef = _summaryDocRef(analysis.patientId);
    if (docRef == null) return;
    await docRef.set(
      analysis.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Merges a single document result into existing analysis.
  MedicalAiAnalysis _mergeSingleResultIntoAnalysis({
    required MedicalAiAnalysis baseAnalysis,
    required SingleDocumentAnalysisResult newResult,
    required String patientId,
    required String ownerUid,
    required Map<String, String> updatedFingerprints,
  }) {
    final existingTags = List<HealthTag>.from(
      baseAnalysis.hasNoData ? [] : baseAnalysis.tags,
    );

    // Merge tags: deduplicate by lowercased label while combining sourceRecordIds
    for (final newTag in newResult.tags) {
      final index = existingTags.indexWhere(
        (t) => t.label.toLowerCase().trim() == newTag.label.toLowerCase().trim(),
      );
      if (index >= 0) {
        final existing = existingTags[index];
        final combinedSources = <String>{
          ...existing.allSourceRecordIds,
          ...newTag.allSourceRecordIds,
        }.toList();

        existingTags[index] = existing.copyWith(
          sourceRecordIds: combinedSources,
          evidence: '${existing.evidence}\n${newTag.evidence}'.trim(),
        );
      } else {
        existingTags.add(newTag);
      }
    }

    final allSources = <String>{
      ...baseAnalysis.sourceRecordIds,
      newResult.recordId,
    }.toList();

    final allAnalyzed = <String>{
      ...baseAnalysis.analyzedRecordIds,
      newResult.recordId,
    }.toList();

    final allConditions = [
      ...baseAnalysis.conditions.where((c) => c.sourceRecordId != newResult.recordId),
      ...newResult.conditions,
    ];

    final allSurgeries = [
      ...baseAnalysis.surgeries.where((s) => s.sourceRecordId != newResult.recordId),
      ...newResult.surgeries,
    ];

    final allMeds = [
      ...baseAnalysis.medications.where((m) => m.sourceRecordId != newResult.recordId),
      ...newResult.medications,
    ];

    final allAllergies = [
      ...baseAnalysis.allergies.where((a) => a.sourceRecordId != newResult.recordId),
      ...newResult.allergies,
    ];

    final allFindings = <String>{
      ...baseAnalysis.importantFindings,
      ...newResult.importantFindings,
    }.toList();

    // Generate comprehensive combined summary
    final combinedSummary = _synthesizeSummary(
      docSummaries: [
        if (!baseAnalysis.hasNoData && baseAnalysis.summary.isNotEmpty) baseAnalysis.summary,
        if (newResult.summary.isNotEmpty) newResult.summary,
      ],
      conditions: allConditions,
      allergies: allAllergies,
      medications: allMeds,
      surgeries: allSurgeries,
      findings: allFindings,
    );

    return MedicalAiAnalysis(
      patientId: patientId,
      ownerUid: ownerUid,
      summary: combinedSummary,
      tags: existingTags,
      conditions: allConditions,
      surgeries: allSurgeries,
      medications: allMeds,
      allergies: allAllergies,
      importantFindings: allFindings,
      sourceRecordIds: allSources,
      analyzedRecordIds: allAnalyzed,
      recordFingerprints: updatedFingerprints,
      status: AnalysisStatus.completed,
      analysisVersion: baseAnalysis.analysisVersion + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Combines results from all documents into a unified analysis.
  MedicalAiAnalysis _combineAllDocumentResults({
    required List<SingleDocumentAnalysisResult> docResults,
    required String patientId,
    required String ownerUid,
    required Map<String, String> fingerprints,
  }) {
    if (docResults.isEmpty) {
      return MedicalAiAnalysis.noData(
        patientId: patientId,
        ownerUid: ownerUid,
      );
    }

    final mergedTags = <HealthTag>[];
    final allConditions = <MedicalFinding>[];
    final allSurgeries = <MedicalFinding>[];
    final allMeds = <MedicalFinding>[];
    final allAllergies = <MedicalFinding>[];
    final allFindings = <String>{};
    final sourceIds = <String>{};

    for (final doc in docResults) {
      sourceIds.add(doc.recordId);

      for (final t in doc.tags) {
        final idx = mergedTags.indexWhere(
          (m) => m.label.toLowerCase().trim() == t.label.toLowerCase().trim(),
        );
        if (idx >= 0) {
          final existing = mergedTags[idx];
          final combined = <String>{
            ...existing.allSourceRecordIds,
            ...t.allSourceRecordIds,
          }.toList();
          mergedTags[idx] = existing.copyWith(
            sourceRecordIds: combined,
            evidence: '${existing.evidence}\n${t.evidence}'.trim(),
          );
        } else {
          mergedTags.add(t);
        }
      }

      allConditions.addAll(doc.conditions);
      allSurgeries.addAll(doc.surgeries);
      allMeds.addAll(doc.medications);
      allAllergies.addAll(doc.allergies);
      allFindings.addAll(doc.importantFindings);
    }

    final combinedSummary = _synthesizeSummary(
      docSummaries: docResults.map((d) => d.summary).toList(),
      conditions: allConditions,
      allergies: allAllergies,
      medications: allMeds,
      surgeries: allSurgeries,
      findings: allFindings.toList(),
    );

    return MedicalAiAnalysis(
      patientId: patientId,
      ownerUid: ownerUid,
      summary: combinedSummary,
      tags: mergedTags,
      conditions: allConditions,
      surgeries: allSurgeries,
      medications: allMeds,
      allergies: allAllergies,
      importantFindings: allFindings.toList(),
      sourceRecordIds: sourceIds.toList(),
      analyzedRecordIds: sourceIds.toList(),
      recordFingerprints: fingerprints,
      status: AnalysisStatus.completed,
      analysisVersion: 1,
      updatedAt: DateTime.now(),
    );
  }

  static String _synthesizeSummary({
    required List<String> docSummaries,
    required List<MedicalFinding> conditions,
    required List<MedicalFinding> allergies,
    required List<MedicalFinding> medications,
    required List<MedicalFinding> surgeries,
    required List<String> findings,
  }) {
    final clean = docSummaries
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (clean.length == 1) {
      return clean.first;
    }

    if (clean.isNotEmpty) {
      return clean.join('\n\n');
    }

    final parts = <String>[];
    if (conditions.isNotEmpty) {
      final names = conditions.map((c) => c.name).toSet().join(', ');
      parts.add('Documented conditions on record: $names.');
    }
    if (allergies.isNotEmpty) {
      final names = allergies.map((a) => a.name).toSet().join(', ');
      parts.add('Allergy alert: $names.');
    }
    if (medications.isNotEmpty) {
      final names = medications.map((m) => m.name).toSet().join(', ');
      parts.add('Active medications: $names.');
    }
    if (surgeries.isNotEmpty) {
      final names = surgeries.map((s) => s.name).toSet().join(', ');
      parts.add('Past surgical history: $names.');
    }
    if (parts.isEmpty) {
      return 'Medical records are uploaded and available on file.';
    }
    return parts.join(' ');
  }
}
