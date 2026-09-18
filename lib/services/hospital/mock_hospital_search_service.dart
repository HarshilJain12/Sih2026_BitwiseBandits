import 'package:geolocator/geolocator.dart';
import '../../models/hospital_result.dart';
import '../../models/patient_location.dart';
import 'hospital_search_service.dart';

/// Prototype implementation of [HospitalSearchService].
///
/// Maps patient symptoms/queries into healthcare categories (Dental, Pediatrics,
/// Cardiology, Dermatology, General Emergency) and computes distances relative
/// to patient location.
class MockHospitalSearchService implements HospitalSearchService {
  // Default reference coordinates (Pune/Maharashtra region) if location unavailable
  static const double _defaultLat = 18.5204;
  static const double _defaultLng = 73.8567;

  static const List<Map<String, dynamic>> _hospitalDatabase = [
    {
      'id': 'h-101',
      'name': 'District Civil Hospital',
      'address': 'Station Road, City Center',
      'lat': 18.5250,
      'lng': 73.8590,
      'specialty': 'General & Emergency Care',
      'phone': '+91 20 2612 3456',
      'isOpen': true,
      'hasEmergency': true,
      'rating': 4.6,
      'keywords': ['general', 'emergency', 'stomach', 'fever', 'accident', 'vomiting', 'chest'],
    },
    {
      'id': 'h-102',
      'name': 'Sanjeevani Dental Care Center',
      'address': 'MG Road, Near Bus Stand',
      'lat': 18.5180,
      'lng': 73.8520,
      'specialty': 'Dental Care',
      'phone': '+91 20 2613 9876',
      'isOpen': true,
      'hasEmergency': false,
      'rating': 4.8,
      'keywords': ['tooth', 'dental', 'teeth', 'gum', 'mouth', 'jaw'],
    },
    {
      'id': 'h-103',
      'name': 'Matoshree Children & Maternity Hospital',
      'address': 'Main Market Road',
      'lat': 18.5300,
      'lng': 73.8620,
      'specialty': 'Pediatric & Maternity Care',
      'phone': '+91 20 2614 1122',
      'isOpen': true,
      'hasEmergency': true,
      'rating': 4.7,
      'keywords': ['child', 'baby', 'kid', 'pediatric', 'fever', 'vaccine', 'maternity'],
    },
    {
      'id': 'h-104',
      'name': 'Krupa Skin & Allergy Clinic',
      'address': 'Subhash Nagar, Opposite Park',
      'lat': 18.5120,
      'lng': 73.8480,
      'specialty': 'Dermatology & Skin Care',
      'phone': '+91 20 2615 5544',
      'isOpen': true,
      'hasEmergency': false,
      'rating': 4.5,
      'keywords': ['skin', 'derma', 'rash', 'allergy', 'itching'],
    },
    {
      'id': 'h-105',
      'name': 'Sahyadri Heart & Cardiac Super Speciality',
      'address': 'Ring Road, Near Highway Touch',
      'lat': 18.5400,
      'lng': 73.8700,
      'specialty': 'Cardiology & Intensive Care',
      'phone': '+91 20 2616 8899',
      'isOpen': true,
      'hasEmergency': true,
      'rating': 4.9,
      'keywords': ['heart', 'cardiac', 'chest pain', 'breath', 'blood pressure', 'hypertension'],
    },
    {
      'id': 'h-106',
      'name': 'Rural Primary Healthcare Center (PHC)',
      'address': 'Taluka Bypass Road',
      'lat': 18.5050,
      'lng': 73.8420,
      'specialty': 'Primary Health & Ayushman Center',
      'phone': '+91 20 2617 3322',
      'isOpen': true,
      'hasEmergency': true,
      'rating': 4.4,
      'keywords': ['phc', 'primary', 'government', 'rural', 'ayushman', 'free'],
    },
  ];

  @override
  Future<List<HospitalResult>> searchHospitals({
    required String query,
    PatientLocation? location,
    double? latitude,
    double? longitude,
  }) async {
    // Simulate minor network lookup delay
    await Future.delayed(const Duration(milliseconds: 400));

    final refLat = latitude ?? location?.latitude ?? _defaultLat;
    final refLng = longitude ?? location?.longitude ?? _defaultLng;

    final lowerQuery = query.toLowerCase().trim();

    final results = <HospitalResult>[];

    for (final raw in _hospitalDatabase) {
      final hLat = raw['lat'] as double;
      final hLng = raw['lng'] as double;

      // Distance calculation in kilometers
      final distanceMeters = Geolocator.distanceBetween(refLat, refLng, hLat, hLng);
      final distanceKm = distanceMeters / 1000.0;

      final keywords = (raw['keywords'] as List<String>);
      final isMatch = lowerQuery.isEmpty ||
          keywords.any((k) => lowerQuery.contains(k)) ||
          (raw['name'] as String).toLowerCase().contains(lowerQuery) ||
          (raw['specialty'] as String).toLowerCase().contains(lowerQuery);

      if (isMatch) {
        results.add(
          HospitalResult(
            id: raw['id'] as String,
            name: raw['name'] as String,
            address: raw['address'] as String,
            latitude: hLat,
            longitude: hLng,
            distanceKm: double.parse(distanceKm.toStringAsFixed(1)),
            specialty: raw['specialty'] as String,
            phoneNumber: raw['phone'] as String?,
            isOpen: raw['isOpen'] as bool,
            hasEmergency: raw['hasEmergency'] as bool,
            rating: (raw['rating'] as num).toDouble(),
          ),
        );
      }
    }

    // Sort nearest hospital first
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    // If query returned no specific keyword match, return all hospitals sorted by distance
    if (results.isEmpty && lowerQuery.isNotEmpty) {
      return searchHospitals(
        query: '',
        location: location,
        latitude: latitude,
        longitude: longitude,
      );
    }

    return results;
  }
}
