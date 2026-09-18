import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/utils/validators.dart';

void main() {
  group('Validators - Name', () {
    test('validates standard English, Hindi, and Marathi names', () {
      expect(Validators.name('Rahul Kumar'), isNull);
      expect(Validators.name('अमित कुमार'), isNull);
      expect(Validators.name('अमोल पाटील'), isNull);
      expect(Validators.name('Ayesha Khan'), isNull);
      expect(Validators.name('  Sunita Rao  '), isNull);
    });

    test('rejects empty or very short names', () {
      expect(Validators.name(''), equals('validation_name'));
      expect(Validators.name('   '), equals('validation_name'));
      expect(Validators.name('A'), equals('validation_name'));
      expect(Validators.name(null), equals('validation_name'));
    });
  });

  group('Validators - Age', () {
    test('validates valid ages between 1 and 120', () {
      expect(Validators.age('1'), isNull);
      expect(Validators.age('25'), isNull);
      expect(Validators.age('65'), isNull);
      expect(Validators.age('120'), isNull);
      expect(Validators.age('  45  '), isNull);
    });

    test('rejects invalid or out of range ages', () {
      expect(Validators.age(''), equals('validation_age'));
      expect(Validators.age('   '), equals('validation_age'));
      expect(Validators.age('0'), equals('validation_age'));
      expect(Validators.age('-5'), equals('validation_age'));
      expect(Validators.age('121'), equals('validation_age'));
      expect(Validators.age('25.5'), equals('validation_age'));
      expect(Validators.age('abc'), equals('validation_age'));
      expect(Validators.age(null), equals('validation_age'));
    });
  });

  group('Validators - Weight', () {
    test('validates valid weights in kg', () {
      expect(Validators.weight('50'), isNull);
      expect(Validators.weight('65.5'), isNull);
      expect(Validators.weight('12.3'), isNull);
      expect(Validators.weight('150'), isNull);
      expect(Validators.weight('  70.2  '), isNull);
    });

    test('rejects invalid, negative, or unreasonable weights', () {
      expect(Validators.weight(''), equals('validation_weight'));
      expect(Validators.weight('   '), equals('validation_weight'));
      expect(Validators.weight('0'), equals('validation_weight'));
      expect(Validators.weight('0.5'), equals('validation_weight'));
      expect(Validators.weight('-10'), equals('validation_weight'));
      expect(Validators.weight('600'), equals('validation_weight'));
      expect(Validators.weight('abc'), equals('validation_weight'));
      expect(Validators.weight(null), equals('validation_weight'));
    });
  });

  group('Validators - Height', () {
    test('validates valid heights in cm', () {
      expect(Validators.height('50'), isNull);
      expect(Validators.height('165'), isNull);
      expect(Validators.height('172.5'), isNull);
      expect(Validators.height('210'), isNull);
      expect(Validators.height('  180  '), isNull);
    });

    test('rejects invalid, negative, or unreasonable heights', () {
      expect(Validators.height(''), equals('validation_height'));
      expect(Validators.height('   '), equals('validation_height'));
      expect(Validators.height('0'), equals('validation_height'));
      expect(Validators.height('10'), equals('validation_height'));
      expect(Validators.height('-150'), equals('validation_height'));
      expect(Validators.height('350'), equals('validation_height'));
      expect(Validators.height('xyz'), equals('validation_height'));
      expect(Validators.height(null), equals('validation_height'));
    });
  });

  group('Validators - Phone Number', () {
    test('validates standard 10-digit Indian mobile number', () {
      expect(Validators.phoneNumber('9876543210'), isNull);
      expect(Validators.phoneNumber('  9876543210  '), isNull);
    });

    test('validates 12-digit 91 prefixed number', () {
      expect(Validators.phoneNumber('919876543210'), isNull);
    });

    test('validates international E.164 test number with +', () {
      expect(Validators.phoneNumber('+1 650-555-3434'), isNull);
      expect(Validators.phoneNumber('+16505553434'), isNull);
      expect(Validators.phoneNumber('+919876543210'), isNull);
    });

    test('rejects empty or invalid phone numbers', () {
      expect(Validators.phoneNumber(''), equals('validation_required'));
      expect(Validators.phoneNumber('   '), equals('validation_required'));
      expect(Validators.phoneNumber('12345'), equals('validation_phone'));
      expect(Validators.phoneNumber('abcdefghij'), equals('validation_phone'));
      expect(Validators.phoneNumber('+123'), equals('validation_phone'));
    });

    test('normalizes standard 10-digit Indian number to +91 E.164', () {
      expect(
        Validators.normalizePhoneNumber('9876543210'),
        equals('+919876543210'),
      );
      expect(
        Validators.normalizePhoneNumber('919876543210'),
        equals('+919876543210'),
      );
    });

    test('normalizes international number keeping country code', () {
      expect(
        Validators.normalizePhoneNumber('+1 650-555-3434'),
        equals('+16505553434'),
      );
      expect(
        Validators.normalizePhoneNumber('+91 98765-43210'),
        equals('+919876543210'),
      );
    });
  });

  group('Validators - OTP', () {
    test('validates 6-digit OTP', () {
      expect(Validators.otp('739284'), isNull);
      expect(Validators.otp('123456'), isNull);
    });

    test('rejects non-6-digit or non-numeric OTP', () {
      expect(Validators.otp(''), equals('validation_required'));
      expect(Validators.otp('12345'), equals('validation_otp'));
      expect(Validators.otp('1234567'), equals('validation_otp'));
      expect(Validators.otp('12a456'), equals('validation_otp'));
    });
  });
}
