import '../../../../core/utils/date_utils.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';
import '../models/calendar_day_summary.dart';

/// Pure domain service calculating day summaries, monthly aggregates,
/// and heatmap data matrices with exact 1:1 React parity.
///
/// Ownership: Calendar Feature (Domain Service)
// ==========================================
// CALENDAR ANALYTICS - Month Grid & Heatmap Computation
// ==========================================
class CalendarAnalyticsService {
  const CalendarAnalyticsService();

  /// Computes the [CalendarDaySummary] for a single calendar date.
  ///
  /// Matches React `CalendarView.jsx` lines 20-33 verbatim.
  CalendarDaySummary computeDaySummary({
    required String date,
    required List<AttendanceRecordEntity> records,
    required Map<String, LegacyAttendanceEntity> legacyByDate,
    required Map<String, bool> holidays,
  }) {
    // 1. Explicit global holiday override
    if (holidays[date] == true) {
      return CalendarDaySummary(
        date: date,
        type: CalendarDayType.holiday,
        held: 0,
        attended: 0,
      );
    }

    // 2. Active session records for this specific date
    final dateRecords = records
        .where((record) => record.date == date && !record.isDeleted)
        .toList();

    // 3. Held sessions: PRESENT or ABSENT
    final heldRecords = dateRecords
        .where(
          (record) =>
              record.status == AttendanceStatus.present ||
              record.status == AttendanceStatus.absent,
        )
        .toList();

    final attendedCount = heldRecords
        .where((record) => record.status == AttendanceStatus.present)
        .length;

    // 4. Legacy attendance aggregates
    final legacy = legacyByDate[date];
    final totalHeld = heldRecords.length + (legacy?.held ?? 0);
    final totalAttended = attendedCount + (legacy?.attended ?? 0);

    // 5. Cancelled classes or "Holiday / No class" legacy mark (held == 0) count as holiday
    final hasCancelled = dateRecords.any(
      (record) => record.status == AttendanceStatus.cancelled,
    );
    final isMarkedNoClass = legacy != null && legacy.held == 0;
    if ((hasCancelled || isMarkedNoClass) && totalHeld == 0) {
      return CalendarDaySummary(
        date: date,
        type: CalendarDayType.holiday,
        held: 0,
        attended: 0,
      );
    }

    // 6. No classes conducted
    if (totalHeld == 0) {
      return CalendarDaySummary(
        date: date,
        type: CalendarDayType.empty,
        held: 0,
        attended: 0,
      );
    }

    // 7. All conducted classes attended (100%)
    if (totalAttended == totalHeld) {
      return CalendarDaySummary(
        date: date,
        type: CalendarDayType.present,
        held: totalHeld,
        attended: totalAttended,
      );
    }

    // 8. Zero conducted classes attended (0%)
    if (totalAttended == 0) {
      return CalendarDaySummary(
        date: date,
        type: CalendarDayType.absent,
        held: totalHeld,
        attended: 0,
      );
    }

    // 9. Partial attendance
    return CalendarDaySummary(
      date: date,
      type: CalendarDayType.partial,
      held: totalHeld,
      attended: totalAttended,
    );
  }

  /// Computes the [CalendarMonthSummary] for the specified year and month (1-12).
  ///
  /// Matches React `CalendarView.jsx` lines 35-40.
  CalendarMonthSummary computeMonthSummary({
    required int year,
    required int month,
    required List<CalendarDaySummary> daySummaries,
  }) {
    int totalHeld = 0;
    int totalAttended = 0;
    int totalHolidays = 0;

    for (final day in daySummaries) {
      totalHeld += day.held;
      totalAttended += day.attended;
      if (day.type == CalendarDayType.holiday) {
        totalHolidays += 1;
      }
    }

    return CalendarMonthSummary(
      held: totalHeld,
      attended: totalAttended,
      holidays: totalHolidays,
    );
  }

  /// Computes day summaries for all days in a month.
  List<CalendarDaySummary> computeDaysInMonth({
    required int year,
    required int month,
    required List<AttendanceRecordEntity> records,
    required Map<String, LegacyAttendanceEntity> legacyByDate,
    required Map<String, bool> holidays,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final List<CalendarDaySummary> summaries = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey = formatDateKey(DateTime(year, month, day));
      summaries.add(
        computeDaySummary(
          date: dateKey,
          records: records,
          legacyByDate: legacyByDate,
          holidays: holidays,
        ),
      );
    }

    return summaries;
  }

  /// Computes the start date for the 26-week heatmap grid aligned to Sunday.
  ///
  /// Guarantees that the returned date is always a Sunday (`weekday % 7 == 0`)
  /// exactly `weeksToShow - 1` weeks prior to the Sunday of the anchor week.
  DateTime computeHeatmapStartDate(
    DateTime anchorDate, [
    int weeksToShow = 26,
  ]) {
    final anchor = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    return anchor.subtract(
      Duration(days: (weeksToShow - 1) * 7 + (anchor.weekday % 7)),
    );
  }

  /// Builds the 26-week heatmap data matrix matching `Heatmap.jsx`.
  ///
  /// Returns a map of `YYYY-MM-DD -> {held: int, attended: int}` for all active dates.
  Map<String, ({int held, int attended, bool isHoliday})>
  computeHeatmapRecords({
    required List<AttendanceRecordEntity> records,
    required List<LegacyAttendanceEntity> legacyRecords,
    required Map<String, bool> holidays,
  }) {
    final Map<String, ({int held, int attended, bool isHoliday})> result = {};

    // 1. Group records by date
    final Map<String, List<AttendanceRecordEntity>> byDate = {};
    for (final record in records) {
      if (record.isDeleted) continue;
      byDate.putIfAbsent(record.date, () => []).add(record);
    }

    final Map<String, LegacyAttendanceEntity> legacyByDate = {
      for (final l in legacyRecords)
        if (!l.isDeleted) l.date: l,
    };

    final allDates = {...byDate.keys, ...legacyByDate.keys, ...holidays.keys};

    for (final date in allDates) {
      final day = computeDaySummary(
        date: date,
        records: records,
        legacyByDate: legacyByDate,
        holidays: holidays,
      );

      if (day.type != CalendarDayType.empty) {
        result[date] = (
          held: day.held,
          attended: day.attended,
          isHoliday: day.type == CalendarDayType.holiday,
        );
      }
    }

    return result;
  }
}
