import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/l10n/app_localizations.dart';
import 'package:healthcare_app/models/medical_record.dart';
import 'package:healthcare_app/models/medical_record_category.dart';
import 'package:healthcare_app/screens/medical_records/widgets/medical_record_card.dart';
import 'package:healthcare_app/services/storage/medical_record_storage.dart';

Widget createTestApp(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MedicalRecordCategory Model Tests', () {
    test('fromId correctly parses category strings', () {
      expect(MedicalRecordCategory.fromId('prescription'), MedicalRecordCategory.prescription);
      expect(MedicalRecordCategory.fromId('lab_report'), MedicalRecordCategory.labReport);
      expect(MedicalRecordCategory.fromId('scan_xray'), MedicalRecordCategory.scanXray);
      expect(MedicalRecordCategory.fromId('discharge_summary'), MedicalRecordCategory.dischargeSummary);
      expect(MedicalRecordCategory.fromId('other'), MedicalRecordCategory.other);
      expect(MedicalRecordCategory.fromId('invalid_id'), MedicalRecordCategory.other);
      expect(MedicalRecordCategory.fromId(null), MedicalRecordCategory.other);
    });

    test('All categories have emojis and icons defined', () {
      for (final cat in MedicalRecordCategory.values) {
        expect(cat.emoji.isNotEmpty, isTrue);
        expect(cat.icon, isNotNull);
        expect(cat.accentColor, isNotNull);
        expect(cat.containerColor, isNotNull);
      }
    });
  });

  group('File Validation Tests', () {
    test('Validates 10 MB maximum file size limit', () {
      expect(MedicalRecordStorage.isValidFileSize(100), isTrue);
      expect(MedicalRecordStorage.isValidFileSize(10 * 1024 * 1024), isTrue);
      expect(MedicalRecordStorage.isValidFileSize(10 * 1024 * 1024 + 1), isFalse);
      expect(MedicalRecordStorage.isValidFileSize(0), isFalse);
      expect(MedicalRecordStorage.isValidFileSize(-1), isFalse);
    });

    test('Validates supported MIME types (PDF, JPG, JPEG, PNG)', () {
      expect(MedicalRecordStorage.isValidMimeType('application/pdf'), isTrue);
      expect(MedicalRecordStorage.isValidMimeType('image/jpeg'), isTrue);
      expect(MedicalRecordStorage.isValidMimeType('image/jpg'), isTrue);
      expect(MedicalRecordStorage.isValidMimeType('image/png'), isTrue);
      expect(MedicalRecordStorage.isValidMimeType('application/zip'), isFalse);
      expect(MedicalRecordStorage.isValidMimeType('video/mp4'), isFalse);
    });
  });

  group('MedicalRecordCard Widget Tests', () {
    final testRecord = MedicalRecord(
      recordId: 'MR-TEST123456',
      patientId: 'P-TEST000001',
      ownerUid: 'uid123',
      originalFileName: 'blood_test_report.pdf',
      storagePath: 'patients/P-TEST000001/medicalRecords/MR-TEST123456/blood_test_report.pdf',
      mimeType: 'application/pdf',
      fileSizeBytes: 2 * 1024 * 1024, // 2.0 MB
      uploadedAt: DateTime(2026, 9, 18),
      updatedAt: DateTime(2026, 9, 18),
      category: 'lab_report',
      notes: 'Test note for blood examination',
    );

    testWidgets('Renders file name, formatted size, date, and category', (tester) async {
      bool openClicked = false;
      bool deleteClicked = false;

      await tester.pumpWidget(
        createTestApp(
          MedicalRecordCard(
            record: testRecord,
            onOpen: () => openClicked = true,
            onDelete: () => deleteClicked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('blood_test_report.pdf'), findsOneWidget);
      expect(find.textContaining('2.0 MB'), findsOneWidget);
      expect(find.textContaining('18 Sep 2026'), findsOneWidget);
      expect(find.text('Lab Report'), findsOneWidget);
      expect(find.text('Test note for blood examination'), findsOneWidget);

      // Tap Open
      await tester.tap(find.text('Open'));
      expect(openClicked, isTrue);

      // Tap Delete icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleteClicked, isTrue);
    });

    testWidgets('Renders localized category in Hindi and Marathi', (tester) async {
      // Hindi
      await tester.pumpWidget(
        createTestApp(
          MedicalRecordCard(
            record: testRecord,
            onOpen: () {},
            onDelete: () {},
          ),
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('लैब रिपोर्ट'), findsOneWidget);

      // Marathi
      await tester.pumpWidget(
        createTestApp(
          MedicalRecordCard(
            record: testRecord,
            onOpen: () {},
            onDelete: () {},
          ),
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('लॅब रिपोर्ट'), findsOneWidget);
    });
  });
}
