import '../../domain/entities/daily_task_entity.dart';

/// Hive Map serialization models for DailyFlow tasks and nested subtasks.
///
/// Ownership: DailyFlow Feature (Data Model)
// ==========================================
// DAILYFLOW MODELS - Task & Subtask Serialization
// ==========================================
class DailySubtaskModel extends DailySubtaskEntity {
  const DailySubtaskModel({
    required super.id,
    required super.title,
    super.isDone,
  });

  factory DailySubtaskModel.fromEntity(DailySubtaskEntity entity) {
    return DailySubtaskModel(
      id: entity.id,
      title: entity.title,
      isDone: entity.isDone,
    );
  }

  factory DailySubtaskModel.fromMap(Map<String, dynamic> map) {
    return DailySubtaskModel(
      id: (map['id'] as String?)?.trim() ?? '',
      title: (map['title'] as String?)?.trim() ?? '',
      isDone: map['isDone'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'isDone': isDone};
  }
}

/// Data model for [DailyTaskEntity] Hive Map serialization.
class DailyTaskModel extends DailyTaskEntity {
  const DailyTaskModel({
    required super.id,
    required super.title,
    super.notes,
    super.status,
    super.priority,
    super.recurrence,
    required super.scheduledDate,
    super.startTime,
    super.estimatedMinutes,
    super.elapsedSeconds,
    super.activeStartedAt,
    super.reminderAt,
    super.subjectId,
    super.timetableSessionId,
    super.subtasks,
    required super.createdAt,
    required super.updatedAt,
    super.completedAt,
    super.isDeleted,
  });

  factory DailyTaskModel.fromEntity(DailyTaskEntity entity) {
    return DailyTaskModel(
      id: entity.id,
      title: entity.title,
      notes: entity.notes,
      status: entity.status,
      priority: entity.priority,
      recurrence: entity.recurrence,
      scheduledDate: entity.scheduledDate,
      startTime: entity.startTime,
      estimatedMinutes: entity.estimatedMinutes,
      elapsedSeconds: entity.elapsedSeconds,
      activeStartedAt: entity.activeStartedAt,
      reminderAt: entity.reminderAt,
      subjectId: entity.subjectId,
      timetableSessionId: entity.timetableSessionId,
      subtasks: entity.subtasks,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      completedAt: entity.completedAt,
      isDeleted: entity.isDeleted,
    );
  }

  factory DailyTaskModel.fromMap(Map<String, dynamic> map) {
    final rawSubtasks = map['subtasks'];
    final subtasks = <DailySubtaskEntity>[];
    if (rawSubtasks is List) {
      for (final item in rawSubtasks) {
        if (item is Map) {
          subtasks.add(
            DailySubtaskModel.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return DailyTaskModel(
      id: (map['id'] as String?)?.trim() ?? '',
      title: (map['title'] as String?)?.trim() ?? '',
      notes: (map['notes'] as String?) ?? '',
      status: DailyTaskStatus.fromString(map['status'] as String?),
      priority: DailyTaskPriority.fromString(map['priority'] as String?),
      recurrence: DailyTaskRecurrence.fromString(map['recurrence'] as String?),
      scheduledDate: (map['scheduledDate'] as String?)?.trim() ?? '',
      startTime: (map['startTime'] as String?)?.trim(),
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 30,
      elapsedSeconds: (map['elapsedSeconds'] as num?)?.toInt() ?? 0,
      activeStartedAt: map['activeStartedAt'] != null
          ? DateTime.tryParse(map['activeStartedAt'].toString())
          : null,
      reminderAt: map['reminderAt'] != null
          ? DateTime.tryParse(map['reminderAt'].toString())
          : null,
      subjectId: (map['subjectId'] as String?)?.trim(),
      timetableSessionId: (map['timetableSessionId'] as String?)?.trim(),
      subtasks: subtasks,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'].toString())
          : null,
      isDeleted: map['isDeleted'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'status': status.name,
      'priority': priority.name,
      'recurrence': recurrence.name,
      'scheduledDate': scheduledDate,
      'startTime': startTime,
      'estimatedMinutes': estimatedMinutes,
      'elapsedSeconds': elapsedSeconds,
      'activeStartedAt': activeStartedAt?.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
      'subjectId': subjectId,
      'timetableSessionId': timetableSessionId,
      'subtasks': subtasks
          .map((s) => DailySubtaskModel.fromEntity(s).toMap())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}
