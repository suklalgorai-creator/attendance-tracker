import '../../../subjects/domain/entities/subject_entity.dart';

/// Domain model representing attendance statistics for an individual subject.
///
/// Ownership: Dashboard Feature (Domain Model)
// ==========================================
// DASHBOARD MODEL - Subject Attendance Stats
// ==========================================
class SubjectAttendanceStats {
  final SubjectEntity subject;
  final int conducted;
  final int present;
  final int absent;
  final double? percentage;
  final int canMiss;
  final int needToAttend;
  final bool isImpossible;
  final bool isSafe;

  const SubjectAttendanceStats({
    required this.subject,
    required this.conducted,
    required this.present,
    required this.absent,
    required this.percentage,
    required this.canMiss,
    required this.needToAttend,
    required this.isImpossible,
    required this.isSafe,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectAttendanceStats &&
          runtimeType == other.runtimeType &&
          subject == other.subject &&
          conducted == other.conducted &&
          present == other.present &&
          absent == other.absent &&
          percentage == other.percentage &&
          canMiss == other.canMiss &&
          needToAttend == other.needToAttend &&
          isImpossible == other.isImpossible &&
          isSafe == other.isSafe;

  @override
  int get hashCode =>
      subject.hashCode ^
      conducted.hashCode ^
      present.hashCode ^
      absent.hashCode ^
      percentage.hashCode ^
      canMiss.hashCode ^
      needToAttend.hashCode ^
      isImpossible.hashCode ^
      isSafe.hashCode;

  @override
  String toString() {
    return 'SubjectAttendanceStats(subject: ${subject.name}, conducted: $conducted, '
        'present: $present, absent: $absent, percentage: $percentage, '
        'canMiss: $canMiss, needToAttend: $needToAttend, isImpossible: $isImpossible, isSafe: $isSafe)';
  }
}
