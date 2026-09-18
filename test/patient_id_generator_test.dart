import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/patient_id_generator.dart';

void main() {
  group('PatientIdGenerator tests', () {
    const generator = PatientIdGenerator();

    test('generateCandidate produces ID with correct prefix and length', () {
      final id = PatientIdGenerator.generateCandidate();
      expect(id.startsWith('P-'), isTrue);
      expect(id.length, equals(12)); // 'P-' (2 chars) + 10 alphanumeric
      expect(PatientIdGenerator.isValidFormat(id), isTrue);
    });

    test('instance generate() produces ID with correct format and length', () {
      final id = generator.generate();
      expect(id.startsWith('P-'), isTrue);
      expect(id.length, equals(12));
      expect(PatientIdGenerator.isValidFormat(id), isTrue);
    });

    test(
      'generateCandidate produces uppercase alphanumeric chars after prefix',
      () {
        final id = PatientIdGenerator.generateCandidate();
        final suffix = id.substring(2);
        final allowedChars = RegExp(r'^[A-Z0-9]{10}$');
        expect(allowedChars.hasMatch(suffix), isTrue);
      },
    );

    test(
      'generate generates unique IDs across 100 iterations without Firestore',
      () {
        final ids = <String>{};
        for (var i = 0; i < 100; i++) {
          ids.add(generator.generate());
        }
        expect(ids.length, equals(100));
      },
    );

    test('isValidFormat validates prefix and suffix rules accurately', () {
      expect(PatientIdGenerator.isValidFormat('P-ABCDE12345'), isTrue);
      expect(PatientIdGenerator.isValidFormat('P-0123456789'), isTrue);
      expect(PatientIdGenerator.isValidFormat('P-ABCDEFGHIJ'), isTrue);

      // Invalid formats
      expect(
        PatientIdGenerator.isValidFormat('ABCDE12345'),
        isFalse,
      ); // No prefix
      expect(
        PatientIdGenerator.isValidFormat('P-abcde12345'),
        isFalse,
      ); // Lowercase
      expect(
        PatientIdGenerator.isValidFormat('P-ABCDE1234'),
        isFalse,
      ); // Too short (9 chars)
      expect(
        PatientIdGenerator.isValidFormat('P-ABCDE123456'),
        isFalse,
      ); // Too long (11 chars)
      expect(
        PatientIdGenerator.isValidFormat('P-ABCDE_2345'),
        isFalse,
      ); // Special character
    });
  });
}
