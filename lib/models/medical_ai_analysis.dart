import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle and processing status for Patient AI Medical Record Analysis.
enum AnalysisStatus {
  // ignore: constant_identifier_names
  no_data,
  pending,
  analyzing,
  completed,
  failed;

  static AnalysisStatus fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'no_data':
        return AnalysisStatus.no_data;
      case 'pending':
        return AnalysisStatus.pending;
      case 'analyzing':
        return AnalysisStatus.analyzing;
      case 'completed':
        return AnalysisStatus.completed;
      case 'failed':
        return AnalysisStatus.failed;
      default:
        return AnalysisStatus.no_data;
    }
  }

  String toValue() => name;
}

/// Concise, clinically relevant tag extracted strictly from uploaded medical records.
class HealthTag {
  const HealthTag({
    required this.label,
    this.category = 'condition',
    required this.evidence,
    this.sourceRecordId,
    this.sourceFileName,
    this.sourceRecordIds = const [],
  });

  /// Human-readable label (e.g., "Diabetes Mentioned", "Cardiac History", "No Previous Data").
  final String label;

  /// Clinical category: `'condition'`, `'surgery'`, `'medication'`, `'allergy'`, `'test'`, `'general'`.
  final String category;

  /// Traceable factual evidence excerpt from the document.
  final String evidence;

  /// Primary source record ID (e.g., "MR-XXXXXXXXXX").
  final String? sourceRecordId;

  /// Original filename of the source document (e.g., "discharge_summary.pdf").
  final String? sourceFileName;

  /// All record IDs supporting this tag (for merged multi-document findings).
  final List<String> sourceRecordIds;

  List<String> get allSourceRecordIds {
    final ids = <String>{};
    if (sourceRecordId != null && sourceRecordId!.isNotEmpty) {
      ids.add(sourceRecordId!);
    }
    ids.addAll(sourceRecordIds);
    return ids.toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'category': category,
      'evidence': evidence,
      'sourceRecordId': sourceRecordId,
      'sourceFileName': sourceFileName,
      'sourceRecordIds': allSourceRecordIds,
    };
  }

  factory HealthTag.fromMap(Map<String, dynamic> map) {
    final rawList = map['sourceRecordIds'] as List<dynamic>?;
    final ids = rawList?.map((e) => e.toString()).toList() ?? [];

    return HealthTag(
      label: map['label'] as String? ?? '',
      category: map['category'] as String? ?? 'condition',
      evidence: map['evidence'] as String? ?? '',
      sourceRecordId: map['sourceRecordId'] as String?,
      sourceFileName: map['sourceFileName'] as String?,
      sourceRecordIds: ids,
    );
  }

  HealthTag copyWith({
    String? label,
    String? category,
    String? evidence,
    String? sourceRecordId,
    String? sourceFileName,
    List<String>? sourceRecordIds,
  }) {
    return HealthTag(
      label: label ?? this.label,
      category: category ?? this.category,
      evidence: evidence ?? this.evidence,
      sourceRecordId: sourceRecordId ?? this.sourceRecordId,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      sourceRecordIds: sourceRecordIds ?? this.sourceRecordIds,
    );
  }
}

/// Structured medical finding item (condition, surgery, medication, allergy).
class MedicalFinding {
  const MedicalFinding({
    required this.name,
    this.status = 'documented',
    required this.evidence,
    this.sourceRecordId,
    this.sourceFileName,
  });

  /// Name of the medical condition, surgery, medication, or allergy.
  final String name;

  /// Clinical status: `'documented'`, `'history'`, `'possible'`, `'suspected'`, `'normal'`.
  final String status;

  /// Concrete evidence quote/excerpt from the uploaded document.
  final String evidence;

  /// Source record ID.
  final String? sourceRecordId;

  /// Source document filename.
  final String? sourceFileName;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'status': status,
      'evidence': evidence,
      'sourceRecordId': sourceRecordId,
      'sourceFileName': sourceFileName,
    };
  }

  factory MedicalFinding.fromMap(Map<String, dynamic> map) {
    return MedicalFinding(
      name: map['name'] as String? ?? '',
      status: map['status'] as String? ?? 'documented',
      evidence: map['evidence'] as String? ?? '',
      sourceRecordId: map['sourceRecordId'] as String?,
      sourceFileName: map['sourceFileName'] as String?,
    );
  }
}

/// Complete patient AI analysis document stored at `/patients/{patientId}/aiAnalysis/summary`.
class MedicalAiAnalysis {
  const MedicalAiAnalysis({
    required this.patientId,
    required this.ownerUid,
    required this.summary,
    this.tags = const [],
    this.conditions = const [],
    this.surgeries = const [],
    this.medications = const [],
    this.allergies = const [],
    this.importantFindings = const [],
    this.sourceRecordIds = const [],
    this.analyzedRecordIds = const [],
    this.recordFingerprints = const {},
    this.status = AnalysisStatus.no_data,
    this.analysisVersion = 1,
    required this.updatedAt,
    this.errorMessage,
  });

  final String patientId;
  final String ownerUid;
  final String summary;
  final List<HealthTag> tags;
  final List<MedicalFinding> conditions;
  final List<MedicalFinding> surgeries;
  final List<MedicalFinding> medications;
  final List<MedicalFinding> allergies;
  final List<String> importantFindings;
  final List<String> sourceRecordIds;
  final List<String> analyzedRecordIds;
  final Map<String, String> recordFingerprints;
  final AnalysisStatus status;
  final int analysisVersion;
  final DateTime updatedAt;
  final String? errorMessage;

  /// Whether the patient has no previous medical records.
  bool get hasNoData => status == AnalysisStatus.no_data || analyzedRecordIds.isEmpty;

