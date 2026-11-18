/// Represents an inclusive date range [start, end] in YYYY-MM-DD format.
class DateRange {
  final String start;
  final String end;

  const DateRange({required this.start, required this.end});

  /// Checks if [dateStr] falls inclusively within this range.
  bool contains(String dateStr) =>
      dateStr.compareTo(start) >= 0 && dateStr.compareTo(end) <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => 'DateRange(start: $start, end: $end)';
}

const List<String> _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

const List<String> _fullMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

/// Pure date manipulation utilities matching `react_app/src/utils/date.js`.
abstract final class AppDateUtils {
  /// Converts a [DateTime] into a YYYY-MM-DD date key in local calendar time.
  static String formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Parses a YYYY-MM-DD string into a [DateTime] at local midnight (00:00:00).
  /// Strictly validates format and calendar day existence (rejects invalid days like 2026-02-30).
  static DateTime? parseDateOnly(String? dateStr) {
    if (dateStr == null) return null;
    final regExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regExp.hasMatch(dateStr)) return null;

    final parts = dateStr.split('-');
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    final date = DateTime(year, month, day);
    // Dart DateTime normalizes invalid dates (e.g. Feb 30 -> Mar 2).
    // Checking exact match ensures invalid dates are rejected.
    if (date.year != year || date.month != month || date.day != day) return null;

    return date;
  }

  /// Returns `true` if [dateStr] is a valid YYYY-MM-DD date string.
  static bool isDateOnly(String? dateStr) => parseDateOnly(dateStr) != null;

  /// Returns today's date formatted as YYYY-MM-DD.
  /// Accepts optional [now] for deterministic unit testing.
  static String todayStr([DateTime? now]) {
    return formatDateKey(now ?? DateTime.now());
  }

  /// Adds [n] calendar days to [dateStr] (supports negative [n]).
  /// Avoids DST drift by constructing year, month, day + n.
  /// Returns null if [dateStr] is invalid.
  static String? addDays(String dateStr, int n) {
    final date = parseDateOnly(dateStr);
    if (date == null) return null;
    final shifted = DateTime(date.year, date.month, date.day + n);
    return formatDateKey(shifted);
  }

  /// Returns `true` if [dateStr] is one of the days in [classDays].
  /// Day indexing follows JavaScript `getDay()`: 0 = Sun, 1 = Mon ... 6 = Sat.
  static bool isClassDay(String dateStr, List<int> classDays) {
    final date = parseDateOnly(dateStr);
    if (date == null) return false;
    // Dart weekday: 1 = Mon ... 7 = Sun. Modulo 7 converts to: 0 = Sun ... 6 = Sat.
    final dayOfWeek = date.weekday % 7;
    return classDays.contains(dayOfWeek);
  }

  /// Generates a descending list of dates from [endStr] down to [startStr].
  /// Enforces a 3000 iteration safety limit. Returns empty list if invalid or start > end.
  static List<String> dateRangeDesc(String startStr, String endStr) {
    if (!isDateOnly(startStr) || !isDateOnly(endStr) || startStr.compareTo(endStr) > 0) {
      return const [];
    }
    final out = <String>[];
    String? cursor = endStr;
    var safety = 0;
    while (cursor != null && cursor.compareTo(startStr) >= 0 && safety < 3000) {
      out.add(cursor);
      cursor = addDays(cursor, -1);
      safety++;
    }
    return out;
  }

  /// Returns the current week's range starting Monday and ending Sunday.
  /// Accepts optional [now] for deterministic testing.
  static DateRange getCurrentWeekRangeStr([DateTime? now]) {
    final current = now ?? DateTime.now();
    // In Dart: weekday 1 = Mon, ..., 7 = Sun.
    // Days since Monday is (weekday - 1).
    final daysSinceMonday = current.weekday - 1;
    final monday = DateTime(current.year, current.month, current.day - daysSinceMonday);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    return DateRange(
      start: formatDateKey(monday),
      end: formatDateKey(sunday),
    );
  }

  /// Returns the current month's range from 1st day to last day.
  /// Accepts optional [now] for deterministic testing.
  static DateRange getCurrentMonthRangeStr([DateTime? now]) {
    final current = now ?? DateTime.now();
    final firstDay = DateTime(current.year, current.month, 1);
    // In Dart: day 0 of month + 1 normalizes to the last day of month.
    final lastDay = DateTime(current.year, current.month + 1, 0);
    return DateRange(
      start: formatDateKey(firstDay),
      end: formatDateKey(lastDay),
    );
  }

  /// Generates a descending list of dates between [startStr] and [endStr] filtered by [classDays].
  static List<String> classDayRangeDesc(
    String startStr,
    String endStr,
    List<int> classDays,
  ) {
    return dateRangeDesc(startStr, endStr)
        .where((date) => isClassDay(date, classDays))
        .toList();
  }

  /// Returns timetable sessions for [dateStr].
  /// Supports [timetable] as a `Map` (with `int` or `String` day keys 0..6) or `List`.
  static List<T> getPeriodsForDate<T>(String dateStr, dynamic timetable) {
    final date = parseDateOnly(dateStr);
    if (date == null || timetable == null) return <T>[];
    final day = date.weekday % 7;
    dynamic sessions;
    if (timetable is Map) {
      sessions = timetable[day] ?? timetable[day.toString()];
    } else if (timetable is List && day >= 0 && day < timetable.length) {
      sessions = timetable[day];
    }
    if (sessions is List) {
      if (T == dynamic) {
        return sessions.toList().cast<T>();
      }
      return sessions.whereType<T>().toList();
    }
    return <T>[];
  }

  /// Formats date for row display (e.g., "17 Nov", "4 May") matching React en-IN format.
  /// Falls back to [dateStr] if parsing fails.
  static String formatDateLabel(String dateStr) {
    final date = parseDateOnly(dateStr);
    if (date == null) return dateStr;
    return '${date.day} ${_shortMonths[date.month - 1]}';
  }

  /// Formats full date (e.g., "17 November 2026") matching React en-IN format.
  /// Falls back to [dateStr] if parsing fails.
  static String formatDateFull(String dateStr) {
    final date = parseDateOnly(dateStr);
    if (date == null) return dateStr;
    return '${date.day} ${_fullMonths[date.month - 1]} ${date.year}';
  }
}

