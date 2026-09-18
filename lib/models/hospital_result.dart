/// Model representing a hospital search result item.
class HospitalResult {
  const HospitalResult({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.specialty,
    this.phoneNumber,
    this.isOpen = true,
    this.hasEmergency = true,
    this.rating = 4.5,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String specialty;
  final String? phoneNumber;
  final bool isOpen;
  final bool hasEmergency;
  final double rating;

  String get formattedDistance => distanceKm < 1.0
      ? '${(distanceKm * 1000).toInt()} m'
      : '${distanceKm.toStringAsFixed(1)} km';
}
