/// Strongly typed model representing a patient's geographic location.
///
/// Can be captured via:
/// - GPS (`source: 'gps'`) with [latitude] and [longitude]
/// - Manual entry (`source: 'manual'`) with [village], [district], [state], [pincode], and optional [address]
class PatientLocation {
  const PatientLocation({
    required this.source,
    this.latitude,
    this.longitude,
    this.village,
    this.district,
    this.state,
    this.pincode,
    this.address,
  });

  /// Location source: `'gps'` or `'manual'`.
  final String source;

  /// Latitude coordinate (populated for GPS).
  final double? latitude;

  /// Longitude coordinate (populated for GPS).
  final double? longitude;

  /// Village or town name (populated for manual).
  final String? village;

  /// District name (populated for manual).
  final String? district;

  /// State name (populated for manual).
  final String? state;

  /// 6-digit postal PIN code (populated for manual).
  final String? pincode;

  /// Optional full street address / landmark (populated for manual).
  final String? address;

  /// True if captured via GPS.
  bool get isGps => source == 'gps';

  /// True if entered manually.
  bool get isManual => source == 'manual';

  /// Creates a [PatientLocation] from a Firestore map or returns `null` if the map is empty/invalid.
  factory PatientLocation.fromMap(Map<String, dynamic> map) {
    return PatientLocation(
      source: map['source'] as String? ?? 'manual',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      village: map['village'] as String?,
      district: map['district'] as String?,
      state: map['state'] as String?,
      pincode: map['pincode'] as String?,
      address: map['address'] as String?,
    );
  }

  /// Converts this [PatientLocation] to a Firestore map.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'source': source};

    if (latitude != null) {
      map['latitude'] = latitude;
    }
    if (longitude != null) {
      map['longitude'] = longitude;
    }
    if (village != null && village!.trim().isNotEmpty) {
      map['village'] = village!.trim();
    }
    if (district != null && district!.trim().isNotEmpty) {
      map['district'] = district!.trim();
    }
    if (state != null && state!.trim().isNotEmpty) {
      map['state'] = state!.trim();
    }
    if (pincode != null && pincode!.trim().isNotEmpty) {
      map['pincode'] = pincode!.trim();
    }
    if (address != null && address!.trim().isNotEmpty) {
      map['address'] = address!.trim();
    }

    return map;
  }

  /// Creates a copy with specified fields replaced.
  PatientLocation copyWith({
    String? source,
    double? latitude,
    double? longitude,
    String? village,
    String? district,
    String? state,
    String? pincode,
    String? address,
  }) {
    return PatientLocation(
      source: source ?? this.source,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      address: address ?? this.address,
    );
  }

  @override
  String toString() {
    if (isGps) {
      return 'PatientLocation(gps: $latitude, $longitude)';
    }
    return 'PatientLocation(manual: $village, $district, $state, $pincode)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientLocation &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          village == other.village &&
          district == other.district &&
          state == other.state &&
          pincode == other.pincode &&
          address == other.address;

  @override
  int get hashCode => Object.hash(
    source,
    latitude,
    longitude,
    village,
    district,
    state,
    pincode,
    address,
  );
}
