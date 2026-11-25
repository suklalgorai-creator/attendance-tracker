/// Value objects returned by [AttendanceCalculator] for overall, subject, and summary metrics.
///
/// Ownership: Core Attendance Engine
library;

// ==========================================
// ATTENDANCE METRICS - User Card Summary
// Summarizes percentage, safety status, bunk headroom, and required recovery classes.
// ==========================================

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

// ==========================================
// ATTENDANCE METRICS - Aggregate Count Summary
// Raw counts matching React `summarizeAttendanceRecords`.
// ==========================================

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

// ==========================================
// ATTENDANCE METRICS - Overall Status Result
// Aggregate attendance percentage and eligibility projection across all classes.
// ==========================================

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

// ==========================================
// ATTENDANCE METRICS - Subject Status Result
// Per-subject attendance percentage, threshold status, and bunk/recovery counts.
// ==========================================

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
