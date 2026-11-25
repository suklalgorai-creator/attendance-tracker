import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/streak_badge.dart';
import 'package:flutter_app/shared/widgets/streak_popup_dialog.dart';

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

  group('StreakBadge Widget Tests', () {
    testWidgets('Renders nothing when streak <= 0 and showWhenZero is false', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const StreakBadge(streak: 0)));
      await tester.pumpAndSettle();

      expect(find.text('🔥'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('Renders flame and streak count when streak > 0', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const StreakBadge(streak: 5)));
      await tester.pumpAndSettle();

      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Tapping StreakBadge with custom onTap triggers callback', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(StreakBadge(streak: 7, onTap: () => tapped = true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StreakBadge));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets(
      'Tapping StreakBadge without custom onTap opens StreakPopupDialog',
      (tester) async {
        await tester.pumpWidget(_wrap(const StreakBadge(streak: 12)));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StreakBadge));
        // Pump explicit duration to accommodate repeating animation without timeout
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(StreakPopupDialog), findsOneWidget);
        expect(find.text('12 Day Streak!'), findsOneWidget);
        expect(find.text('Awesome'), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Awesome'));
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
