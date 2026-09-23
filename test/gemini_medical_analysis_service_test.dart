import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/medical_record.dart';
import 'package:healthcare_app/services/ai/gemini_medical_analysis_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GeminiMedicalAnalysisService Unit Tests', () {
    final samplePdfRecord = MedicalRecord(
      recordId: 'REC-PDF-001',
      patientId: 'P-1001',
      ownerUid: 'uid-1001',
      category: 'lab_reports',
      originalFileName: 'blood_report.pdf',
      fileSizeBytes: 2048,
      storagePath: 'patients/P-1001/REC-PDF-001.pdf',
      mimeType: 'application/pdf',
      uploadedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final sampleImageRecord = MedicalRecord(
      recordId: 'REC-IMG-002',
      patientId: 'P-1001',
      ownerUid: 'uid-1001',
      category: 'prescriptions',
      originalFileName: 'prescription.jpg',
      fileSizeBytes: 1024,
      storagePath: 'patients/P-1001/REC-IMG-002.jpg',
      mimeType: 'image/jpeg',
      uploadedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final dummyPdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.4 sample content'));
    final dummyImageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);

    test('1. PDF payload construction sends inlineData with application/pdf mimeType', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'summary': 'Blood test indicates HbA1c of 6.8% mentioned in uploaded records.',
                        'tags': [
                          {
                            'label': 'Diabetes Mentioned',
                            'category': 'condition',
                            'evidence': 'HbA1c 6.8%',
                            'sourceRecordId': 'REC-PDF-001',
                            'sourceFileName': 'blood_report.pdf',
                          }
                        ],
                        'conditions': [
                          {
                            'name': 'Elevated Blood Sugar Mentioned',
                            'status': 'documented',
                            'evidence': 'HbA1c 6.8%',
                            'sourceRecordId': 'REC-PDF-001',
                            'sourceFileName': 'blood_report.pdf',
                          }
                        ],
                        'surgeries': [],
                        'medications': [],
                        'allergies': [],
                        'importantFindings': [
                          'HbA1c 6.8% in fasting blood test'
                        ],
                      })
                    }
                  ]
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiMedicalAnalysisService(
        apiKey: 'test_api_key',
        httpClient: mockClient,
      );

      final result = await service.analyzeDocument(
        record: samplePdfRecord,
        fileBytes: dummyPdfBytes,
      );

      // Verify request payload
      final contents = capturedBody['contents'] as List;
      final parts = contents[0]['parts'] as List;
      final inlineDataPart = parts.firstWhere((p) => (p as Map).containsKey('inline_data'))['inline_data'];

      expect(inlineDataPart['mime_type'], equals('application/pdf'));
      expect(inlineDataPart['data'], equals(base64Encode(dummyPdfBytes)));

      // Verify parsed output
      expect(result.summary, contains('HbA1c'));
      expect(result.tags.length, equals(1));
      expect(result.tags.first.label, equals('Diabetes Mentioned'));
      expect(result.tags.first.sourceRecordId, equals('REC-PDF-001'));
      expect(result.tags.first.sourceFileName, equals('blood_report.pdf'));
    });

    test('2. Image payload construction sends inlineData with image/jpeg mimeType', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'summary': 'Prescription lists Amoxicillin 500mg mentioned.',
                        'tags': [
                          {
                            'label': 'Antibiotic Prescribed',
                            'category': 'medication',
                            'evidence': 'Amoxicillin 500mg TDS',
                            'sourceRecordId': 'REC-IMG-002',
                            'sourceFileName': 'prescription.jpg',
                          }
                        ],
                        'conditions': [],
                        'surgeries': [],
                        'medications': [
                          {
                            'name': 'Amoxicillin 500mg',
                            'status': 'active',
                            'evidence': 'Amoxicillin 500mg TDS for 5 days',
                            'sourceRecordId': 'REC-IMG-002',
                            'sourceFileName': 'prescription.jpg',
                          }
                        ],
                        'allergies': [],
                        'importantFindings': [],
                      })
                    }
                  ]
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiMedicalAnalysisService(
        apiKey: 'test_api_key',
        httpClient: mockClient,
      );

      final result = await service.analyzeDocument(
        record: sampleImageRecord,
        fileBytes: dummyImageBytes,
      );

      final contents = capturedBody['contents'] as List;
      final parts = contents[0]['parts'] as List;
      final inlineDataPart = parts.firstWhere((p) => (p as Map).containsKey('inline_data'))['inline_data'];

      expect(inlineDataPart['mime_type'], equals('image/jpeg'));
      expect(result.medications.first.name, equals('Amoxicillin 500mg'));
    });

    test('3. Non-diagnostic behavior and uncertainty preservation in structured output', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'summary': 'Possible asthma mentioned in uploaded records. Patient reports mild wheezing.',
                        'tags': [
                          {
                            'label': 'Possible Asthma Mentioned',
                            'category': 'condition',
                            'evidence': 'Physician note: Possible bronchial asthma',
                            'sourceRecordId': 'REC-PDF-001',
                            'sourceFileName': 'blood_report.pdf',
                          }
                        ],
                        'conditions': [
                          {
                            'name': 'Possible Asthma Mentioned',
                            'status': 'suspected',
                            'evidence': 'Physician note: Possible bronchial asthma',
                            'sourceRecordId': 'REC-PDF-001',
                            'sourceFileName': 'blood_report.pdf',
                          }
                        ],
                        'surgeries': [],
                        'medications': [],
                        'allergies': [],
                        'importantFindings': [],
                      })
                    }
                  ]
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiMedicalAnalysisService(
        apiKey: 'test_api_key',
        httpClient: mockClient,
      );

      final result = await service.analyzeDocument(
        record: samplePdfRecord,
        fileBytes: dummyPdfBytes,
      );

      expect(result.summary, contains('Possible asthma mentioned'));
      expect(result.conditions.first.status, equals('suspected'));
      expect(result.tags.first.label, equals('Possible Asthma Mentioned'));
    });

    test('4. Malformed Gemini response triggers safe deterministic metadata fallback', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'This is unformatted random text without JSON'}
                  ]
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiMedicalAnalysisService(
        apiKey: 'test_api_key',
        httpClient: mockClient,
      );

      final result = await service.analyzeDocument(
        record: samplePdfRecord,
        fileBytes: dummyPdfBytes,
      );

      // Safe deterministic fallback produces valid structured findings with record info
      expect(result.summary, contains('Lab Reports'));
      expect(result.tags.length, equals(1));
      expect(result.tags.first.label, equals('Lab Reports Documented'));
      expect(result.tags.first.sourceRecordId, equals('REC-PDF-001'));
    });

    test('5. Gemini HTTP 500 error triggers safe fallback without crashing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = GeminiMedicalAnalysisService(
        apiKey: 'test_api_key',
        httpClient: mockClient,
      );

      final result = await service.analyzeDocument(
        record: samplePdfRecord,
        fileBytes: dummyPdfBytes,
      );

      expect(result.tags.isNotEmpty, isTrue);
      expect(result.tags.first.sourceRecordId, equals('REC-PDF-001'));
    });
  });
}
