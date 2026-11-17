import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/shared/widgets/attendance_ring.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) {
  return MaterialApp(
    themeMode: mode,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AttendanceRing Widget Tests', () {
    testWidgets('Renders placeholder dash and target when percent is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const AttendanceRing(
          percent: null,
          minPercent: 75.0,
          animate: false,
        ),
      ));

      expect(find.text('—'), findsOneWidget);
      expect(find.text('%'), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Renders formatted percentage and target when safe', (tester) async {
      await tester.pumpWidget(_wrap(
        const AttendanceRing(
          percent: 85.0,
          minPercent: 75.0,
          animate: false,
        ),
      ));

      expect(find.text('85'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('Renders decimal percentage correctly', (tester) async {
      await tester.pumpWidget(_wrap(
        const AttendanceRing(
          percent: 74.5,
          minPercent: 75.0,
          animate: false,
        ),
      ));

      expect(find.text('74.5'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('Renders in danger state (percent < minPercent)', (tester) async {
      await tester.pumpWidget(_wrap(
        const AttendanceRing(
          percent: 60.0,
          minPercent: 75.0,
          animate: false,
        ),
      ));

      expect(find.text('60'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('Animates smoothly when animate is true', (tester) async {
      await tester.pumpWidget(_wrap(
        const AttendanceRing(
          percent: 90.0,
          minPercent: 75.0,
          animate: true,
        ),
      ));

      // Initially at 0 progress
      await tester.pump();
      expect(find.text('90'), findsOneWidget);

      // Settle the 700ms animation
      await tester.pumpAndSettle();
      expect(find.text('90'), findsOneWidget);
    });

    testWidgets('Renders properly in light mode', (tester) async {
      await tester.pumpWidget(_wrap(
        const AttendanceRing(
          percent: 80.0,
          minPercent: 75.0,
          size: 180.0,
          animate: false,
        ),
        mode: ThemeMode.light,
      ));

      expect(find.text('80'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
      final sizeBoxFinder = find.byType(SizedBox).first;
      final SizedBox box = tester.widget(sizeBoxFinder);
      expect(box.width, 180.0);
      expect(box.height, 180.0);
    });
  });
}
