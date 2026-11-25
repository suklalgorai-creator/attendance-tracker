import '../../features/attendance/domain/entities/attendance_record_entity.dart';
import '../../features/attendance/domain/entities/attendance_status.dart';
import '../../features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'date_utils.dart';

/// Metrics computed for user-facing attendance card status.
class AttendanceMetrics {
  final double percentage;
  final bool isSafe;
  final int classesCanBunk;
  final int classesNeeded;
  final String statusMessage;

  AttendanceMetrics({
    required this.percentage,
    required this.isSafe,
    required this.classesCanBunk,
    required this.classesNeeded,
    required this.statusMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceMetrics &&
          percentage == other.percentage &&
          isSafe == other.isSafe &&
          classesCanBunk == other.classesCanBunk &&
          classesNeeded == other.classesNeeded &&
          statusMessage == other.statusMessage;

  @override
  int get hashCode =>
      percentage.hashCode ^
      isSafe.hashCode ^
      classesCanBunk.hashCode ^
      classesNeeded.hashCode ^
      statusMessage.hashCode;

  @override
  String toString() =>
      'AttendanceMetrics(percentage: $percentage, isSafe: $isSafe, classesCanBunk: $classesCanBunk, classesNeeded: $classesNeeded, statusMessage: "$statusMessage")';
}

/// Raw counts summarizing attendance records conforming 1:1 with React `summarizeAttendanceRecords`.
class AttendanceSummary {
  final int present;
  final int absent;
  final int conducted;
  final int cancelled;
  final int unmarked;

  const AttendanceSummary({
    this.present = 0,
    this.absent = 0,
    this.conducted = 0,
    this.cancelled = 0,
    this.unmarked = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceSummary &&
          present == other.present &&
          absent == other.absent &&
          conducted == other.conducted &&
          cancelled == other.cancelled &&
          unmarked == other.unmarked;

  @override
  int get hashCode =>
      present.hashCode ^
      absent.hashCode ^
      conducted.hashCode ^
      cancelled.hashCode ^
      unmarked.hashCode;

  @override
  String toString() =>
      'AttendanceSummary(present: $present, absent: $absent, conducted: $conducted, cancelled: $cancelled, unmarked: $unmarked)';
}

/// Calculated overall attendance result conforming 1:1 with React `calculateOverallAttendance`.
class OverallAttendanceResult {
  final int present;
  final int absent;
  final int conducted;
  final int cancelled;
  final int unmarked;
  final double? attendance;
  final String status; // 'none' | 'safe' | 'danger'
  final int canMiss;
  final int needToAttend;
  final bool impossible;

  const OverallAttendanceResult({
    required this.present,
    required this.absent,
    required this.conducted,
    required this.cancelled,
    required this.unmarked,
    required this.attendance,
    required this.status,
    required this.canMiss,
    required this.needToAttend,
    required this.impossible,
  });

  bool get isSafe => status == 'safe';
  bool get isDanger => status == 'danger';
  bool get isNone => status == 'none';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverallAttendanceResult &&
          present == other.present &&
          absent == other.absent &&
          conducted == other.conducted &&
          cancelled == other.cancelled &&
          unmarked == other.unmarked &&
          attendance == other.attendance &&
          status == other.status &&
          canMiss == other.canMiss &&
          needToAttend == other.needToAttend &&
          impossible == other.impossible;

  @override
  int get hashCode =>
      present.hashCode ^
      absent.hashCode ^
      conducted.hashCode ^
      cancelled.hashCode ^
      unmarked.hashCode ^
      attendance.hashCode ^
      status.hashCode ^
      canMiss.hashCode ^
      needToAttend.hashCode ^
      impossible.hashCode;

  @override
  String toString() =>
      'OverallAttendanceResult(present: $present, absent: $absent, conducted: $conducted, cancelled: $cancelled, unmarked: $unmarked, attendance: $attendance, status: "$status", canMiss: $canMiss, needToAttend: $needToAttend, impossible: $impossible)';
}

/// Calculated subject-level attendance result conforming 1:1 with React `calculateSubjectAttendance`.
class SubjectAttendanceResult {
  final String? subjectId;
  final int present;
  final int absent;
  final int conducted;
  final int cancelled;
  final int unmarked;
  final double? attendance;
  final String status; // 'none' | 'safe' | 'danger'
  final int canMiss;
  final int needToAttend;
  final bool impossible;

  const SubjectAttendanceResult({
    this.subjectId,
    required this.present,
    required this.absent,
    required this.conducted,
    required this.cancelled,
    required this.unmarked,
    required this.attendance,
    required this.status,
    required this.canMiss,
    required this.needToAttend,
    required this.impossible,
  });

  bool get isSafe => status == 'safe';
  bool get isDanger => status == 'danger';
  bool get isNone => status == 'none';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectAttendanceResult &&
          subjectId == other.subjectId &&
          present == other.present &&
          absent == other.absent &&
          conducted == other.conducted &&
          cancelled == other.cancelled &&
          unmarked == other.unmarked &&
          attendance == other.attendance &&
          status == other.status &&
          canMiss == other.canMiss &&
          needToAttend == other.needToAttend &&
          impossible == other.impossible;

  @override
  int get hashCode =>
      subjectId.hashCode ^
      present.hashCode ^
      absent.hashCode ^
      conducted.hashCode ^
      cancelled.hashCode ^
      unmarked.hashCode ^
      attendance.hashCode ^
      status.hashCode ^
      canMiss.hashCode ^
      needToAttend.hashCode ^
      impossible.hashCode;

  @override
  String toString() =>
      'SubjectAttendanceResult(subjectId: $subjectId, present: $present, absent: $absent, conducted: $conducted, cancelled: $cancelled, unmarked: $unmarked, attendance: $attendance, status: "$status", canMiss: $canMiss, needToAttend: $needToAttend, impossible: $impossible)';
}

bool _isRecordDeleted(dynamic record) {
  if (record == null) return true;
  if (record is AttendanceRecordEntity) return record.isDeleted;
  if (record is LegacyAttendanceEntity) return record.isDeleted;
  if (record is Map) return record['deletedAt'] != null;
  try {
    return (record as dynamic).deletedAt != null;
  } catch (_) {
    return false;
  }
}

String? _getRecordDate(dynamic record) {
  if (record == null) return null;
  if (record is AttendanceRecordEntity) return record.date;
  if (record is LegacyAttendanceEntity) return record.date;
  if (record is Map) return record['date']?.toString();
  try {
    return (record as dynamic).date?.toString();
  } catch (_) {
    return null;
  }
}

String? _getRecordSubjectId(dynamic record) {
  if (record == null) return null;
  if (record is AttendanceRecordEntity) return record.subjectId;
  if (record is Map) return record['subjectId']?.toString();
  try {
    return (record as dynamic).subjectId?.toString();
  } catch (_) {
    return null;
  }
}

AttendanceStatus? _getRecordStatus(dynamic record) {
  if (record == null) return null;
  if (record is AttendanceRecordEntity) return record.status;
  dynamic raw;
  if (record is Map) {
    raw = record['status'];
  } else {
    try {
      raw = (record as dynamic).status;
    } catch (_) {}
  }
  if (raw is AttendanceStatus) return raw;
  if (raw is String) return AttendanceStatus.fromString(raw);
  return null;
}

bool _isHoliday(String? date, dynamic holidays) {
  if (date == null || holidays == null) return false;
  if (holidays is Map) {
    return holidays.containsKey(date) &&
        holidays[date] != null &&
        holidays[date] != false;
  }
  if (holidays is Set) return holidays.contains(date);
  if (holidays is List) return holidays.contains(date);
  return false;
}

/// Core attendance calculation engine replicating React `attendance.js` with IEEE-754 epsilon parity.
class AttendanceCalculator {
  static const double _epsilon = 1e-10;

  /// Returns whether [threshold] is a usable attendance percentage (0 < threshold <= 100).
  ///
  /// Mirroring React's `isValidThreshold`: zero, negative, NaN, and values above 100
  /// are not valid targets.
  static bool isValidThreshold(num? threshold) {
    if (threshold == null) return false;
    final d = threshold.toDouble();
    return d.isFinite && d > 0 && d <= 100;
  }

  /// Calculates attendance percentage, or `null` when no valid classes exist.
  static double? calculateAttendance(num? present, num? conducted) {
    if (present == null || conducted == null) return null;
    final p = present.toDouble();
    final c = conducted.toDouble();
    if (!p.isFinite || !c.isFinite || c <= 0 || p < 0 || p > c) return null;
    return (p / c) * 100.0;
  }

  /// Calculates the maximum number of future absences that preserve [threshold].
  /// Uses floor with +1e-10 epsilon guard matching React.
  /// Invalid or already-dangerous records return zero.
  static int calculateMaximumAbsences(
    num? present,
    num? conducted,
    num? threshold,
  ) {
    if (!isValidThreshold(threshold) || present == null || conducted == null) {
      return 0;
    }
    final p = present.toDouble();
    final c = conducted.toDouble();
    final t = threshold!.toDouble();
    if (!p.isFinite || !c.isFinite || c <= 0) return 0;

    final attendance = calculateAttendance(p, c);
    if (attendance == null || attendance < t) return 0;

    final maximum = ((p * 100.0) / t - c + _epsilon).floor();
    return maximum < 0 ? 0 : maximum;
  }

  /// Calculates the minimum consecutive present classes needed to reach [threshold].
  /// Uses ceil with -1e-10 epsilon guard. Returns -1 for Infinity when threshold >= 100.
  static int calculateRequiredRecoveryClasses(
    num? present,
    num? conducted,
    num? threshold,
  ) {
    if (!isValidThreshold(threshold) || present == null || conducted == null) {
      return 0;
    }
    final p = present.toDouble();
    final c = conducted.toDouble();
    final t = threshold!.toDouble();
    if (!p.isFinite || !c.isFinite || c <= 0) return 0;

    final attendance = calculateAttendance(p, c);
    if (attendance == null || attendance >= t) return 0;
    if (t >= 100.0) return -1; // -1 represents Infinity in integer domain

    final required = (((t * c) - (100.0 * p)) / (100.0 - t) - _epsilon).ceil();
    return required < 0 ? 0 : required;
  }

  /// Projects attendance after adding future present and absent classes.
  static double? calculateProjectedAttendance(
    num? present,
    num? conducted, {
    num futurePresent = 0,
    num futureAbsent = 0,
  }) {
    if (present == null || conducted == null) return null;
    final p = present.toDouble();
    final c = conducted.toDouble();
    final fp = futurePresent.toDouble();
    final fa = futureAbsent.toDouble();
    if (!p.isFinite || !c.isFinite || !fp.isFinite || !fa.isFinite) return null;
    if (fp < 0 || fa < 0) return null;
    return calculateAttendance(p + fp, c + fp + fa);
  }

  /// Returns whether a status represents a conducted class (Present or Absent).
  static bool isConductedStatus(dynamic status) {
    if (status is AttendanceStatus) return status.isConducted;
    if (status is String) {
      final s = status.toUpperCase().trim();
      return s == 'PRESENT' || s == 'ABSENT';
    }
    return false;
  }

  /// Returns whether a record is a valid non-deleted conducted attendance record.
  static bool isConductedAttendanceRecord(dynamic record) {
    if (record == null) return false;
    if (_isRecordDeleted(record)) return false;
    final status = _getRecordStatus(record);
    if (status != null) return status.isConducted;
    if (record is Map) return isConductedStatus(record['status']);
    try {
      return isConductedStatus((record as dynamic).status);
    } catch (_) {
      return false;
    }
  }

  /// Summarizes attendance records filtering deleted, subjectId, and holidays.
  static AttendanceSummary summarizeAttendanceRecords(
    dynamic records, {
    String? subjectId,
    dynamic holidays,
  }) {
    if (records == null) return const AttendanceSummary();
    final Iterable list = records is Iterable ? records : [records];

    int present = 0;
    int absent = 0;
    int conducted = 0;
    int cancelled = 0;
    int unmarked = 0;

    for (final record in list) {
      if (record == null || _isRecordDeleted(record)) continue;
      final date = _getRecordDate(record);
      if (_isHoliday(date, holidays)) continue;

      final recSubId = _getRecordSubjectId(record);
      if (subjectId != null && subjectId.isNotEmpty && recSubId != subjectId) {
        continue;
      }

      final status = _getRecordStatus(record);
      if (status == null) continue;

      switch (status) {
        case AttendanceStatus.present:
          present += 1;
          conducted += 1;
          break;
        case AttendanceStatus.absent:
          absent += 1;
          conducted += 1;
          break;
        case AttendanceStatus.cancelled:
          cancelled += 1;
          break;
        case AttendanceStatus.unmarked:
          unmarked += 1;
          break;
      }
    }

    return AttendanceSummary(
      present: present,
      absent: absent,
      conducted: conducted,
      cancelled: cancelled,
      unmarked: unmarked,
    );
  }

  /// Summarizes legacy held and attended records filtering deleted and holidays.
  static AttendanceSummary summarizeLegacyAttendance(
    dynamic records, [
    dynamic holidays,
  ]) {
    if (records == null) return const AttendanceSummary();
    final Iterable list = records is Iterable ? records : [records];

    int present = 0;
    int absent = 0;
    int conducted = 0;

    for (final record in list) {
      if (record == null || _isRecordDeleted(record)) continue;
      final date = _getRecordDate(record);
      if (_isHoliday(date, holidays)) continue;

      int held = 0;
      int attended = 0;
      if (record is LegacyAttendanceEntity) {
        held = record.held;
        attended = record.attended;
      } else if (record is Map) {
        held = (record['held'] is num) ? (record['held'] as num).toInt() : 0;
        attended = (record['attended'] is num)
            ? (record['attended'] as num).toInt()
            : 0;
      } else {
        try {
          held = ((record as dynamic).held as num).toInt();
          attended = ((record as dynamic).attended as num).toInt();
        } catch (_) {}
      }

      present += attended;
      absent += (held - attended);
      conducted += held;
    }

    return AttendanceSummary(
      present: present,
      absent: absent,
      conducted: conducted,
      cancelled: 0,
      unmarked: 0,
    );
  }

  /// Calculates overall attendance across current session records and legacy records.
  static OverallAttendanceResult calculateOverallAttendance({
    dynamic attendanceRecords,
    dynamic legacyAttendance,
    required num minPercent,
    dynamic holidays,
  }) {
    final current = summarizeAttendanceRecords(
      attendanceRecords,
      holidays: holidays,
    );
    final legacy = summarizeLegacyAttendance(legacyAttendance, holidays);
    final present = current.present + legacy.present;
    final absent = current.absent + legacy.absent;
    final conducted = current.conducted + legacy.conducted;
    final attendance = calculateAttendance(present, conducted);
    final target = minPercent.toDouble();
    final safe = attendance != null && attendance >= target;
    final status = attendance == null ? 'none' : (safe ? 'safe' : 'danger');
    final canMiss = safe
        ? calculateMaximumAbsences(present, conducted, target)
        : 0;
    final needToAttend = safe
        ? 0
        : calculateRequiredRecoveryClasses(present, conducted, target);
    final impossible = !safe && target >= 100.0;

    return OverallAttendanceResult(
      present: present,
      absent: absent,
      conducted: conducted,
      cancelled: current.cancelled,
      unmarked: current.unmarked,
      attendance: attendance,
      status: status,
      canMiss: canMiss,
      needToAttend: needToAttend,
      impossible: impossible,
    );
  }

  /// Calculates attendance for a specific subject conforming 1:1 with React `calculateSubjectAttendance`.
  static SubjectAttendanceResult calculateSubjectAttendance(
    String subjectId, {
    dynamic attendanceRecords,
    required num minPercent,
    dynamic holidays,
  }) {
    final summary = summarizeAttendanceRecords(
      attendanceRecords,
      subjectId: subjectId,
      holidays: holidays,
    );
    final attendance = calculateAttendance(summary.present, summary.conducted);
    final target = minPercent.toDouble();
    final safe = attendance != null && attendance >= target;
    final status = attendance == null ? 'none' : (safe ? 'safe' : 'danger');
    final canMiss = safe
        ? calculateMaximumAbsences(summary.present, summary.conducted, target)
        : 0;
    final needToAttend = safe
        ? 0
        : calculateRequiredRecoveryClasses(
            summary.present,
            summary.conducted,
            target,
          );
    final impossible = !safe && target >= 100.0;

    return SubjectAttendanceResult(
      subjectId: subjectId,
      present: summary.present,
      absent: summary.absent,
      conducted: summary.conducted,
      cancelled: summary.cancelled,
      unmarked: summary.unmarked,
      attendance: attendance,
      status: status,
      canMiss: canMiss,
      needToAttend: needToAttend,
      impossible: impossible,
    );
  }

  /// Calculates pending scheduled sessions matching React `calculatePendingScheduledSessions`.
  static int calculatePendingScheduledSessions({
    dynamic attendanceRecords,
    dynamic timetable,
    List<int> classDays = const [1, 2, 3, 4, 5],
    String? startDate,
    String? endDate,
    dynamic holidays,
  }) {
    if (startDate == null || startDate.isEmpty) return 0;
    final effectiveEndDate = endDate ?? AppDateUtils.todayStr();

    final recordMap = <String, dynamic>{};
    if (attendanceRecords is Iterable) {
      for (final r in attendanceRecords) {
        if (r == null || _isRecordDeleted(r)) continue;
        final date = _getRecordDate(r);
        String? sessionId;
        if (r is AttendanceRecordEntity) {
          sessionId = r.sessionId;
        } else if (r is Map) {
          sessionId = r['sessionId']?.toString();
        } else {
          try {
            sessionId = (r as dynamic).sessionId?.toString();
          } catch (_) {}
        }
        if (date != null && sessionId != null) {
          recordMap['$date:$sessionId'] = r;
        }
      }
    }

    final dates = AppDateUtils.classDayRangeDesc(
      startDate,
      effectiveEndDate,
      classDays,
    );
    int pending = 0;

    for (final date in dates) {
      if (_isHoliday(date, holidays)) continue;
      final sessions = AppDateUtils.getPeriodsForDate(date, timetable);
      for (final session in sessions) {
        String? sessId;
        bool active = true;
        bool deleted = false;
        if (session is Map) {
          sessId = session['id']?.toString();
          active = session['active'] != false;
          deleted = session['deletedAt'] != null;
        } else {
          try {
            sessId = (session as dynamic).id?.toString();
            active = (session as dynamic).active != false;
            deleted = (session as dynamic).deletedAt != null;
          } catch (_) {}
        }
        if (sessId == null || !active || deleted) continue;

        final rec = recordMap['$date:$sessId'];
        if (rec == null) {
          pending++;
        } else {
          final status = _getRecordStatus(rec);
          if (status == AttendanceStatus.unmarked) {
            pending++;
          }
        }
      }
    }

    return pending;
  }

  /// Evaluates attendance metrics for UI components.
  static AttendanceMetrics evaluate({
    required int attended,
    required int total,
    double target = 75.0,
  }) {
    if (total == 0) {
      return AttendanceMetrics(
        percentage: 100.0,
        isSafe: true,
        classesCanBunk: 0,
        classesNeeded: 0,
        statusMessage: "No classes logged yet",
      );
    }

    final double currentPct = calculateAttendance(attended, total) ?? 0.0;
    final effectiveTarget = isValidThreshold(target) ? target : 75.0;

    if (currentPct >= effectiveTarget) {
      final int bunkable = calculateMaximumAbsences(
        attended,
        total,
        effectiveTarget,
      );
      return AttendanceMetrics(
        percentage: currentPct,
        isSafe: true,
        classesCanBunk: bunkable,
        classesNeeded: 0,
        statusMessage: bunkable > 0
            ? "Safe Zone: Can bunk $bunkable more class${bunkable > 1 ? 'es' : ''}"
            : "On the edge: Don't miss your next class!",
      );
    } else {
      final int needed = calculateRequiredRecoveryClasses(
        attended,
        total,
        effectiveTarget,
      );
      return AttendanceMetrics(
        percentage: currentPct,
        isSafe: false,
        classesCanBunk: 0,
        classesNeeded: needed,
        statusMessage:
            "Danger Zone: Must attend next $needed class${needed > 1 ? 'es' : ''} to reach ${effectiveTarget.toInt()}%",
      );
    }
  }
}

// Top-level aliases for direct parity with React function imports
bool isValidThreshold(num? threshold) =>
    AttendanceCalculator.isValidThreshold(threshold);
double? calculateAttendance(num? present, num? conducted) =>
    AttendanceCalculator.calculateAttendance(present, conducted);
int calculateMaximumAbsences(num? present, num? conducted, num? threshold) =>
    AttendanceCalculator.calculateMaximumAbsences(
      present,
      conducted,
      threshold,
    );
int calculateRequiredRecoveryClasses(
  num? present,
  num? conducted,
  num? threshold,
) => AttendanceCalculator.calculateRequiredRecoveryClasses(
  present,
  conducted,
  threshold,
);
double? calculateProjectedAttendance(
  num? present,
  num? conducted, {
  num futurePresent = 0,
  num futureAbsent = 0,
}) => AttendanceCalculator.calculateProjectedAttendance(
  present,
  conducted,
  futurePresent: futurePresent,
  futureAbsent: futureAbsent,
);
bool isConductedStatus(dynamic status) =>
    AttendanceCalculator.isConductedStatus(status);
bool isConductedAttendanceRecord(dynamic record) =>
    AttendanceCalculator.isConductedAttendanceRecord(record);
AttendanceSummary summarizeAttendanceRecords(
  dynamic records, {
  String? subjectId,
  dynamic holidays,
}) => AttendanceCalculator.summarizeAttendanceRecords(
  records,
  subjectId: subjectId,
  holidays: holidays,
);
AttendanceSummary summarizeLegacyAttendance(
  dynamic records, [
  dynamic holidays,
]) => AttendanceCalculator.summarizeLegacyAttendance(records, holidays);
OverallAttendanceResult calculateOverallAttendance({
  dynamic attendanceRecords,
  dynamic legacyAttendance,
  required num minPercent,
  dynamic holidays,
}) => AttendanceCalculator.calculateOverallAttendance(
  attendanceRecords: attendanceRecords,
  legacyAttendance: legacyAttendance,
  minPercent: minPercent,
  holidays: holidays,
);
SubjectAttendanceResult calculateSubjectAttendance(
  String subjectId, {
  dynamic attendanceRecords,
  required num minPercent,
  dynamic holidays,
}) => AttendanceCalculator.calculateSubjectAttendance(
  subjectId,
  attendanceRecords: attendanceRecords,
  minPercent: minPercent,
  holidays: holidays,
);
int calculatePendingScheduledSessions({
  dynamic attendanceRecords,
  dynamic timetable,
  List<int> classDays = const [1, 2, 3, 4, 5],
  String? startDate,
  String? endDate,
  dynamic holidays,
}) => AttendanceCalculator.calculatePendingScheduledSessions(
  attendanceRecords: attendanceRecords,
  timetable: timetable,
  classDays: classDays,
  startDate: startDate,
  endDate: endDate,
  holidays: holidays,
);
