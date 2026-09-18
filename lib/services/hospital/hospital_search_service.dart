import '../../models/hospital_result.dart';
import '../../models/patient_location.dart';

/// Abstract interface for hospital search and healthcare facility lookup.
abstract class HospitalSearchService {
  /// Searches for nearby hospitals matching [query] and relative to [location].
  Future<List<HospitalResult>> searchHospitals({
    required String query,
    PatientLocation? location,
    double? latitude,
    double? longitude,
  });
}
