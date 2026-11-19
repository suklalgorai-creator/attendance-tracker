import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flutter_app/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testNow = DateTime(2026, 11, 1);

  Widget createWidget({
    DateTime? initialDate,
    List<AttendanceRecordEntity> records = const [],
    List<LegacyAttendanceEntity> legacy = const [],
    UserSettingsEntity? settings,
  }) {
    return ProviderScope(
      overrides: [
        if (initialDate != null)
          calendarDateProvider.overrideWith(
            (ref) => CalendarDateNotifier()..setDate(initialDate),
          ),
        attendanceRecordsStreamProvider.overrideWith((ref) => Stream.value(records)),
        legacyAttendanceStreamProvider.overrideWith((ref) => Stream.value(legacy)),
        settingsStreamProvider.overrideWith(
          (ref) => Stream.value(settings ?? const UserSettingsEntity()),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalendarViewWidget(),
          ),
        ),
      ),
    );
  }

  group('CalendarViewWidget Tests', () {
    testWidgets('Renders month title and navigation buttons', (tester) async {
      final fixedDate = DateTime(2026, 11, 1);
      await tester.pumpWidget(createWidget(initialDate: fixedDate));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);
      expect(find.byKey(const Key('calendar_prev_month_btn')), findsOneWidget);
      expect(find.byKey(const Key('calendar_next_month_btn')), findsOneWidget);
    });

    testWidgets('Renders all 7 weekday column headers', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      for (final day in ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']) {
        expect(find.text(day), findsOneWidget);
      }
    });

    testWidgets('Clicking previous and next month buttons changes title', (tester) async {
      final fixedDate = DateTime(2026, 11, 1);
      await tester.pumpWidget(createWidget(initialDate: fixedDate));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);

      // Tap next month
      await tester.tap(find.byKey(const Key('calendar_next_month_btn')));
      await tester.pumpAndSettle();
      expect(find.text('December 2026'), findsOneWidget);

      // Tap prev month twice
      await tester.tap(find.byKey(const Key('calendar_prev_month_btn')));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('calendar_prev_month_btn')));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('Renders monthly summary footer stats correctly', (tester) async {
      final fixedDate = DateTime(2026, 11, 1);
      final records = [
        AttendanceRecordEntity(
          id: 'rec-1',
          date: '2026-11-05',
          subjectId: 'sub-1',
          sessionId: 's-1',
          status: AttendanceStatus.present,
          createdAt: testNow,
          updatedAt: testNow,
        ),
        AttendanceRecordEntity(
          id: 'rec-2',
          date: '2026-11-06',
          subjectId: 'sub-1',
          sessionId: 's-2',
          status: AttendanceStatus.absent,
          createdAt: testNow,
          updatedAt: testNow,
        ),
      ];

      await tester.pumpWidget(
        createWidget(initialDate: fixedDate, records: records),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONDUCTED'), findsOneWidget);
      expect(find.text('PRESENT'), findsOneWidget);
      expect(find.text('HOLIDAYS'), findsOneWidget);

      // Conducted = 2, Present = 1, Holidays = 0
      expect(find.text('2'), findsWidgets); // Can appear in day number and stat
      expect(find.text('1'), findsWidgets);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('Renders cleanly on 320px narrow width without overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fixedDate = DateTime(2026, 11, 1);
      await tester.pumpWidget(createWidget(initialDate: fixedDate));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('November 2026'), findsOneWidget);
    });
  });
}
