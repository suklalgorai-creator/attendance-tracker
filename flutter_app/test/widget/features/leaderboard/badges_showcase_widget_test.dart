import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/features/leaderboard/presentation/widgets/badges_showcase_widget.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createWidget({int streak = 5}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BadgesShowcaseWidget(currentStreak: streak),
        ),
      ),
    );
  }

  group('BadgesShowcaseWidget Widget Tests', () {
    testWidgets('Renders title, streak pill, and all 4 badge tiers', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(streak: 5));
      await tester.pumpAndSettle();

      expect(find.text('Streak Badges'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);

      expect(find.text('Bronze'), findsOneWidget);
      expect(find.text('Silver'), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
      expect(find.text('Platinum'), findsOneWidget);
    });

    testWidgets('Renders progress towards next tier', (tester) async {
      await tester.pumpWidget(
        createWidget(streak: 5),
      ); // Next tier is Silver at 7 days
      await tester.pumpAndSettle();

      expect(find.text('2 more days to unlock Silver'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('Renders maximum tier achieved message when streak >= 30', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(streak: 35));
      await tester.pumpAndSettle();

      expect(find.text('👑 Maximum Streak Tier Achieved!'), findsOneWidget);
    });

    testWidgets('Renders cleanly on 320px narrow width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(streak: 8));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Streak Badges'), findsOneWidget);
    });
  });
}
