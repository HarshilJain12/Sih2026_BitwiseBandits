import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../models/hospital_result.dart';
import '../../models/patient_location.dart';
import '../ai/gemini_hospital_intent_service.dart';
import 'hospital_search_service.dart';

/// Production implementation of [HospitalSearchService] using Google Places API (New).
///
/// Strictly uses live CURRENT GPS coordinates with expanding search radius (5km -> 10km -> 25km).
class GooglePlacesHospitalSearchService implements HospitalSearchService {
  GooglePlacesHospitalSearchService({
    String? apiKey,
    http.Client? httpClient,
    GeminiHospitalIntentService? intentService,
  })  : _apiKey = apiKey ?? ApiConfig.placesApiKey,
        _client = httpClient ?? http.Client(),
        _intentService = intentService ?? GeminiHospitalIntentService();

  final String _apiKey;
  final http.Client _client;
  final GeminiHospitalIntentService _intentService;

  static const String _placesEndpoint =
      'https://places.googleapis.com/v1/places:searchNearby';

  static const List<double> _radiusTiers = [5000.0, 10000.0, 25000.0];

  @override
  Future<List<HospitalResult>> searchHospitals({
    required String query,
    PatientLocation? location,
    double? latitude,
    double? longitude,
  }) async {
    final curLat = latitude ?? (location?.isGps == true ? location?.latitude : null);
    final curLng = longitude ?? (location?.isGps == true ? location?.longitude : null);

    if (curLat == null || curLng == null) {
      throw ArgumentError(
        'Fresh current GPS coordinates (latitude and longitude) are required for Google Places search.',
      );
    }

    // 1. Determine healthcare category using Gemini or fallback
    final category = await _resolveCategory(query);

    // 2. Map category to Google Places includedTypes
    final specializedTypes = _mapCategoryToPlaceTypes(category);

    // 3. Search for specialized healthcare facilities with expanding radius tiers (5km -> 10km -> 25km)
    List<HospitalResult> specializedResults = [];
    final seenIds = <String>{};

    for (final radius in _radiusTiers) {
      final tierResults = await _executePlacesSearch(
        currentLat: curLat,
        currentLng: curLng,
        category: category,
        includedTypes: specializedTypes,
        radiusMeters: radius,
      );

      for (final r in tierResults) {
        if (seenIds.add(r.id)) {
          specializedResults.add(r);
        }
      }

      if (specializedResults.length >= 3) {
        break;
      }
    }

    // Sort specialized facilities by distance (nearest first)
    specializedResults.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    // 4. If specialized facilities are fewer than 3 and the category is not already general hospital,
    // also fetch general multi-specialty hospitals & clinics where doctors for all fields are present.
    List<HospitalResult> generalResults = [];
    final isSpecializedCategory = category != HealthcareCategory.hospital &&
        category != HealthcareCategory.generalPhysician &&
        category != HealthcareCategory.clinic;

    if (specializedResults.length < 3 && isSpecializedCategory) {
      for (final radius in _radiusTiers) {
        final tierResults = await _executePlacesSearch(
          currentLat: curLat,
          currentLng: curLng,
          category: HealthcareCategory.hospital,
          includedTypes: const ['hospital', 'doctor', 'medical_clinic'],
          radiusMeters: radius,
          specialtyOverride: 'Hospital (General & Multi-Specialty)',
        );

        for (final r in tierResults) {
          if (seenIds.add(r.id)) {
            generalResults.add(r);
          }
        }

        if ((specializedResults.length + generalResults.length) >= 4) {
          break;
        }
      }

      generalResults.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    // Return specialized facilities FIRST, followed by general hospitals/physicians
    return [...specializedResults, ...generalResults];
  }

  Future<String> _resolveCategory(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return HealthcareCategory.hospital;
    }

    // If query is already an exact category name (e.g. from specialty chips)
    if (HealthcareCategory.isValid(q)) {
      return q;
    }

    return await _intentService.classifyIntent(q);
  }

