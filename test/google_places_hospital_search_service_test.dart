import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/services/ai/gemini_hospital_intent_service.dart';
import 'package:healthcare_app/services/hospital/google_places_hospital_search_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GooglePlacesHospitalSearchService Unit Tests', () {
    const double userLat = 18.5204;
    const double userLng = 73.8567;

    test('1. Google Places JSON response converts correctly into HospitalResult items', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['includedTypes'], contains('dentist'));
        expect(body['locationRestriction']['circle']['center']['latitude'], equals(userLat));
        expect(body['locationRestriction']['circle']['center']['longitude'], equals(userLng));

        return http.Response(
          jsonEncode({
            'places': [
              {
                'id': 'place_123',
                'displayName': {'text': 'City Dental Clinic'},
                'formattedAddress': '123 Main Road, Pune',
                'location': {'latitude': 18.5300, 'longitude': 73.8600},
                'rating': 4.7,
                'nationalPhoneNumber': '+91 20 1234 5678',
                'regularOpeningHours': {'openNow': true},
                'types': ['dentist', 'health'],
              },
              {
                'id': 'place_456',
                'displayName': {'text': 'Apex Dental Care'},
                'formattedAddress': '456 MG Road, Pune',
                'location': {'latitude': 18.5400, 'longitude': 73.8700},
                'rating': 4.9,
                'regularOpeningHours': {'openNow': false},
                'types': ['dentist'],
              },
              {
                'id': 'place_789',
                'displayName': {'text': 'Omkar Dental Center'},
                'formattedAddress': '789 Station Rd, Pune',
                'location': {'latitude': 18.5100, 'longitude': 73.8500},
                'rating': 4.5,
                'types': ['dentist'],
              },
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GooglePlacesHospitalSearchService(
        apiKey: 'test_places_key',
        httpClient: mockClient,
      );

      final results = await service.searchHospitals(
        query: 'tooth pain',
        latitude: userLat,
        longitude: userLng,
      );

      expect(results.length, equals(3));
      final first = results.first;
      expect(first.name, isNotEmpty);
      expect(first.distanceKm, isPositive);
      expect(first.specialty, contains('Dental'));
    });

    test('2. Radius expands when fewer than 3 results are returned in 5km tier', () async {
      int requestCount = 0;
      final requestedRadii = <double>[];

      final mockClient = MockClient((request) async {
        requestCount++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final radius = (body['locationRestriction']['circle']['radius'] as num).toDouble();
        requestedRadii.add(radius);

        if (radius < 10000) {
          // 5km tier: return 1 result (trigger expansion)
          return http.Response(
            jsonEncode({
              'places': [
                {
                  'id': 'place_1',
                  'displayName': {'text': 'Rural Clinic 1'},
                  'formattedAddress': 'Village 1',
                  'location': {'latitude': 18.5250, 'longitude': 73.8580},
                }
              ]
            }),
            200,
          );
        } else {
          // 10km tier: return 3 results
          return http.Response(
            jsonEncode({
              'places': [
                {
                  'id': 'place_1',
                  'displayName': {'text': 'Rural Clinic 1'},
                  'formattedAddress': 'Village 1',
                  'location': {'latitude': 18.5250, 'longitude': 73.8580},
                },
                {
                  'id': 'place_2',
                  'displayName': {'text': 'Rural Clinic 2'},
                  'formattedAddress': 'Village 2',
                  'location': {'latitude': 18.5450, 'longitude': 73.8780},
                },
                {
                  'id': 'place_3',
                  'displayName': {'text': 'Rural Clinic 3'},
                  'formattedAddress': 'Village 3',
                  'location': {'latitude': 18.5650, 'longitude': 73.8980},
                },
              ]
            }),
            200,
          );
        }
      });

      final service = GooglePlacesHospitalSearchService(
        apiKey: 'test_places_key',
        httpClient: mockClient,
      );

      final results = await service.searchHospitals(
        query: HealthcareCategory.clinic,
        latitude: userLat,
        longitude: userLng,
      );

      expect(results.length, equals(3));
      expect(requestCount, equals(2));
      expect(requestedRadii, equals([5000.0, 10000.0]));
    });

    test('3. Search throws ArgumentError when latitude or longitude is missing', () async {
      final service = GooglePlacesHospitalSearchService(apiKey: 'test_key');
      expect(
        () => service.searchHospitals(query: 'fever'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
