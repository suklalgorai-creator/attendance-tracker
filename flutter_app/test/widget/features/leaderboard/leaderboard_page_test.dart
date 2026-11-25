import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter_app/features/leaderboard/domain/entities/leaderboard_entry_entity.dart';
import 'package:flutter_app/features/leaderboard/presentation/pages/leaderboard_page.dart';
import 'package:flutter_app/features/leaderboard/presentation/providers/leaderboard_providers.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const mockEntries = [
    LeaderboardEntryEntity(
      id: 'student-1',
      displayName: 'Top Student',
      attendancePercent: 98.0,
      streak: 15,
      isCurrentUser: false,
    ),
    LeaderboardEntryEntity(
      id: 'my-id',
      displayName: 'Local User',
      attendancePercent: 92.5,
      streak: 8,
      isCurrentUser: true,
    ),
    LeaderboardEntryEntity(
      id: 'student-3',
      displayName: 'Third Student',
      attendancePercent: 80.0,
      streak: 2,
      isCurrentUser: false,
    ),
  ];

  Widget createWidget({
    List<LeaderboardEntryEntity> entries = mockEntries,
    int myRank = 2,
    int streak = 8,
  }) {
    return ProviderScope(
      overrides: [
        leaderboardEntriesProvider.overrideWith((ref) => Future.value(entries)),
        myRankProvider.overrideWithValue(myRank),
        streakCountProvider.overrideWithValue(AsyncValue.data(streak)),
      ],
      child: const MaterialApp(home: Scaffold(body: LeaderboardPage())),
    );
  }

  group('LeaderboardPage Widget Tests', () {
    testWidgets('Renders header card, title, hint, and your rank', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Attendance Leaderboard'), findsOneWidget);
      expect(
        find.text(
          'Display names and calculated attendance percentages are shown.',
        ),
        findsOneWidget,
      );
      expect(find.text('Your Rank'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
    });

    testWidgets(
      'Renders rankings list and highlights current user with You badge',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Class Rankings'), findsOneWidget);
        expect(find.text('Top Student'), findsOneWidget);
        expect(find.text('Local User'), findsOneWidget);
        expect(find.text('You'), findsOneWidget);

        expect(find.text('98.0%'), findsOneWidget);
        expect(find.text('92.5%'), findsOneWidget);
        expect(find.text('80.0%'), findsOneWidget);
      },
    );

    testWidgets('Renders cleanly on 320px narrow width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Attendance Leaderboard'), findsOneWidget);
    });

    testWidgets('Renders empty state message when no entries exist', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(entries: []));
      await tester.pumpAndSettle();

      expect(find.text('No students have opted in yet.'), findsOneWidget);
    });

    testWidgets('Renders error message when leaderboard provider fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leaderboardEntriesProvider.overrideWith(
              (ref) => Future.error(Exception('Network Error')),
            ),
            myRankProvider.overrideWithValue(0),
            streakCountProvider.overrideWithValue(const AsyncValue.data(0)),
          ],
          child: const MaterialApp(home: Scaffold(body: LeaderboardPage())),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Leaderboard is temporarily unavailable.'),
        findsOneWidget,
      );
    });
  });
}
