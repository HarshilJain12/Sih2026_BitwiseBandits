import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/models/patient_location.dart';

void main() {
  group('PatientLocation model tests', () {
    test('GPS location serialization and deserialization', () {
      const location = PatientLocation(
        source: 'gps',
        latitude: 18.5204,
        longitude: 73.8567,
      );

      final map = location.toMap();
      expect(map['source'], equals('gps'));
      expect(map['latitude'], equals(18.5204));
      expect(map['longitude'], equals(73.8567));
      expect(map.containsKey('village'), isFalse);

      final parsed = PatientLocation.fromMap(map);
      expect(parsed.source, equals('gps'));
      expect(parsed.latitude, equals(18.5204));
      expect(parsed.longitude, equals(73.8567));
      expect(parsed.isGps, isTrue);
      expect(parsed.isManual, isFalse);
    });

    test('Manual location serialization and deserialization', () {
      const location = PatientLocation(
        source: 'manual',
        village: 'Baramati',
        district: 'Pune',
        state: 'Maharashtra',
        pincode: '413102',
        address: 'Near Old Bus Stand',
      );

      final map = location.toMap();
      expect(map['source'], equals('manual'));
      expect(map['village'], equals('Baramati'));
      expect(map['district'], equals('Pune'));
      expect(map['state'], equals('Maharashtra'));
      expect(map['pincode'], equals('413102'));
      expect(map['address'], equals('Near Old Bus Stand'));
      expect(map.containsKey('latitude'), isFalse);

      final parsed = PatientLocation.fromMap(map);
      expect(parsed.source, equals('manual'));
      expect(parsed.village, equals('Baramati'));
      expect(parsed.district, equals('Pune'));
      expect(parsed.state, equals('Maharashtra'));
      expect(parsed.pincode, equals('413102'));
      expect(parsed.address, equals('Near Old Bus Stand'));
      expect(parsed.isGps, isFalse);
      expect(parsed.isManual, isTrue);
    });

    test('copyWith updates specified fields', () {
      const location = PatientLocation(
        source: 'manual',
        village: 'Baramati',
        district: 'Pune',
        state: 'Maharashtra',
        pincode: '413102',
      );

      final updated = location.copyWith(village: 'Phaltan', district: 'Satara');
      expect(updated.village, equals('Phaltan'));
      expect(updated.district, equals('Satara'));
      expect(updated.state, equals('Maharashtra'));
      expect(updated.pincode, equals('413102'));
    });

    test('equality operator compares all fields', () {
      const l1 = PatientLocation(
        source: 'gps',
        latitude: 18.5204,
        longitude: 73.8567,
      );
      const l2 = PatientLocation(
        source: 'gps',
        latitude: 18.5204,
        longitude: 73.8567,
      );
      const l3 = PatientLocation(
        source: 'gps',
        latitude: 19.0760,
        longitude: 72.8777,
      );

      expect(l1, equals(l2));
      expect(l1, isNot(equals(l3)));
    });
  });
}
