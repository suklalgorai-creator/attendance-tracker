import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/utils/date_utils.dart';

void main() {
  group('DateRange', () {
    test('contains correctly checks inclusive dates', () {
      const range = DateRange(start: '2026-11-01', end: '2026-11-30');
      expect(range.contains('2026-11-01'), isTrue);
      expect(range.contains('2026-11-15'), isTrue);
      expect(range.contains('2026-11-30'), isTrue);
      expect(range.contains('2026-10-31'), isFalse);
      expect(range.contains('2026-12-01'), isFalse);
    });

    test('implements value equality and hashCode', () {
      const r1 = DateRange(start: '2026-11-01', end: '2026-11-30');
      const r2 = DateRange(start: '2026-11-01', end: '2026-11-30');
      const r3 = DateRange(start: '2026-11-02', end: '2026-11-30');

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
      expect(r1.toString(), contains('DateRange(start: 2026-11-01, end: 2026-11-30)'));
    });
  });

  group('formatDateKey', () {
    test('formats standard date with zero padding', () {
      expect(formatDateKey(DateTime(2026, 11, 18)), equals('2026-11-18'));
      expect(formatDateKey(DateTime(2026, 5, 4)), equals('2026-05-04'));
      expect(formatDateKey(DateTime(2024, 2, 29)), equals('2024-02-29'));
      expect(AppDateUtils.formatDateKey(DateTime(2026, 1, 1)), equals('2026-01-01'));
    });
  });

  group('parseDateOnly', () {
    test('parses valid YYYY-MM-DD date string', () {
      final dt = parseDateOnly('2026-11-18');
      expect(dt, isNotNull);
      expect(dt!.year, equals(2026));
      expect(dt.month, equals(11));
      expect(dt.day, equals(18));
      expect(AppDateUtils.parseDateOnly('2026-11-18'), isNotNull);
    });

    test('rejects malformed strings', () {
      expect(parseDateOnly(null), isNull);
      expect(parseDateOnly(''), isNull);
      expect(parseDateOnly('invalid'), isNull);
      expect(parseDateOnly('2026/11/18'), isNull);
      expect(parseDateOnly('18-11-2026'), isNull);
      expect(parseDateOnly('2026-1-1'), isNull);
      expect(parseDateOnly('2026-11-18T10:00:00Z'), isNull);
    });

    test('rejects impossible calendar dates without overflow', () {
      expect(parseDateOnly('2026-02-29'), isNull); // 2026 is non-leap
      expect(parseDateOnly('2026-02-30'), isNull);
      expect(parseDateOnly('2026-04-31'), isNull);
      expect(parseDateOnly('2026-13-01'), isNull);
      expect(parseDateOnly('2026-00-10'), isNull);
    });

    test('accepts leap year February 29', () {
      final dt = parseDateOnly('2024-02-29');
      expect(dt, isNotNull);
      expect(dt!.year, equals(2024));
      expect(dt.month, equals(2));
      expect(dt.day, equals(29));
    });
  });

  group('isDateOnly', () {
    test('returns true for valid dates and false for invalid', () {
      expect(isDateOnly('2026-11-18'), isTrue);
      expect(isDateOnly('2026-02-30'), isFalse);
      expect(isDateOnly('random'), isFalse);
      expect(isDateOnly(null), isFalse);
      expect(AppDateUtils.isDateOnly('2026-11-18'), isTrue);
    });
  });

  group('todayStr', () {
    test('returns YYYY-MM-DD string for current or mock date', () {
      final mock = DateTime(2026, 11, 18);
      expect(todayStr(mock), equals('2026-11-18'));
      expect(isDateOnly(todayStr()), isTrue);
      expect(AppDateUtils.todayStr(mock), equals('2026-11-18'));
    });
  });

  group('addDays', () {
    test('shifts date correctly forward and backward', () {
      expect(addDays('2026-11-18', 0), equals('2026-11-18'));
      expect(addDays('2026-11-18', 1), equals('2026-11-19'));
      expect(addDays('2026-11-18', -1), equals('2026-11-17'));
      expect(AppDateUtils.addDays('2026-11-18', 2), equals('2026-11-20'));
    });

    test('handles month and year boundaries correctly', () {
      expect(addDays('2026-01-31', 1), equals('2026-02-01'));
      expect(addDays('2026-03-01', -1), equals('2026-02-28'));
      expect(addDays('2024-03-01', -1), equals('2024-02-29'));
      expect(addDays('2026-12-31', 1), equals('2027-01-01'));
      expect(addDays('2026-01-01', -1), equals('2025-12-31'));
    });

    test('returns null for invalid date', () {
      expect(addDays('invalid', 5), isNull);
    });
  });

  group('isClassDay', () {
    // 2026-11-18 is Wednesday (day 3)
    // 2026-11-22 is Sunday (day 0)
    // 2026-11-21 is Saturday (day 6)
    final monToFri = [1, 2, 3, 4, 5];

    test('identifies weekday vs weekend based on 0=Sun..6=Sat convention', () {
      expect(isClassDay('2026-11-18', monToFri), isTrue); // Wed = 3
      expect(isClassDay('2026-11-22', monToFri), isFalse); // Sun = 0
      expect(isClassDay('2026-11-21', monToFri), isFalse); // Sat = 6
      expect(isClassDay('2026-11-22', [0, 6]), isTrue); // Sunday in weekend list
      expect(AppDateUtils.isClassDay('2026-11-18', monToFri), isTrue);
    });

    test('returns false for invalid date or empty classDays', () {
      expect(isClassDay('invalid', monToFri), isFalse);
      expect(isClassDay('2026-11-18', []), isFalse);
    });
  });

  group('dateRangeDesc', () {
    test('produces descending list from end to start', () {
      final range = dateRangeDesc('2026-11-15', '2026-11-18');
      expect(range, equals(['2026-11-18', '2026-11-17', '2026-11-16', '2026-11-15']));
    });

    test('handles single day range (start == end)', () {
      expect(dateRangeDesc('2026-11-18', '2026-11-18'), equals(['2026-11-18']));
    });

    test('returns empty list when start > end or inputs invalid', () {
      expect(dateRangeDesc('2026-11-18', '2026-11-10'), isEmpty);
      expect(dateRangeDesc('invalid', '2026-11-18'), isEmpty);
      expect(dateRangeDesc('2026-11-18', 'invalid'), isEmpty);
    });

    test('spans across month boundary in descending order', () {
      final range = dateRangeDesc('2026-10-30', '2026-11-02');
      expect(range, equals(['2026-11-02', '2026-11-01', '2026-10-31', '2026-10-30']));
    });

    test('enforces 3000 safety limit', () {
      final range = dateRangeDesc('2010-01-01', '2026-01-01');
      expect(range.length, equals(3000));
    });
  });

  group('getCurrentWeekRangeStr', () {
    test('computes Monday-Sunday week range for Wednesday', () {
      final wednesday = DateTime(2026, 11, 18);
      final range = getCurrentWeekRangeStr(wednesday);
      expect(range.start, equals('2026-11-16')); // Monday
      expect(range.end, equals('2026-11-22')); // Sunday
    });

    test('computes Monday-Sunday week range for Monday', () {
      final monday = DateTime(2026, 11, 16);
      final range = getCurrentWeekRangeStr(monday);
      expect(range.start, equals('2026-11-16'));
      expect(range.end, equals('2026-11-22'));
    });

    test('computes Monday-Sunday week range for Sunday', () {
      final sunday = DateTime(2026, 11, 22);
      final range = getCurrentWeekRangeStr(sunday);
      expect(range.start, equals('2026-11-16'));
      expect(range.end, equals('2026-11-22'));
    });

    test('spans month boundary across Monday to Sunday', () {
      // 2026-04-01 is Wednesday. Week starts Monday 2026-03-30, ends Sunday 2026-04-05.
      final wed = DateTime(2026, 4, 1);
      final range = getCurrentWeekRangeStr(wed);
      expect(range.start, equals('2026-03-30'));
      expect(range.end, equals('2026-04-05'));
    });
  });

  group('getCurrentMonthRangeStr', () {
    test('computes first and last day for 30-day month (November)', () {
      final range = getCurrentMonthRangeStr(DateTime(2026, 11, 18));
      expect(range.start, equals('2026-11-01'));
      expect(range.end, equals('2026-11-30'));
    });

    test('computes first and last day for 31-day month (December)', () {
      final range = getCurrentMonthRangeStr(DateTime(2026, 12, 10));
      expect(range.start, equals('2026-12-01'));
      expect(range.end, equals('2026-12-31'));
    });

    test('computes first and last day for leap February (2024)', () {
      final range = getCurrentMonthRangeStr(DateTime(2024, 2, 15));
      expect(range.start, equals('2024-02-01'));
      expect(range.end, equals('2024-02-29'));
    });

    test('computes first and last day for non-leap February (2026)', () {
      final range = getCurrentMonthRangeStr(DateTime(2026, 2, 15));
      expect(range.start, equals('2026-02-01'));
      expect(range.end, equals('2026-02-28'));
    });
  });

  group('classDayRangeDesc', () {
    test('filters descending range to include only class days', () {
      // 2026-11-16 (Mon), 17 (Tue), 18 (Wed), 19 (Thu), 20 (Fri), 21 (Sat), 22 (Sun)
      final range = classDayRangeDesc('2026-11-16', '2026-11-22', [1, 3, 5]); // Mon, Wed, Fri
      expect(range, equals(['2026-11-20', '2026-11-18', '2026-11-16']));
      expect(AppDateUtils.classDayRangeDesc('2026-11-16', '2026-11-22', [1, 3, 5]), equals(['2026-11-20', '2026-11-18', '2026-11-16']));
    });

    test('returns empty when no class days in range', () {
      final range = classDayRangeDesc('2026-11-21', '2026-11-22', [1, 2, 3]);
      expect(range, isEmpty);
    });
  });

  group('getPeriodsForDate', () {
    final timetableMapInt = {
      3: ['Math', 'Physics'], // Wednesday = 3
    };
    final timetableMapStr = {
      '3': ['Math', 'Physics'],
    };
    final timetableList = [
      [], // 0 Sun
      ['CS'], // 1 Mon
      [], // 2 Tue
      ['Math', 'Physics'], // 3 Wed
      [], // 4 Thu
      [], // 5 Fri
      [], // 6 Sat
    ];

    test('resolves sessions from map with int keys', () {
      expect(getPeriodsForDate<String>('2026-11-18', timetableMapInt), equals(['Math', 'Physics']));
      expect(AppDateUtils.getPeriodsForDate<String>('2026-11-18', timetableMapInt), equals(['Math', 'Physics']));
    });

    test('resolves sessions from map with String keys', () {
      expect(getPeriodsForDate<String>('2026-11-18', timetableMapStr), equals(['Math', 'Physics']));
    });

    test('resolves sessions from list', () {
      expect(getPeriodsForDate<String>('2026-11-18', timetableList), equals(['Math', 'Physics']));
      expect(getPeriodsForDate<String>('2026-11-16', timetableList), equals(['CS']));
    });

    test('returns empty list for invalid date or missing sessions', () {
      expect(getPeriodsForDate<String>('invalid', timetableMapInt), isEmpty);
      expect(getPeriodsForDate<String>('2026-11-19', timetableMapInt), isEmpty);
      expect(getPeriodsForDate<String>('2026-11-18', null), isEmpty);
    });
  });

  group('formatDateLabel', () {
    test('formats dates according to en_IN locale (d MMM)', () {
      expect(formatDateLabel('2026-11-17'), equals('17 Nov'));
      expect(formatDateLabel('2026-05-04'), equals('4 May'));
      expect(formatDateLabel('2026-01-01'), equals('1 Jan'));
      expect(AppDateUtils.formatDateLabel('2026-11-17'), equals('17 Nov'));
    });

    test('returns original string on invalid date', () {
      expect(formatDateLabel('invalid'), equals('invalid'));
      expect(formatDateLabel(''), equals(''));
    });
  });

  group('formatDateFull', () {
    test('formats dates according to en_IN locale (d MMMM y)', () {
      expect(formatDateFull('2026-11-17'), equals('17 November 2026'));
      expect(formatDateFull('2026-05-04'), equals('4 May 2026'));
      expect(AppDateUtils.formatDateFull('2026-11-17'), equals('17 November 2026'));
    });

    test('returns original string on invalid date', () {
      expect(formatDateFull('invalid'), equals('invalid'));
    });
  });
}
