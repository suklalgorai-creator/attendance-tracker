/// Domain entity representing a Subject in the curriculum.
/// Strictly pure Dart (zero Flutter or Firebase SDK dependencies).
class SubjectEntity {
  final String id;
  final String name;
  final String color;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const SubjectEntity({
    required this.id,
    required this.name,
    this.color = '#10B981',
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  SubjectEntity copyWith({
    String? id,
    String? name,
    String? color,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return SubjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectEntity &&
          id == other.id &&
          name == other.name &&
          color == other.color &&
          active == other.active &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      color.hashCode ^
      active.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
}