// Top-level function exports
String formatDateKey(DateTime date) => AppDateUtils.formatDateKey(date);
DateTime? parseDateOnly(String? dateStr) => AppDateUtils.parseDateOnly(dateStr);
bool isDateOnly(String? dateStr) => AppDateUtils.isDateOnly(dateStr);
String todayStr([DateTime? now]) => AppDateUtils.todayStr(now);
String? addDays(String dateStr, int n) => AppDateUtils.addDays(dateStr, n);
bool isClassDay(String dateStr, List<int> classDays) =>
    AppDateUtils.isClassDay(dateStr, classDays);
List<String> dateRangeDesc(String startStr, String endStr) =>
    AppDateUtils.dateRangeDesc(startStr, endStr);
DateRange getCurrentWeekRangeStr([DateTime? now]) =>
    AppDateUtils.getCurrentWeekRangeStr(now);
DateRange getCurrentMonthRangeStr([DateTime? now]) =>
    AppDateUtils.getCurrentMonthRangeStr(now);
List<String> classDayRangeDesc(
  String startStr,
  String endStr,
  List<int> classDays,
) =>
    AppDateUtils.classDayRangeDesc(startStr, endStr, classDays);
List<T> getPeriodsForDate<T>(String dateStr, dynamic timetable) =>
    AppDateUtils.getPeriodsForDate<T>(dateStr, timetable);
String formatDateLabel(String dateStr) => AppDateUtils.formatDateLabel(dateStr);
String formatDateFull(String dateStr) => AppDateUtils.formatDateFull(dateStr);
