import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../models/dashboard_stats.dart';
import '../models/subject_attendance_stats.dart';

/// Pure Dart domain service providing attendance analytics, mathematical formulas,
/// safe bunk calculations, recovery projections, and streak tracking.
class DashboardAnalyticsService {
  const DashboardAnalyticsService();

  /// Calculates raw attendance percentage.
  /// Returns `null` if [conducted] <= 0 or if inputs are invalid.
  double? calculateAttendance(int present, int conducted) {
    if (conducted <= 0 || present < 0 || present > conducted) {
      return null;
    }
    return (present / conducted) * 100.0;
  }

  /// Calculates the maximum number of classes a student can safely miss while
  /// remaining at or above [threshold]%.
  ///
  /// Uses a `+ 1e-10` floating-point precision guard to prevent flooring artifacts.
  /// Returns `0` if current attendance is below [threshold] or if conducted <= 0.
  int calculateMaximumAbsences(int present, int conducted, double threshold) {
    if (threshold <= 0 || threshold > 100 || conducted <= 0 || present < 0) {
      return 0;
    }
    final attendance = calculateAttendance(present, conducted);
    if (attendance == null || attendance < threshold) {
      return 0;
    }
    final bunks = ((present * 100.0) / threshold - conducted + 1e-10).floor();
    return bunks < 0 ? 0 : bunks;
  }

  /// Calculates the minimum consecutive classes needed to recover attendance to [threshold]%.
  ///
  /// Uses a `- 1e-10` floating-point precision guard to prevent ceiling artifacts.
  /// Returns `0` if already at or above [threshold]%.
  /// Returns `-1` (impossible) if [threshold] >= 100.0 and attendance < 100%.
  int calculateRequiredRecoveryClasses(int present, int conducted, double threshold) {
    if (threshold <= 0 || conducted <= 0 || present < 0) {
      return 0;
    }
    final attendance = calculateAttendance(present, conducted);
    if (attendance == null || attendance >= threshold) {
      return 0;
    }
    if (threshold >= 100.0) {
      return -1; // Unreachable
    }
    final required =
        (((threshold * conducted) - (100.0 * present)) / (100.0 - threshold) - 1e-10).ceil();
    return required < 0 ? 0 : required;
  }

  /// Converts a Dart [DateTime.weekday] (Monday=1, ..., Sunday=7)
  /// to JavaScript/React day-of-week index (Sunday=0, Monday=1, ..., Saturday=6).
  int toClassDayIndex(int dartWeekday) {
    return dartWeekday == DateTime.sunday ? 0 : dartWeekday;
  }

  /// Determines whether the given date is a scheduled class day according to [classDays].
  bool isClassDay(DateTime date, List<int> classDays) {
    if (classDays.isEmpty) return false;
    final dayIndex = toClassDayIndex(date.weekday);
    return classDays.contains(dayIndex);
  }

