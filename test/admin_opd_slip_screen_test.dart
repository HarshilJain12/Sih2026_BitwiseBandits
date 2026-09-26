import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/providers/admin_state_provider.dart';
import 'package:healthcare_app/screens/admin_dashboard/admin_opd_slip_screen.dart';
import 'package:healthcare_app/services/firestore/hospital_admin_service.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HospitalAdminService service;
  late AdminStateProvider adminState;

  setUp(() {
    service = HospitalAdminService()..enableLocalDemo();
    adminState = AdminStateProvider(dataService: service);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<AdminStateProvider>.value(
        value: adminState,
        child: const AdminOpdSlipScreen(),
      ),
    );
  }

  group('AdminOpdSlipScreen Widget Tests', () {
    testWidgets('1. Initial render displays search field and walk-in option', (tester) async {
      await adminState.loadAll();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Fast OPD / Appointment Slip'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('+ New Patient / Walk-in'), findsOneWidget);
    });

    testWidgets('2. Searching "Vikram" displays multiple patients with mobile numbers separately', (tester) async {
      await adminState.loadAll();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Vikram');
      await tester.pumpAndSettle();

      // Both "Vikram Shinde"s and "Vikram Kumar" are displayed
      expect(find.text('Matching Patients (3):'), findsOneWidget);
      expect(find.textContaining('+91 9876543212'), findsWidgets);
      expect(find.textContaining('+91 9123456780'), findsWidgets);
    });

    testWidgets('3. Selecting a patient auto-loads name, age, and QR without manual entry', (tester) async {
      await adminState.loadAll();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Vikram');
      await tester.pumpAndSettle();

      // Tap on the first result
      final firstCard = find.textContaining('+91 9876543212');
      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      // Selected patient card is shown with QR Linked
      expect(find.text('Selected Patient'), findsOneWidget);
      expect(find.text('✓ QR Linked'), findsOneWidget);
      expect(find.text('Which doctor / specialty category?'), findsOneWidget);
      expect(find.text('GENERATE OPD SLIP'), findsOneWidget);
    });

    testWidgets('4. Category chip selection works cleanly', (tester) async {
      await adminState.loadAll();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Vikram');
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('+91 9876543212'));
      await tester.pumpAndSettle();

      // Tap 'Cardiology'
      final cardiologyChip = find.text('Cardiology');
      expect(cardiologyChip, findsOneWidget);
      await tester.tap(cardiologyChip);
      await tester.pumpAndSettle();

      // Tap 'GENERATE OPD SLIP'
      final genBtn = find.text('GENERATE OPD SLIP');
      await tester.ensureVisible(genBtn);
      await tester.tap(genBtn);
      await tester.pumpAndSettle();

      // Dialog appears with slip preview
      expect(find.text('OPD Slip Ready'), findsOneWidget);
      expect(find.text('CARDIOLOGY'), findsOneWidget);
      expect(find.text('REGISTERED'), findsOneWidget);
    });

    testWidgets('5. Walk-in flow creates slip with no QR', (tester) async {
      await adminState.loadAll();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap '+ New Patient / Walk-in'
      final walkInBtn = find.text('+ New Patient / Walk-in');
      await tester.tap(walkInBtn);
      await tester.pumpAndSettle();

      expect(find.text('New Patient / Walk-in'), findsOneWidget);
      expect(find.text('No QR'), findsOneWidget);

      // Enter walk-in details
      final nameField = find.widgetWithText(TextField, 'Patient Name *');
      final ageField = find.widgetWithText(TextField, 'Age *');

      await tester.enterText(nameField, 'Ramesh Walkin');
      await tester.enterText(ageField, '45');
      await tester.pumpAndSettle();

      // Select 'Orthopedics'
      await tester.tap(find.text('Orthopedics'));
      await tester.pumpAndSettle();

      // Generate Slip
      final genBtn = find.text('GENERATE OPD SLIP');
      await tester.ensureVisible(genBtn);
      await tester.tap(genBtn);
      await tester.pumpAndSettle();

      expect(find.text('OPD Slip Ready'), findsOneWidget);
      expect(find.text('ORTHOPEDICS'), findsOneWidget);
      expect(find.text('WALK-IN'), findsOneWidget);
      expect(find.text('• Walk-in Consultation Slip •\n(No QR Assigned)'), findsOneWidget);
    });
  });
}