  /// Factory for a patient with zero uploaded medical records.
  factory MedicalAiAnalysis.noData({
    required String patientId,
    required String ownerUid,
  }) {
    return MedicalAiAnalysis(
      patientId: patientId,
      ownerUid: ownerUid,
      summary: 'No previous medical records have been uploaded yet.',
      tags: const [],
      conditions: const [],
      surgeries: const [],
      medications: const [],
      allergies: const [],
      importantFindings: const [],
      sourceRecordIds: const [],
      analyzedRecordIds: const [],
      recordFingerprints: const {},
      status: AnalysisStatus.no_data,
      analysisVersion: 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a [MedicalAiAnalysis] from a Firestore [DocumentSnapshot].
  factory MedicalAiAnalysis.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    String? fallbackPatientId,
    String? fallbackOwnerUid,
  }) {
    final data = snapshot.data();
    if (data == null) {
      return MedicalAiAnalysis.noData(
        patientId: fallbackPatientId ?? '',
        ownerUid: fallbackOwnerUid ?? '',
      );
    }
    return MedicalAiAnalysis.fromMap(data);
  }

  /// Creates a [MedicalAiAnalysis] from a Map.
  factory MedicalAiAnalysis.fromMap(Map<String, dynamic> map) {
    final rawUpdatedAt = map['updatedAt'];
    DateTime updatedAt;
    if (rawUpdatedAt is Timestamp) {
      updatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is String) {
      updatedAt = DateTime.tryParse(rawUpdatedAt) ?? DateTime.now();
    } else {
      updatedAt = DateTime.now();
    }

    final rawTags = map['tags'] as List<dynamic>?;
    final tags = rawTags
            ?.map((e) => HealthTag.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [];

    final rawConditions = map['conditions'] as List<dynamic>?;
    final conditions = rawConditions
            ?.map((e) =>
                MedicalFinding.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [];

    final rawSurgeries = map['surgeries'] as List<dynamic>?;
    final surgeries = rawSurgeries
            ?.map((e) =>
                MedicalFinding.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [];

    final rawMeds = map['medications'] as List<dynamic>?;
    final medications = rawMeds
            ?.map((e) =>
                MedicalFinding.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [];

    final rawAllergies = map['allergies'] as List<dynamic>?;
    final allergies = rawAllergies
            ?.map((e) =>
                MedicalFinding.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [];

    final rawFindings = map['importantFindings'] as List<dynamic>?;
    final importantFindings =
        rawFindings?.map((e) => e.toString()).toList() ?? const [];

    final rawSources = map['sourceRecordIds'] as List<dynamic>?;
    final sourceRecordIds =
        rawSources?.map((e) => e.toString()).toList() ?? const [];

    final rawAnalyzed = map['analyzedRecordIds'] as List<dynamic>?;
    final analyzedRecordIds =
        rawAnalyzed?.map((e) => e.toString()).toList() ?? const [];

    final rawFingerprints = map['recordFingerprints'] as Map<String, dynamic>?;
    final recordFingerprints = rawFingerprints != null
        ? rawFingerprints.map((k, v) => MapEntry(k, v.toString()))
        : <String, String>{};

    return MedicalAiAnalysis(
      patientId: map['patientId'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      tags: tags,
      conditions: conditions,
      surgeries: surgeries,
      medications: medications,
      allergies: allergies,
      importantFindings: importantFindings,
      sourceRecordIds: sourceRecordIds,
      analyzedRecordIds: analyzedRecordIds,
      recordFingerprints: recordFingerprints,
      status: AnalysisStatus.fromString(map['status'] as String?),
      analysisVersion: (map['analysisVersion'] as num?)?.toInt() ?? 1,
      updatedAt: updatedAt,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'ownerUid': ownerUid,
      'summary': summary,
      'tags': tags.map((t) => t.toMap()).toList(),
      'conditions': conditions.map((c) => c.toMap()).toList(),
      'surgeries': surgeries.map((s) => s.toMap()).toList(),
      'medications': medications.map((m) => m.toMap()).toList(),
      'allergies': allergies.map((a) => a.toMap()).toList(),
      'importantFindings': importantFindings,
      'sourceRecordIds': sourceRecordIds,
      'analyzedRecordIds': analyzedRecordIds,
      'recordFingerprints': recordFingerprints,
      'status': status.toValue(),
      'analysisVersion': analysisVersion,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'errorMessage': errorMessage,
    };
  }

  MedicalAiAnalysis copyWith({
    String? patientId,
    String? ownerUid,
    String? summary,
    List<HealthTag>? tags,
    List<MedicalFinding>? conditions,
    List<MedicalFinding>? surgeries,
    List<MedicalFinding>? medications,
    List<MedicalFinding>? allergies,
    List<String>? importantFindings,
    List<String>? sourceRecordIds,
    List<String>? analyzedRecordIds,
    Map<String, String>? recordFingerprints,
    AnalysisStatus? status,
    int? analysisVersion,
    DateTime? updatedAt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return MedicalAiAnalysis(
      patientId: patientId ?? this.patientId,
      ownerUid: ownerUid ?? this.ownerUid,
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      conditions: conditions ?? this.conditions,
      surgeries: surgeries ?? this.surgeries,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
      importantFindings: importantFindings ?? this.importantFindings,
      sourceRecordIds: sourceRecordIds ?? this.sourceRecordIds,
      analyzedRecordIds: analyzedRecordIds ?? this.analyzedRecordIds,
      recordFingerprints: recordFingerprints ?? this.recordFingerprints,
      status: status ?? this.status,
      analysisVersion: analysisVersion ?? this.analysisVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
