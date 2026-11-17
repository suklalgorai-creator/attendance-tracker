import '../../domain/entities/legacy_attendance_entity.dart';

/// Data model for LegacyAttendance serialization, extending LegacyAttendanceEntity.
class LegacyAttendanceModel extends LegacyAttendanceEntity {
  const LegacyAttendanceModel({
    required super.id,
    required super.date,
    required super.held,
    required super.attended,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory LegacyAttendanceModel.fromEntity(LegacyAttendanceEntity entity) {
    return LegacyAttendanceModel(
      id: entity.id,
      date: entity.date,
      held: entity.held,
      attended: entity.attended,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory LegacyAttendanceModel.fromMap(Map<String, dynamic> map) {
    return LegacyAttendanceModel(
      id: (map['id'] as String?)?.trim() ?? '',
      date: (map['date'] as String?)?.trim() ?? '',
      held: (map['held'] as num?)?.toInt() ?? 0,
      attended: (map['attended'] as num?)?.toInt() ?? 0,
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
      'held': held,
      'attended': attended,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
