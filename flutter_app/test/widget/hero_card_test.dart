import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/shared/widgets/hero_card.dart';
import 'package:flutter_app/shared/widgets/attendance_ring.dart';
import 'package:flutter_app/shared/widgets/stat_row_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('HeroCardWidget Tests', () {
    testWidgets('Renders AttendanceRing and StatRow widgets', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HeroCardWidget(
            percent: 85.0,
            minPercent: 75.0,
            conducted: 20,
            present: 17,
            canMiss: 2,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AttendanceRing), findsOneWidget);
      expect(find.byType(StatRowWidget), findsNWidgets(3));
      expect(find.text('CONDUCTED'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('PRESENT'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('Can miss 2 classes'), findsOneWidget);
    });

    testWidgets('Displays none status text when percent is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const HeroCardWidget(
            percent: null,
            minPercent: 75.0,
            conducted: 0,
            present: 0,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No attendance recorded'), findsOneWidget);
    });

    testWidgets(
      'Displays danger status recovery message when percent < minPercent',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const HeroCardWidget(
              percent: 60.0,
              minPercent: 75.0,
              conducted: 20,
              present: 12,
              needToAttend: 4,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Need 4 attended classes'), findsOneWidget);
      },
    );

    testWidgets('Displays unreachable message when impossible is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const HeroCardWidget(
            percent: 95.0,
            minPercent: 100.0,
            conducted: 20,
            present: 19,
            isImpossible: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('100% target is unreachable'), findsOneWidget);
    });

    testWidgets('Tapping HeroCard invokes onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          HeroCardWidget(
            percent: 80.0,
            conducted: 10,
            present: 8,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
      'Renders cleanly under 280px narrow width constraint without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeroCardWidget(
                conducted: 24,
                present: 20,
                minPercent: 75.0,
                statusText: 'Can miss 2 classes',
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(HeroCardWidget), findsOneWidget);
        expect(find.text('CONDUCTED'), findsOneWidget);
        expect(find.text('24'), findsOneWidget);
        expect(find.text('PRESENT'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('STATUS'), findsOneWidget);
        expect(find.text('Can miss 2 classes'), findsOneWidget);
      },
    );
  });
}
