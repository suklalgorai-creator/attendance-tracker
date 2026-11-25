import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/dashboard/domain/models/dashboard_stats.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/overview_card.dart';

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

  group('OverviewCard Widget Tests', () {
    testWidgets('Renders conducted and present counts with percentage', (
      tester,
    ) async {
      const stats = DashboardStats(
        conducted: 24,
        present: 20,
        absent: 4,
        percentage: 83.333,
        minPercent: 75.0,
        canMiss: 2,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      await tester.pumpWidget(_wrap(const OverviewCard(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('24'), findsOneWidget); // Conducted
      expect(find.text('20'), findsOneWidget); // Present
      expect(find.text('Can miss 2 classes'), findsOneWidget);
    });

    testWidgets(
      'Renders null percentage and no attendance status for 0 conducted',
      (tester) async {
        final stats = DashboardStats.empty(minPercent: 75.0);

        await tester.pumpWidget(_wrap(OverviewCard(stats: stats)));
        await tester.pumpAndSettle();

        expect(
          find.text('0'),
          findsNWidgets(2),
        ); // Conducted and Present both 0
        expect(find.text('No attendance recorded'), findsOneWidget);
        expect(
          find.text('—'),
          findsOneWidget,
        ); // Ring center text for null percent
      },
    );

    testWidgets('Renders danger status text when attendance < minPercent', (
      tester,
    ) async {
      const stats = DashboardStats(
        conducted: 10,
        present: 6,
        absent: 4,
        percentage: 60.0,
        minPercent: 75.0,
        canMiss: 0,
        needToAttend: 6,
        isImpossible: false,
        isSafe: false,
      );

      await tester.pumpWidget(_wrap(const OverviewCard(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('Need 6 attended classes'), findsOneWidget);
    });

    testWidgets('Tapping OverviewCard triggers onTap callback', (tester) async {
      var tapped = false;
      const stats = DashboardStats(
        conducted: 10,
        present: 9,
        absent: 1,
        percentage: 90.0,
        minPercent: 75.0,
        canMiss: 2,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      await tester.pumpWidget(
        _wrap(OverviewCard(stats: stats, onTap: () => tapped = true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OverviewCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
