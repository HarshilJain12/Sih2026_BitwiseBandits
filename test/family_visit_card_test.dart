import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/theme/app_theme.dart';
import 'package:healthcare_app/models/family.dart';
import 'package:healthcare_app/screens/home_visit/asha_home_visit_screen.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: SizedBox(width: 400, child: child)),
  );
}

Family _sampleFamily() {
  final now = DateTime(2026, 1, 1);
  return Family(
    familyId: 'demo_family_1',
    headOfFamilyName: 'Ramesh Patil',
    address: 'Kondhwa Budruk, Lane 1',
    village: 'Kondhwa',
    ward: 'Ward 4',
    block: 'Haveli',
    district: 'Pune',
    contactNumber: '+91 9822011223',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FamilyVisitCard', () {
    testWidgets('shows name, address, phone and a tappable Visit button',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_testApp(FamilyVisitCard(
        family: _sampleFamily(),
        onVisit: () => tapped = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Ramesh Patil'), findsOneWidget);
      expect(find.text('Kondhwa Budruk, Lane 1'), findsOneWidget);
      expect(find.text('+91 9822011223'), findsOneWidget);

      final visitButton = find.widgetWithText(ElevatedButton, 'Visit');
      expect(visitButton, findsOneWidget);

      // The title must get real horizontal space (regression: it once
      // collapsed to ~1 char wide on web, stacking letters vertically).
      final titleBox =
          tester.getSize(find.text('Ramesh Patil'));
      expect(titleBox.width, greaterThan(100));

      await tester.tap(visitButton);
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('handles empty contact number without crashing',
        (tester) async {
      final now = DateTime(2026, 1, 1);
      final family = Family(
        familyId: 'f2',
        headOfFamilyName: 'Prakash Jadhav',
        address: 'Ward 4',
        village: 'Kondhwa',
        ward: 'Ward 4',
        block: 'Haveli',
        district: 'Pune',
        contactNumber: '',
        createdAt: now,
        updatedAt: now,
      );
      await tester.pumpWidget(
          _testApp(FamilyVisitCard(family: family, onVisit: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Prakash Jadhav'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Visit'), findsOneWidget);
    });
  });
}
