import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Result status when attempting to acquire the device's current GPS location.
enum LocationFetchStatus {
  success,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeoutOrError,
}

/// Result payload containing status and optional [Position].
class LocationFetchResult {
  const LocationFetchResult({
    required this.status,
    this.position,
    this.errorMessage,
  });

  final LocationFetchStatus status;
  final Position? position;
  final String? errorMessage;

  bool get isSuccess =>
      status == LocationFetchStatus.success && position != null;
}

/// Service that encapsulates one-time GPS acquisition and permission checks.
///
/// Follows rural-first principles:
/// - One-time acquisition only (no continuous streams or background tracking).
/// - Graceful handling of disabled services, denied permissions, and timeouts.
class LocationService {
  const LocationService();

  /// Checks whether device-level location services (GPS) are enabled.
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationService] Error checking service enabled: $e');
      }
      return false;
    }
  }

  /// Checks the current location permission state.
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationService] Error checking permission: $e');
      }
      return LocationPermission.denied;
    }
  }

  /// Requests location permission from the user.
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationService] Error requesting permission: $e');
      }
      return LocationPermission.denied;
    }
  }

  /// Acquires the current device GPS position once.
  ///
  /// Times out after [timeout] (default 10 seconds).
  Future<LocationFetchResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationFetchResult(
        status: LocationFetchStatus.servicesDisabled,
        errorMessage: 'Location services are disabled on device.',
      );
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationFetchResult(
          status: LocationFetchStatus.permissionDenied,
          errorMessage: 'Location permission was denied by user.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationFetchResult(
        status: LocationFetchStatus.permissionDeniedForever,
        errorMessage: 'Location permission is permanently denied.',
      );
    }

    try {
      final LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
          forceLocationManager: true,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      return LocationFetchResult(
        status: LocationFetchStatus.success,
        position: position,
      );
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('[LocationService] GPS location fetch timed out.');
      }
      return const LocationFetchResult(
        status: LocationFetchStatus.timeoutOrError,
        errorMessage: 'Location request timed out. Please try again.',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationService] Error getting current position: $e');
      }
      return LocationFetchResult(
        status: LocationFetchStatus.timeoutOrError,
        errorMessage: e.toString(),
      );
    }
  }

  /// Opens the device settings to enable location services.
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationService] Error opening location settings: $e');
      }
      return false;
    }
  }

  /// Opens application settings (for permanently denied permissions).
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationService] Error opening app settings: $e');
      }
      return false;
    }
  }
}
