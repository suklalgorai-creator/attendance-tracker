import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/calendar/domain/models/calendar_day_summary.dart';
import 'package:flutter_app/features/calendar/domain/services/calendar_analytics_service.dart';

void main() {
  const service = CalendarAnalyticsService();
  final testNow = DateTime(2026, 11, 20);

  AttendanceRecordEntity makeRecord({
    required String id,
    required String date,
    required AttendanceStatus status,
    String subjectId = 'sub-1',
    String sessionId = 'session-1',
    DateTime? deletedAt,
  }) {
    return AttendanceRecordEntity(
      id: id,
      date: date,
      subjectId: subjectId,
      sessionId: sessionId,
      status: status,
      createdAt: testNow,
      updatedAt: testNow,
      deletedAt: deletedAt,
    );
  }

  LegacyAttendanceEntity makeLegacy({
    required String id,
    required String date,
    required int held,
    required int attended,
  }) {
    return LegacyAttendanceEntity(
      id: id,
      date: date,
      held: held,
      attended: attended,
      createdAt: testNow,
      updatedAt: testNow,
    );
  }

  group('CalendarAnalyticsService - computeDaySummary', () {
    test('Returns holiday if date is in holidays map', () {
      final summary = service.computeDaySummary(
        date: '2026-11-20',
        records: [],
        legacyByDate: {},
        holidays: {'2026-11-20': true},
      );

      expect(summary.date, '2026-11-20');
      expect(summary.type, CalendarDayType.holiday);
      expect(summary.held, 0);
      expect(summary.attended, 0);
    });

    test('Returns empty when no records or legacy attendance exist', () {
      final summary = service.computeDaySummary(
        date: '2026-11-20',
        records: [],
        legacyByDate: {},
        holidays: {},
      );

      expect(summary.type, CalendarDayType.empty);
      expect(summary.held, 0);
      expect(summary.attended, 0);
    });

    test('Ignores soft-deleted attendance records', () {
      final records = [
        makeRecord(
          id: 'rec-1',
          date: '2026-11-20',
          status: AttendanceStatus.present,
          deletedAt: testNow,
        ),
      ];

      final summary = service.computeDaySummary(
        date: '2026-11-20',
        records: records,
        legacyByDate: {},
        holidays: {},
      );

      expect(summary.type, CalendarDayType.empty);
      expect(summary.held, 0);
    });

    test('Returns present when all held classes are attended (100%)', () {
      final records = [
        makeRecord(
          id: 'rec-1',
          date: '2026-11-20',
          status: AttendanceStatus.present,
        ),
        makeRecord(
          id: 'rec-2',
          date: '2026-11-20',
          subjectId: 'sub-2',
          status: AttendanceStatus.present,
        ),
      ];

      final summary = service.computeDaySummary(
        date: '2026-11-20',
        records: records,
        legacyByDate: {},
        holidays: {},
      );

      expect(summary.type, CalendarDayType.present);
      expect(summary.held, 2);
      expect(summary.attended, 2);
    });

    test('Returns absent when zero held classes are attended (0%)', () {
      final records = [
        makeRecord(
          id: 'rec-1',
          date: '2026-11-20',
          status: AttendanceStatus.absent,
        ),
      ];

      final summary = service.computeDaySummary(
        date: '2026-11-20',
        records: records,
        legacyByDate: {},
        holidays: {},
      );

      expect(summary.type, CalendarDayType.absent);
      expect(summary.held, 1);
      expect(summary.attended, 0);
    });

    test('Returns partial when some classes are attended and some missed', () {
      final records = [
        makeRecord(
          id: 'rec-1',
          date: '2026-11-20',
          status: AttendanceStatus.present,
        ),
        makeRecord(
          id: 'rec-2',
          date: '2026-11-20',
          subjectId: 'sub-2',
          status: AttendanceStatus.absent,
        ),
      ];

      final summary = service.computeDaySummary(
        date: '2026-11-20',
        records: records,
        legacyByDate: {},
        holidays: {},
      );

      expect(summary.type, CalendarDayType.partial);
      expect(summary.held, 2);
      expect(summary.attended, 1);
    });

    test('Correctly combines session records with legacy attendance', () {
      final records = [
        makeRecord(
          id: 'rec-1',
          date: '2026-11-20',
          status: AttendanceStatus.present,
        ),
      ];
      final legacy = {
        '2026-11-20': makeLegacy(
          id: 'leg-1',
          date: '2026-11-20',
          held: 3,
          attended: 2,
        ),
      };

      final summary = service.computeDaySummary(
        date: '2026-11-20',
        records: records,
        legacyByDate: legacy,
        holidays: {},
      );

      expect(summary.type, CalendarDayType.partial);
      expect(summary.held, 4); // 1 session + 3 legacy
      expect(summary.attended, 3); // 1 session + 2 legacy
    });

    test('Returns holiday if all classes on date were cancelled with 0 held', () {
      final records = [
        makeRecord(
          id: 'rec-1',
          date: '2026-11-20',
          status: AttendanceStatus.cancelled,
        ),
      ];

      final summary = service.computeDaySummary(
        date: '2026-11-20',
        records: records,
        legacyByDate: {},
        holidays: {},
      );

      expect(summary.type, CalendarDayType.holiday);
      expect(summary.held, 0);
      expect(summary.attended, 0);
    });
  });

  group('CalendarAnalyticsService - computeMonthSummary', () {
    test('Calculates held, attended, and holidays accurately', () {
      const daySummaries = [
        CalendarDaySummary(
          date: '2026-11-01',
          type: CalendarDayType.present,
          held: 2,
          attended: 2,
        ),
        CalendarDaySummary(
          date: '2026-11-02',
          type: CalendarDayType.partial,
          held: 3,
          attended: 2,
        ),
        CalendarDaySummary(
          date: '2026-11-03',
          type: CalendarDayType.holiday,
          held: 0,
          attended: 0,
        ),
        CalendarDaySummary(
          date: '2026-11-04',
          type: CalendarDayType.absent,
          held: 1,
          attended: 0,
        ),
        CalendarDaySummary(
          date: '2026-11-05',
          type: CalendarDayType.empty,
          held: 0,
          attended: 0,
        ),
      ];

      final monthSummary = service.computeMonthSummary(
        year: 2026,
        month: 11,
        daySummaries: daySummaries,
      );

      expect(monthSummary.held, 6); // 2 + 3 + 0 + 1 + 0
      expect(monthSummary.attended, 4); // 2 + 2 + 0 + 0 + 0
      expect(monthSummary.holidays, 1);
    });
  });

  group('CalendarAnalyticsService - computeDaysInMonth', () {
    test('Generates correct number of days for February in leap year and non-leap year', () {
      final leapDays = service.computeDaysInMonth(
        year: 2024, // Leap year
        month: 2,
        records: [],
        legacyByDate: {},
        holidays: {},
      );
      expect(leapDays.length, 29);

      final nonLeapDays = service.computeDaysInMonth(
        year: 2025, // Non-leap year
        month: 2,
        records: [],
        legacyByDate: {},
        holidays: {},
      );
      expect(nonLeapDays.length, 28);
    });

    test('Generates 30 days for November', () {
      final novDays = service.computeDaysInMonth(
        year: 2026,
        month: 11,
        records: [],
        legacyByDate: {},
        holidays: {},
      );
      expect(novDays.length, 30);
      expect(novDays.first.date, '2026-11-01');
      expect(novDays.last.date, '2026-11-30');
    });
  });

  group('CalendarAnalyticsService - computeHeatmapRecords', () {
    test('Builds correct map with session records and holidays', () {
      final records = [
        makeRecord(
          id: 'r1',
          date: '2026-11-15',
          status: AttendanceStatus.present,
        ),
      ];
      final legacy = [
        makeLegacy(
          id: 'l1',
          date: '2026-11-16',
          held: 2,
          attended: 0,
        ),
      ];
      final holidays = {'2026-11-17': true};

      final result = service.computeHeatmapRecords(
        records: records,
        legacyRecords: legacy,
        holidays: holidays,
      );

      expect(result['2026-11-15']?.held, 1);
      expect(result['2026-11-15']?.attended, 1);
      expect(result['2026-11-15']?.isHoliday, false);

      expect(result['2026-11-16']?.held, 2);
      expect(result['2026-11-16']?.attended, 0);

      expect(result['2026-11-17']?.isHoliday, true);
    });

    test('computeHeatmapStartDate always returns Sunday for all weekdays', () {
      // Test across all 7 days of the week: Sun Nov 15, 2026 to Sat Nov 21, 2026
      for (int i = 0; i < 7; i++) {
        final anchor = DateTime(2026, 11, 15 + i);
        final start = service.computeHeatmapStartDate(anchor, 26);

        // In Dart, Sunday is weekday 7 (7 % 7 == 0)
        expect(start.weekday % 7, 0,
            reason: 'Failed for anchor ${anchor.toIso8601String()}');

        // Total days between start and current week Saturday is 26 * 7 - 1 = 181
        final currentWeekSaturday = anchor.add(
          Duration(days: 6 - (anchor.weekday % 7)),
        );
        final daySpan = currentWeekSaturday.difference(start).inDays + 1;
        expect(daySpan, 26 * 7);
      }
    });
  });
}
