import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/app/app.dart';

void main() {
  setUpAll(() {
    // Disable runtime font fetching to keep widget tests deterministic & offline
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppRouter & Shell Navigation Widget Tests', () {
    testWidgets('Initial route displays DashboardPage and AppShell', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: AttendanceApp()),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Attendance'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Tapping bottom tabs switches branches preserving state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: AttendanceApp()),
      );
      await tester.pumpAndSettle();

      // Tap Register Tab
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      expect(find.text('Register View'), findsOneWidget);

      // Tap Leaderboard Tab
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      expect(find.text('Leaderboard View'), findsOneWidget);

      // Tap Settings Tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings View'), findsOneWidget);

      // Return to Home Tab
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Opening Drawer and selecting Sticky Notes pushes /notes', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: AttendanceApp()),
      );
      await tester.pumpAndSettle();

      // Tap hamburger menu button
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Sticky Notes'), findsOneWidget);

      // Tap Sticky Notes item
      await tester.tap(find.text('Sticky Notes'));
      await tester.pumpAndSettle();

      expect(find.text('Sticky Notes Page'), findsOneWidget);
    });

    testWidgets('Header theme toggle reacts immediately in MaterialApp', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: AttendanceApp()),
      );
      await tester.pumpAndSettle();

      // Default is dark mode -> header displays sun emoji to switch to light
      expect(find.text('☀️'), findsOneWidget);

      // Tap theme switch button
      await tester.tap(find.text('☀️'));
      await tester.pumpAndSettle();

      // State switches to light mode -> header displays moon emoji to switch to dark
      expect(find.text('🌙'), findsOneWidget);
    });
  });
}
