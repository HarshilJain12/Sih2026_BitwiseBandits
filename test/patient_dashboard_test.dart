import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/patient.dart';
import 'package:healthcare_app/services/ai/local_health_message_generator.dart';
import 'package:healthcare_app/services/hospital/mock_hospital_search_service.dart';

void main() {
  group('Patient Dashboard Services Tests', () {
    late LocalHealthMessageGenerator messageGenerator;
    late MockHospitalSearchService hospitalSearchService;
    late Patient dummyPatient;

    setUp(() {
      messageGenerator = LocalHealthMessageGenerator();
      hospitalSearchService = MockHospitalSearchService();
      dummyPatient = Patient(
        patientId: 'P-TEST123456',
        ownerUid: 'owner_1',
        name: 'Rahul Test',
        phoneNumber: '+919876543210',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('LocalHealthMessageGenerator returns safe fallback message when no history', () async {
      final msgEn = await messageGenerator.generateMessage(
        patient: dummyPatient,
        localeCode: 'en',
      );
      expect(msgEn, isNotEmpty);
      expect(msgEn.contains('you') || msgEn.contains('health') || msgEn.contains('Welcome'), isTrue);

      final msgHi = await messageGenerator.generateMessage(
        patient: dummyPatient,
        localeCode: 'hi',
      );
      expect(msgHi, isNotEmpty);
    });

    test('MockHospitalSearchService filters and ranks nearby hospitals', () async {
      final dentalResults = await hospitalSearchService.searchHospitals(
        query: 'tooth pain',
      );
      expect(dentalResults, isNotEmpty);
      expect(dentalResults.first.specialty, equals('Dental Care'));

      final generalResults = await hospitalSearchService.searchHospitals(
        query: 'stomach pain',
      );
      expect(generalResults, isNotEmpty);
      expect(generalResults.first.name.contains('District') || generalResults.first.name.contains('Hospital'), isTrue);
    });
  });
}