  List<String> _mapCategoryToPlaceTypes(String category) {
    switch (category) {
      case HealthcareCategory.dentist:
        return ['dentist', 'dental_clinic'];
      case HealthcareCategory.eyeCare:
        return ['ophthalmologist', 'optometrist'];
      case HealthcareCategory.dermatologist:
        return ['dermatologist'];
      case HealthcareCategory.pediatrician:
        return ['pediatrician'];
      case HealthcareCategory.orthopedics:
        return ['orthopedic_surgeon'];
      case HealthcareCategory.gynecologist:
        return ['gynecologist'];
      case HealthcareCategory.pharmacy:
        return ['pharmacy', 'drugstore'];
      case HealthcareCategory.clinic:
        return ['medical_clinic'];
      case HealthcareCategory.generalPhysician:
      case HealthcareCategory.ent:
        return ['doctor', 'medical_clinic'];
      case HealthcareCategory.hospital:
      default:
        return ['hospital'];
    }
  }

  Future<List<HospitalResult>> _executePlacesSearch({
    required double currentLat,
    required double currentLng,
    required String category,
    required List<String> includedTypes,
    required double radiusMeters,
    String? specialtyOverride,
  }) async {
    if (_apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[GooglePlacesHospitalSearchService] Places API Key is not configured.');
      }
      return [];
    }

    final requestBody = {
      'includedTypes': includedTypes,
      'maxResultCount': 20,
      'rankPreference': 'DISTANCE',
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': currentLat,
            'longitude': currentLng,
          },
          'radius': radiusMeters,
        },
      },
    };

    try {
      final response = await _client.post(
        Uri.parse(_placesEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.primaryType,places.types,places.rating,places.nationalPhoneNumber,places.regularOpeningHours',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            '[GooglePlacesHospitalSearchService] Places API Error: ${response.statusCode} - ${response.body}',
          );
        }
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final places = data['places'] as List<dynamic>?;
      if (places == null || places.isEmpty) {
        return [];
      }

      final results = <HospitalResult>[];
      for (final item in places) {
        final raw = item as Map<String, dynamic>;
        final location = raw['location'] as Map<String, dynamic>?;
        if (location == null) continue;

        final pLat = (location['latitude'] as num?)?.toDouble();
        final pLng = (location['longitude'] as num?)?.toDouble();
        if (pLat == null || pLng == null) continue;

        final distMeters = Geolocator.distanceBetween(
          currentLat,
          currentLng,
          pLat,
          pLng,
        );
        final distKm = distMeters / 1000.0;

        final displayName = (raw['displayName'] as Map<String, dynamic>?)?['text'] as String? ??
            'Healthcare Facility';
        final address = raw['formattedAddress'] as String? ?? 'Nearby';
        final placeId = raw['id'] as String? ?? 'p_${results.length}';
        final rating = (raw['rating'] as num?)?.toDouble() ?? 4.5;
        final phone = raw['nationalPhoneNumber'] as String?;
        final openingHours = raw['regularOpeningHours'] as Map<String, dynamic>?;
        final isOpen = openingHours?['openNow'] as bool? ?? true;
        final types = (raw['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final hasEmergency = category == HealthcareCategory.hospital ||
            types.contains('hospital') ||
            types.contains('emergency_room');

        final displaySpecialty = specialtyOverride ?? HealthcareCategory.getDisplayName(category);

        results.add(
          HospitalResult(
            id: placeId,
            name: displayName,
            address: address,
            latitude: pLat,
            longitude: pLng,
            distanceKm: double.parse(distKm.toStringAsFixed(1)),
            specialty: displaySpecialty,
            phoneNumber: phone,
            isOpen: isOpen,
            hasEmergency: hasEmergency,
            rating: rating,
          ),
        );
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GooglePlacesHospitalSearchService] Exception querying places: $e');
      }
      return [];
    }
  }
}
