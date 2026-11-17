import 'attendance_status.dart';

/// Domain entity representing a session-level attendance record.
/// Replicates React `attendanceRecords` array schema.
class AttendanceRecordEntity {
  final String id;
  final String date; // YYYY-MM-DD
  final String subjectId;
  final String sessionId;
  final AttendanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const AttendanceRecordEntity({
    required this.id,
    required this.date,
    this.subjectId = dailySubjectId,
    required this.sessionId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  AttendanceRecordEntity copyWith({
    String? id,
    String? date,
    String? subjectId,
    String? sessionId,
    AttendanceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return AttendanceRecordEntity(
      id: id ?? this.id,
      date: date ?? this.date,
      subjectId: subjectId ?? this.subjectId,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordEntity &&
          id == other.id &&
          date == other.date &&
          subjectId == other.subjectId &&
          sessionId == other.sessionId &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      date.hashCode ^
      subjectId.hashCode ^
      sessionId.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
}
