import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/utils/date_utils.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/register/presentation/widgets/day_row.dart';

void main() {
  Widget buildTestableWidget({
    required String dateStr,
    LegacyAttendanceEntity? legacyRecord,
    bool isToday = false,
    bool isHoliday = false,
    void Function({
      required String date,
      required int held,
      required int attended,
    })?
    onSaveDaily,
    void Function(String id)? onDeleteDaily,
    Brightness brightness = Brightness.dark,
    double width = 400.0,
  }) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: DayRow(
              dateStr: dateStr,
              legacyRecord: legacyRecord,
              isToday: isToday,
              isHoliday: isHoliday,
              onSaveDaily:
                  onSaveDaily ??
                  ({required date, required held, required attended}) {},
              onDeleteDaily: onDeleteDaily ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('DayRow Status Display (All 7 States)', () {
    testWidgets('renders "Holiday" status when isHoliday=true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(dateStr: '2026-11-10', isHoliday: true),
      );

      expect(find.text('Holiday'), findsOneWidget);
      expect(find.text('DAILY ATTENDANCE'), findsNothing);
    });

    testWidgets('renders "Upcoming" status and 65% opacity for future date', (
      tester,
    ) async {
      final futureDate = AppDateUtils.addDays(AppDateUtils.todayStr(), 5)!;
      await tester.pumpWidget(buildTestableWidget(dateStr: futureDate));

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('DAILY ATTENDANCE'), findsNothing);

      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder, findsOneWidget);
      final opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, equals(0.65));
    });

    testWidgets(
      'renders "Not marked" status for past date with no legacy record',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(dateStr: '2026-10-15', legacyRecord: null),
        );

        expect(find.text('Not marked'), findsOneWidget);
        expect(find.text('DAILY ATTENDANCE'), findsOneWidget);
      },
    );

    testWidgets('renders "Holiday / No class" status when held=0', (
      tester,
    ) async {
      final record = LegacyAttendanceEntity(
        id: 'daily-2026-10-15',
        date: '2026-10-15',
        held: 0,
        attended: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(dateStr: '2026-10-15', legacyRecord: record),
      );

      // In header, status text should be Holiday / No class
      expect(find.text('Holiday / No class'), findsWidgets);
    });

    testWidgets('renders "Present" status when held > 0 and attended == held', (
      tester,
    ) async {
      final record = LegacyAttendanceEntity(
        id: 'daily-2026-10-15',
        date: '2026-10-15',
        held: 2,
        attended: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(dateStr: '2026-10-15', legacyRecord: record),
      );

      expect(find.text('Present'), findsWidgets);
    });

    testWidgets('renders "Absent" status when held > 0 and attended == 0', (
      tester,
    ) async {
      final record = LegacyAttendanceEntity(
        id: 'daily-2026-10-15',
        date: '2026-10-15',
        held: 2,
        attended: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(dateStr: '2026-10-15', legacyRecord: record),
      );

      expect(find.text('Absent'), findsWidgets);
    });

    testWidgets('renders "Partial · X/Y" status when 0 < attended < held', (
      tester,
    ) async {
      final record = LegacyAttendanceEntity(
        id: 'daily-2026-10-15',
        date: '2026-10-15',
        held: 3,
        attended: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(dateStr: '2026-10-15', legacyRecord: record),
      );

      expect(find.text('Partial · 1/3'), findsOneWidget);
    });
  });

  group('DayRow Badges and Buttons', () {
    testWidgets('renders TODAY badge only when isToday=true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(dateStr: '2026-11-18', isToday: true),
      );

      expect(find.text('TODAY'), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(dateStr: '2026-11-18', isToday: false),
      );

      expect(find.text('TODAY'), findsNothing);
    });

    testWidgets(
      'when legacyRecord is null, renders Present, Absent, Holiday buttons and NO Clear button',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(dateStr: '2026-10-15', legacyRecord: null),
        );

        expect(find.text('Present'), findsOneWidget);
        expect(find.text('Absent'), findsOneWidget);
        expect(find.text('Holiday / No class'), findsOneWidget);
        expect(find.text('Clear'), findsNothing);
      },
    );

    testWidgets('when legacyRecord is present, renders Clear button', (
      tester,
    ) async {
      final record = LegacyAttendanceEntity(
        id: 'daily-2026-10-15',
        date: '2026-10-15',
        held: 1,
        attended: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(dateStr: '2026-10-15', legacyRecord: record),
      );

      expect(find.text('Clear'), findsNothing);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('tapping Present calls onSaveDaily with held=1, attended=1', (
      tester,
    ) async {
      String? savedDate;
      int? savedHeld;
      int? savedAttended;

      await tester.pumpWidget(
        buildTestableWidget(
          dateStr: '2026-10-15',
          onSaveDaily: ({required date, required held, required attended}) {
            savedDate = date;
            savedHeld = held;
            savedAttended = attended;
          },
        ),
      );

      await tester.tap(find.text('Present'));
      await tester.pump();

      expect(savedDate, equals('2026-10-15'));
      expect(savedHeld, equals(1));
      expect(savedAttended, equals(1));
    });

    testWidgets('tapping Absent calls onSaveDaily with held=1, attended=0', (
      tester,
    ) async {
      String? savedDate;
      int? savedHeld;
      int? savedAttended;

      await tester.pumpWidget(
        buildTestableWidget(
          dateStr: '2026-10-15',
          onSaveDaily: ({required date, required held, required attended}) {
            savedDate = date;
            savedHeld = held;
            savedAttended = attended;
          },
        ),
      );

      await tester.tap(find.text('Absent'));
      await tester.pump();

      expect(savedDate, equals('2026-10-15'));
      expect(savedHeld, equals(1));
      expect(savedAttended, equals(0));
    });

    testWidgets(
      'tapping Holiday / No class calls onSaveDaily with held=0, attended=0',
      (tester) async {
        String? savedDate;
        int? savedHeld;
        int? savedAttended;

        await tester.pumpWidget(
          buildTestableWidget(
            dateStr: '2026-10-15',
            onSaveDaily: ({required date, required held, required attended}) {
              savedDate = date;
              savedHeld = held;
              savedAttended = attended;
            },
          ),
        );

        await tester.tap(find.text('Holiday / No class'));
        await tester.pump();

        expect(savedDate, equals('2026-10-15'));
        expect(savedHeld, equals(0));
        expect(savedAttended, equals(0));
      },
    );

    testWidgets('tapping Clear calls onDeleteDaily with record id', (
      tester,
    ) async {
      String? deletedId;
      final record = LegacyAttendanceEntity(
        id: 'rec-test-123',
        date: '2026-10-15',
        held: 1,
        attended: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          dateStr: '2026-10-15',
          legacyRecord: record,
          onDeleteDaily: (id) => deletedId = id,
        ),
      );

      // Collapsed by default when already marked
      expect(find.text('DAILY ATTENDANCE'), findsNothing);
      expect(find.text('Clear'), findsNothing);

      // Tap edit icon to expand and tap Clear
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(find.text('DAILY ATTENDANCE'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(deletedId, equals('rec-test-123'));
    });
  });

  group('DayRow Small-Screen Viewport Assertions (320px width)', () {
    testWidgets('does not overflow on 320px screen width', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final record = LegacyAttendanceEntity(
        id: 'daily-2026-10-15',
        date: '2026-10-15',
        held: 1,
        attended: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          dateStr: '2026-10-15',
          legacyRecord: record,
          isToday: true,
          width: 320,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('DAILY ATTENDANCE'), findsNothing);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('DAILY ATTENDANCE'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });
  });
}
