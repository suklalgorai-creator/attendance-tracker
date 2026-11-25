import '../../domain/entities/subject_entity.dart';

/// Data model for Subject serialization, extending SubjectEntity.
class SubjectModel extends SubjectEntity {
  const SubjectModel({
    required super.id,
    required super.name,
    super.code,
    super.color,
    super.icon = 'school',
    super.targetPercentage,
    super.sortOrder = 0,
    super.active,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory SubjectModel.fromEntity(SubjectEntity entity) {
    return SubjectModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      color: entity.color,
      icon: entity.icon,
      targetPercentage: entity.targetPercentage,
      sortOrder: entity.sortOrder,
      active: entity.active,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    final rawTarget = map['targetPercentage'];
    double? targetPercentage;
    if (rawTarget != null) {
      if (rawTarget is num) {
        targetPercentage = rawTarget.toDouble();
      } else if (rawTarget is String) {
        targetPercentage = double.tryParse(rawTarget);
      }
    }

    final rawSort = map['sortOrder'];
    int sortOrder = 0;
    if (rawSort != null) {
      if (rawSort is num) {
        sortOrder = rawSort.toInt();
      } else if (rawSort is String) {
        sortOrder = int.tryParse(rawSort) ?? 0;
      }
    }

    final rawIcon = map['icon'] as String?;

    return SubjectModel(
      id: (map['id'] as String?)?.trim() ?? '',
      name: (map['name'] as String?)?.trim() ?? '',
      code: (map['code'] as String?)?.trim(),
      color: (map['color'] as String?)?.trim() ?? '#10B981',
      icon: (rawIcon != null && rawIcon.trim().isNotEmpty)
          ? rawIcon.trim()
          : 'school',
      targetPercentage: targetPercentage,
      sortOrder: sortOrder,
      active: map['active'] as bool? ?? true,
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
      'name': name,
      'code': code,
      'color': color,
      'icon': icon,
      'targetPercentage': targetPercentage,
      'sortOrder': sortOrder,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
