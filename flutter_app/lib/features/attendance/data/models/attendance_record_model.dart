import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/entities/attendance_status.dart';

/// Serialization model mapping [AttendanceRecordEntity] to/from Hive Maps.
///
/// Ownership: Attendance Feature (Data Model)
// ==========================================
// ATTENDANCE MODEL - V2 Session Record
// ==========================================
class AttendanceRecordModel extends AttendanceRecordEntity {
  const AttendanceRecordModel({
    required super.id,
    required super.date,
    super.subjectId,
    required super.sessionId,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory AttendanceRecordModel.fromEntity(AttendanceRecordEntity entity) {
    return AttendanceRecordModel(
      id: entity.id,
      date: entity.date,
      subjectId: entity.subjectId,
      sessionId: entity.sessionId,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map) {
    return AttendanceRecordModel(
      id: (map['id'] as String?)?.trim() ?? '',
      date: (map['date'] as String?)?.trim() ?? '',
      subjectId: (map['subjectId'] as String?)?.trim() ?? dailySubjectId,
      sessionId: (map['sessionId'] as String?)?.trim() ?? '',
      status: AttendanceStatus.fromString(map['status'] as String?),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deletedAt: map['deletedAt'] != null
          ? DateTime.tryParse(map['deletedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'subjectId': subjectId,
      'sessionId': sessionId,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
