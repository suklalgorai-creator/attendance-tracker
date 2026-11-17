/// Domain entity representing legacy daily aggregate attendance.
/// Replicates React `legacyAttendance` array schema (`held` and `attended` integers).
class LegacyAttendanceEntity {
  final String id;
  final String date; // YYYY-MM-DD
  final int held;
  final int attended;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const LegacyAttendanceEntity({
    required this.id,
    required this.date,
    required this.held,
    required this.attended,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  LegacyAttendanceEntity copyWith({
    String? id,
    String? date,
    int? held,
    int? attended,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return LegacyAttendanceEntity(
      id: id ?? this.id,
      date: date ?? this.date,
      held: held ?? this.held,
      attended: attended ?? this.attended,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyAttendanceEntity &&
          id == other.id &&
          date == other.date &&
          held == other.held &&
          attended == other.attended &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      date.hashCode ^
      held.hashCode ^
      attended.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
}
