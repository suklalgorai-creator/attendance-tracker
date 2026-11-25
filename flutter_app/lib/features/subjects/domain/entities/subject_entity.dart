/// Domain entity representing a Subject in the curriculum.
/// Strictly pure Dart (zero Flutter or Firebase SDK dependencies).
class SubjectEntity {
  final String id;
  final String name;
  final String? code;
  final String color;
  final String icon;
  final double? targetPercentage;
  final int sortOrder;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const SubjectEntity({
    required this.id,
    required this.name,
    this.code,
    this.color = '#10B981',
    this.icon = 'school',
    this.targetPercentage,
    this.sortOrder = 0,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  SubjectEntity copyWith({
    String? id,
    String? name,
    String? code,
    bool clearCode = false,
    String? color,
    String? icon,
    double? targetPercentage,
    bool clearTargetPercentage = false,
    int? sortOrder,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return SubjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      code: clearCode ? null : (code ?? this.code),
      color: color ?? this.color,
      icon: icon ?? this.icon,
      targetPercentage: clearTargetPercentage
          ? null
          : (targetPercentage ?? this.targetPercentage),
      sortOrder: sortOrder ?? this.sortOrder,
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
          code == other.code &&
          color == other.color &&
          icon == other.icon &&
          targetPercentage == other.targetPercentage &&
          sortOrder == other.sortOrder &&
          active == other.active &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      code.hashCode ^
      color.hashCode ^
      icon.hashCode ^
      targetPercentage.hashCode ^
      sortOrder.hashCode ^
      active.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
}
