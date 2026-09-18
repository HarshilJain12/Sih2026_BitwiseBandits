import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/record_id_generator.dart';

void main() {
  group('RecordIdGenerator tests', () {
    const generator = RecordIdGenerator();

    test('generateCandidate produces ID with correct prefix and length', () {
      final id = RecordIdGenerator.generateCandidate();

      expect(id.startsWith('MR-'), isTrue);
      // 'MR-' (3 chars) + 10 alphanumeric chars = 13 total chars
      expect(id.length, 13);
    });

    test('instance generate() produces ID with correct format and length', () {
      final id = generator.generate();

      expect(id.startsWith('MR-'), isTrue);
      expect(id.length, 13);
      expect(RecordIdGenerator.isValidFormat(id), isTrue);
    });

    test(
      'generateCandidate produces uppercase alphanumeric chars after prefix',
      () {
        final id = RecordIdGenerator.generateCandidate();
        final suffix = id.substring(3);

        final validPattern = RegExp(r'^[A-Z0-9]{10}$');
        expect(validPattern.hasMatch(suffix), isTrue);
      },
    );

    test(
      'generate generates unique IDs across 100 iterations without collisions',
      () {
        final generatedIds = <String>{};
        const count = 100;

        for (int i = 0; i < count; i++) {
          final id = generator.generate();
          expect(
            generatedIds.contains(id),
            isFalse,
            reason: 'Collision on iteration $i',
          );
          generatedIds.add(id);
        }

        expect(generatedIds.length, count);
      },
    );

    test('isValidFormat validates prefix and suffix rules accurately', () {
      expect(RecordIdGenerator.isValidFormat('MR-ABC123XYZ0'), isTrue);
      expect(RecordIdGenerator.isValidFormat('MR-0123456789'), isTrue);
      expect(RecordIdGenerator.isValidFormat('MR-AAAAAAAAAA'), isTrue);

      // Invalid formats
      expect(
        RecordIdGenerator.isValidFormat('P-ABC123XYZ0'),
        isFalse,
      ); // Wrong prefix
      expect(
        RecordIdGenerator.isValidFormat('MR-ABC123XYZ'),
        isFalse,
      ); // 9 chars suffix
      expect(
        RecordIdGenerator.isValidFormat('MR-ABC123XYZ00'),
        isFalse,
      ); // 11 chars suffix
      expect(
        RecordIdGenerator.isValidFormat('MR-abc123xyz0'),
        isFalse,
      ); // Lowercase
      expect(
        RecordIdGenerator.isValidFormat('MR-ABC_23XYZ0'),
        isFalse,
      ); // Special char
      expect(RecordIdGenerator.isValidFormat(''), isFalse);
    });

    test('generates deterministic IDs when seeded Random is provided', () {
      final id1 = generator.generate(Random(42));
      final id2 = generator.generate(Random(42));

      expect(id1, equals(id2));
    });
  });
}
