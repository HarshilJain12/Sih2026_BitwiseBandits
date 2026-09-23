import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:healthcare_app/l10n/app_localizations.dart';
import 'package:healthcare_app/models/hospital_result.dart';
import 'package:healthcare_app/models/patient_location.dart';
import 'package:healthcare_app/screens/patient_dashboard/widgets/find_hospital_section.dart';
import 'package:healthcare_app/services/hospital/hospital_search_service.dart';
import 'package:healthcare_app/services/location/location_service.dart';
import 'package:healthcare_app/services/speech/mock_speech_input_service.dart';

class MockTestLocationService extends LocationService {
  MockTestLocationService({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.position,
  });

  final bool serviceEnabled;
  final LocationPermission permission;
  final Position? position;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<LocationFetchResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!serviceEnabled) {
      return const LocationFetchResult(status: LocationFetchStatus.servicesDisabled);
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return const LocationFetchResult(status: LocationFetchStatus.permissionDenied);
    }
    if (position == null) {
      return const LocationFetchResult(status: LocationFetchStatus.timeoutOrError);
    }
    return LocationFetchResult(status: LocationFetchStatus.success, position: position);
  }
}

class RecordingHospitalSearchService implements HospitalSearchService {
  String? lastQuery;
  double? lastLatitude;
  double? lastLongitude;
  List<HospitalResult> returnedResults = [];

  @override
  Future<List<HospitalResult>> searchHospitals({
    required String query,
    PatientLocation? location,
    double? latitude,
    double? longitude,
  }) async {
    lastQuery = query;
    lastLatitude = latitude;
    lastLongitude = longitude;
    return returnedResults;
  }
}

Widget _buildTestWidget({
  required LocationService locationService,
  required HospitalSearchService searchService,
  MockSpeechInputService? speechService,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: FindHospitalSection(
          onOpenMap: (selected, all, userLat, userLng) {},
          onGetDirections: (h) {},
          searchService: searchService,
          speechService: speechService ?? MockSpeechInputService(),
          locationService: locationService,
        ),
      ),
    ),
  );
}

void main() {
  group('FindHospitalSection Live Location & Real Places Pipeline Tests', () {
    final livePosition = Position(
      latitude: 19.0760,
      longitude: 72.8777,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 1.0,
    );

    testWidgets('1. Hospital search passes FRESH LIVE GPS coordinates (19.0760, 72.8777)', (tester) async {
      final mockLocation = MockTestLocationService(position: livePosition);
      final recordingSearch = RecordingHospitalSearchService();
      recordingSearch.returnedResults = [
        const HospitalResult(
          id: 'place_1',
          name: 'City General Hospital',
          address: 'Main St',
          latitude: 19.0800,
          longitude: 72.8800,
          distanceKm: 0.5,
          specialty: 'Hospital',
        ),
      ];

      await tester.pumpWidget(_buildTestWidget(
        locationService: mockLocation,
        searchService: recordingSearch,
      ));
      await tester.pumpAndSettle();

      // Verify the search invoked with live GPS coordinates
      expect(recordingSearch.lastLatitude, equals(19.0760));
      expect(recordingSearch.lastLongitude, equals(72.8777));
      expect(find.text('City General Hospital'), findsOneWidget);
    });

    testWidgets('2. Location service disabled displays clear error and no fake hospitals', (tester) async {
      final disabledLocation = MockTestLocationService(serviceEnabled: false);
      final recordingSearch = RecordingHospitalSearchService();

      await tester.pumpWidget(_buildTestWidget(
        locationService: disabledLocation,
        searchService: recordingSearch,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Please enable location services'), findsOneWidget);
      expect(find.text('Open Location Settings'), findsOneWidget);
      expect(recordingSearch.lastLatitude, isNull);
    });

    testWidgets('3. Location permission denied displays permission error', (tester) async {
      final deniedLocation = MockTestLocationService(permission: LocationPermission.denied);
      final recordingSearch = RecordingHospitalSearchService();

      await tester.pumpWidget(_buildTestWidget(
        locationService: deniedLocation,
        searchService: recordingSearch,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Location permission is required'), findsOneWidget);
      expect(find.text('Open App Settings'), findsOneWidget);
    });

    testWidgets('4. Empty places results shows clear empty state without mock fallback', (tester) async {
      final mockLocation = MockTestLocationService(position: livePosition);
      final recordingSearch = RecordingHospitalSearchService();
      recordingSearch.returnedResults = []; // No results found

      await tester.pumpWidget(_buildTestWidget(
        locationService: mockLocation,
        searchService: recordingSearch,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('No nearby healthcare facilities found'), findsOneWidget);
    });

    testWidgets('5. Specialty chip selection performs category search with live GPS', (tester) async {
      final mockLocation = MockTestLocationService(position: livePosition);
      final recordingSearch = RecordingHospitalSearchService();

      await tester.pumpWidget(_buildTestWidget(
        locationService: mockLocation,
        searchService: recordingSearch,
      ));
      await tester.pumpAndSettle();

      // Tap Dental Care chip
      await tester.tap(find.text('Dental Care'));
      await tester.pumpAndSettle();

      expect(recordingSearch.lastQuery, equals('dentist'));
      expect(recordingSearch.lastLatitude, equals(19.0760));
      expect(recordingSearch.lastLongitude, equals(72.8777));
    });

    testWidgets('6. Voice query is submitted to the hospital search pipeline with live GPS', (tester) async {
      final mockLocation = MockTestLocationService(position: livePosition);
      final recordingSearch = RecordingHospitalSearchService();
      final mockSpeech = MockSpeechInputService(
        mockResult: 'I need an eye doctor',
        simulatedDelay: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(_buildTestWidget(
        locationService: mockLocation,
        searchService: recordingSearch,
        speechService: mockSpeech,
      ));
      await tester.pumpAndSettle();

      // Tap mic
      final micIcon = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.mic_rounded && w.size == 22.0,
      );
      await tester.tap(micIcon);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Verify the voice query went to search pipeline with live GPS
      expect(recordingSearch.lastQuery, equals('I need an eye doctor'));
      expect(recordingSearch.lastLatitude, equals(19.0760));
      expect(recordingSearch.lastLongitude, equals(72.8777));
    });
  });
}