  /// Formats a [DateTime] into a standard `YYYY-MM-DD` string.
  String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Computes the consecutive class day attendance streak matching React's `computeStreak`.
  ///
  /// - Excludes soft-deleted records.
  /// - Non-class days and holidays are skipped (do not break or increment streak).
  /// - Today's grace period: If today is a class day but un-attended, steps back to yesterday.
  /// - Stops on the first attended class day that was missed.
  /// - Accepts optional [referenceDate] for deterministic testing.
  int computeStreak({
    required List<AttendanceRecordEntity> attendanceRecords,
    required List<int> classDays,
    List<LegacyAttendanceEntity> legacyAttendance = const [],
    Set<String> holidays = const {},
    DateTime? referenceDate,
  }) {
    if (classDays.isEmpty) return 0;

    final presentDates = <String>{};

    for (final record in attendanceRecords) {
      if (!record.isDeleted &&
          record.status == AttendanceStatus.present &&
          !holidays.contains(record.date)) {
        presentDates.add(record.date);
      }
    }

    for (final legacy in legacyAttendance) {
      if (!legacy.isDeleted &&
          legacy.held > 0 &&
          legacy.attended == legacy.held &&
          !holidays.contains(legacy.date)) {
        presentDates.add(legacy.date);
      }
    }

    final ref = referenceDate ?? DateTime.now();
    var cursor = DateTime(ref.year, ref.month, ref.day);

    // Today's grace period: if today is a class day and un-attended, step back to yesterday
    final todayStr = formatDate(cursor);
    if (!presentDates.contains(todayStr) && isClassDay(cursor, classDays)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    var safety = 0;

    while (safety < 3000) {
      safety++;
      final cursorStr = formatDate(cursor);
      final isHol = holidays.contains(cursorStr);
      final isClass = isClassDay(cursor, classDays);

      if (isHol || !isClass) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      if (!presentDates.contains(cursorStr)) {
        break;
      }

      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Computes overall dashboard statistics aggregating session records and legacy data.
  DashboardStats computeOverallStats({
    required List<AttendanceRecordEntity> attendanceRecords,
    required List<LegacyAttendanceEntity> legacyAttendance,
    double minPercent = 75.0,
    int unmarkedPastSessions = 0,
  }) {
    var presentCount = 0;
    var absentCount = 0;

    for (final record in attendanceRecords) {
      if (record.isDeleted) continue;
      if (record.status == AttendanceStatus.present) {
        presentCount++;
      } else if (record.status == AttendanceStatus.absent) {
        absentCount++;
      }
    }

    for (final legacy in legacyAttendance) {
      if (legacy.isDeleted) continue;
      presentCount += legacy.attended;
      absentCount += (legacy.held - legacy.attended).clamp(0, 999999);
    }

    final conducted = presentCount + absentCount;
    final percentage = calculateAttendance(presentCount, conducted);
    final isSafe = percentage == null || percentage >= minPercent;
    final isImpossible = !isSafe && minPercent >= 100.0;
    final canMiss = isSafe ? calculateMaximumAbsences(presentCount, conducted, minPercent) : 0;
    final recovery = isSafe
        ? 0
        : calculateRequiredRecoveryClasses(presentCount, conducted, minPercent);
    final needToAttend = recovery < 0 ? 0 : recovery;

    return DashboardStats(
      conducted: conducted,
      present: presentCount,
      absent: absentCount,
      percentage: percentage,
      minPercent: minPercent,
      canMiss: canMiss,
      needToAttend: needToAttend,
      isImpossible: isImpossible || recovery < 0,
      isSafe: isSafe,
      unmarkedPastSessions: unmarkedPastSessions,
    );
  }

  /// Computes metrics for an individual subject.
  SubjectAttendanceStats computeSubjectStats({
    required SubjectEntity subject,
    required List<AttendanceRecordEntity> attendanceRecords,
    double minPercent = 75.0,
  }) {
    var presentCount = 0;
    var absentCount = 0;

    for (final record in attendanceRecords) {
      if (record.isDeleted || record.subjectId != subject.id) continue;
      if (record.status == AttendanceStatus.present) {
        presentCount++;
      } else if (record.status == AttendanceStatus.absent) {
        absentCount++;
      }
    }

    final conducted = presentCount + absentCount;
    final percentage = calculateAttendance(presentCount, conducted);
    final effectiveThreshold = subject.targetPercentage ?? minPercent;
    final isSafe = percentage == null || percentage >= effectiveThreshold;
    final isImpossible = !isSafe && effectiveThreshold >= 100.0;
    final canMiss = isSafe ? calculateMaximumAbsences(presentCount, conducted, effectiveThreshold) : 0;
    final recovery = isSafe
        ? 0
        : calculateRequiredRecoveryClasses(presentCount, conducted, effectiveThreshold);
    final needToAttend = recovery < 0 ? 0 : recovery;

    return SubjectAttendanceStats(
      subject: subject,
      conducted: conducted,
      present: presentCount,
      absent: absentCount,
      percentage: percentage,
      canMiss: canMiss,
      needToAttend: needToAttend,
      isImpossible: isImpossible || recovery < 0,
      isSafe: isSafe,
    );
  }

  /// Computes metrics for all active subjects.
  List<SubjectAttendanceStats> computeAllSubjectStats({
    required List<SubjectEntity> subjects,
    required List<AttendanceRecordEntity> attendanceRecords,
    double minPercent = 75.0,
  }) {
    final activeSubjects = subjects.where((s) => s.active && !s.isDeleted).toList();
    return activeSubjects
        .map((subject) => computeSubjectStats(
              subject: subject,
              attendanceRecords: attendanceRecords,
              minPercent: minPercent,
            ))
        .toList();
  }
}
