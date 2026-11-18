import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/dashboard/domain/models/dashboard_stats.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/advisor_banner.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    darkTheme: ThemeData.dark(),
    themeMode: ThemeMode.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AdvisorBanner Widget Tests', () {
    testWidgets('Renders reminder banner when unmarked past sessions exist', (tester) async {
      var reviewTapped = false;
      const stats = DashboardStats(
        conducted: 10,
        present: 8,
        absent: 2,
        percentage: 80.0,
        minPercent: 75.0,
        canMiss: 0,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
        unmarkedPastSessions: 3,
      );

      await tester.pumpWidget(_wrap(AdvisorBanner(
        stats: stats,
        onReviewUnmarked: () => reviewTapped = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Unmarked Sessions'), findsOneWidget);
      expect(find.textContaining('You have 3 unmarked past sessions'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(reviewTapped, isTrue);
    });

    testWidgets('Renders neutral welcome banner when 0 sessions conducted', (tester) async {
      final stats = DashboardStats.empty(minPercent: 75.0);

      await tester.pumpWidget(_wrap(AdvisorBanner(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Attendance Tracker'), findsOneWidget);
      expect(find.textContaining('Log your first class to see smart attendance advice'), findsOneWidget);
    });

    testWidgets('Renders Safe to Bunk banner when attendance is safely above target', (tester) async {
      const stats = DashboardStats(
        conducted: 20,
        present: 18,
        absent: 2,
        percentage: 90.0,
        minPercent: 75.0,
        canMiss: 4,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      await tester.pumpWidget(_wrap(const AdvisorBanner(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('Safe to Bunk'), findsOneWidget);
      expect(find.textContaining('You can safely miss 4 classes while staying above 75%'), findsOneWidget);
    });

    testWidgets('Renders On the Edge banner when safe but canMiss == 0', (tester) async {
      const stats = DashboardStats(
        conducted: 4,
        present: 3,
        absent: 1,
        percentage: 75.0,
        minPercent: 75.0,
        canMiss: 0,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      await tester.pumpWidget(_wrap(const AdvisorBanner(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('On the Edge'), findsOneWidget);
      expect(find.textContaining('You are right at your 75% target'), findsOneWidget);
    });

    testWidgets('Renders Target Unreachable banner when 100% target cannot be met', (tester) async {
      const stats = DashboardStats(
        conducted: 10,
        present: 9,
        absent: 1,
        percentage: 90.0,
        minPercent: 100.0,
        canMiss: 0,
        needToAttend: 0,
        isImpossible: true,
        isSafe: false,
      );

      await tester.pumpWidget(_wrap(const AdvisorBanner(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('Target Unreachable'), findsOneWidget);
      expect(find.textContaining('A 100% target is mathematically unreachable'), findsOneWidget);
    });

    testWidgets('Renders Attendance Warning banner when in danger zone with recovery count', (tester) async {
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

      await tester.pumpWidget(_wrap(const AdvisorBanner(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('Attendance Warning'), findsOneWidget);
      expect(find.textContaining('Attend next 6 consecutive classes to recover to 75%'), findsOneWidget);
    });
  });
}
