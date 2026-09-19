import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:healthcare_app/l10n/app_localizations.dart';
import 'package:healthcare_app/screens/patient_dashboard/widgets/find_hospital_section.dart';
import 'package:healthcare_app/services/hospital/mock_hospital_search_service.dart';
import 'package:healthcare_app/services/location/location_service.dart';
import 'package:healthcare_app/services/speech/mock_speech_input_service.dart';

class _MockLocationServiceForVoice extends LocationService {
  const _MockLocationServiceForVoice();

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.whileInUse;

  @override
  Future<LocationFetchResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return LocationFetchResult(
      status: LocationFetchStatus.success,
      position: Position(
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
      ),
    );
  }
}

Widget _buildTestWidget({
  required MockSpeechInputService speechService,
  MockHospitalSearchService? searchService,
  LocationService? locationService,
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
          speechService: speechService,
          searchService: searchService ?? MockHospitalSearchService(),
          locationService: locationService ?? const _MockLocationServiceForVoice(),
        ),
      ),
    ),
  );
}

void main() {
  group('FindHospitalSection Voice Input Widget Tests', () {
    testWidgets('1. Tapping microphone triggers voice input and inserts text into TextField', (tester) async {
      final mockSpeech = MockSpeechInputService(
        mockResult: 'I need an eye doctor',
        simulatedDelay: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(_buildTestWidget(speechService: mockSpeech));
      await tester.pumpAndSettle();

      // Verify mic button is present
      final micButton = find.byIcon(Icons.mic_rounded);
      expect(micButton, findsOneWidget);

      // Tap mic button
      await tester.tap(micButton);
      await tester.pump();

      // Verify "Listening..." SnackBar appears
      expect(find.byType(SnackBar), findsOneWidget);

      // Settle simulated speech delay
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Verify recognized text is now in the TextField
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      final textWidget = tester.widget<TextField>(textField);
      expect(textWidget.controller?.text, equals('I need an eye doctor'));
    });

    testWidgets('2. Recognized voice text in TextField is editable by the user', (tester) async {
      final mockSpeech = MockSpeechInputService(
        mockResult: 'tooth pain',
        simulatedDelay: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(_buildTestWidget(speechService: mockSpeech));
      await tester.pumpAndSettle();

      // Speak into mic
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(tester.widget<TextField>(textField).controller?.text, equals('tooth pain'));

      // User edits the text field
      await tester.enterText(textField, 'severe tooth pain and dentist needed');
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(textField).controller?.text, equals('severe tooth pain and dentist needed'));
    });

    testWidgets('3. Voice error displays graceful SnackBar and keeps text search usable', (tester) async {
      final mockSpeech = MockSpeechInputService(
        mockError: 'Microphone permission denied',
      );

      await tester.pumpWidget(_buildTestWidget(speechService: mockSpeech));
      await tester.pumpAndSettle();

      // Tap mic button
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify graceful error message SnackBar
      expect(find.textContaining('Voice input unavailable'), findsOneWidget);

      // Verify user can still type manually in TextField
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'skin doctor');
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(textField).controller?.text, equals('skin doctor'));
    });

    testWidgets('4. Tapping mic while listening stops listening without crash', (tester) async {
      final mockSpeech = MockSpeechInputService(
        simulatedDelay: const Duration(seconds: 5),
      );

      await tester.pumpWidget(_buildTestWidget(speechService: mockSpeech));
      await tester.pumpAndSettle();

      // Find mic button (size 22)
      final micIcon = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.mic_rounded && w.size == 22.0,
      );
      expect(micIcon, findsOneWidget);

      // First tap starts listening
      await tester.tap(micIcon);
      await tester.pump();
      expect(mockSpeech.isListening, isTrue);

      // Verify active listening icon is graphic_eq_rounded
      final activeMicIcon = find.byIcon(Icons.graphic_eq_rounded);
      expect(activeMicIcon, findsOneWidget);

      // Second tap on active mic stops listening
      await tester.tap(activeMicIcon);
      await tester.pump();
      expect(mockSpeech.isListening, isFalse);

      // Mic button icon changes back to mic_rounded (size 22)
      expect(micIcon, findsOneWidget);
    });
  });
}
