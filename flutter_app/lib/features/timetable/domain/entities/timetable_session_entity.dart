/// Domain entity representing a single scheduled session in the weekly timetable.
class TimetableSessionEntity {
  final String id;
  final String subjectId;
  final String label;
  final int dayOfWeek; // 0 = Sun, 1 = Mon, ..., 6 = Sat
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const TimetableSessionEntity({
    required this.id,
    required this.subjectId,
    required this.label,
    required this.dayOfWeek,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null || !active;

  TimetableSessionEntity copyWith({
    String? id,
    String? subjectId,
    String? label,
    int? dayOfWeek,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return TimetableSessionEntity(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      label: label ?? this.label,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimetableSessionEntity &&
        other.id == id &&
        other.subjectId == subjectId &&
        other.label == label &&
        other.dayOfWeek == dayOfWeek &&
        other.active == active &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    subjectId,
    label,
    dayOfWeek,
    active,
    createdAt,
    updatedAt,
    deletedAt,
  );

  @override
  String toString() =>
      'TimetableSessionEntity(id: $id, subjectId: $subjectId, label: $label, dayOfWeek: $dayOfWeek, active: $active, deletedAt: $deletedAt)';
}
