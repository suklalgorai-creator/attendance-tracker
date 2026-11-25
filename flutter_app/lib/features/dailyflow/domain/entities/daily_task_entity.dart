/// Execution lifecycle states for a DailyFlow task.
enum DailyTaskStatus {
  planned,
  inProgress,
  paused,
  completed,
  skipped,
  archived;

  static DailyTaskStatus fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
        return DailyTaskStatus.inProgress;
      case 'paused':
        return DailyTaskStatus.paused;
      case 'completed':
        return DailyTaskStatus.completed;
      case 'skipped':
        return DailyTaskStatus.skipped;
      case 'archived':
        return DailyTaskStatus.archived;
      case 'planned':
      default:
        return DailyTaskStatus.planned;
    }
  }

  String get label {
    switch (this) {
      case DailyTaskStatus.planned:
        return 'Planned';
      case DailyTaskStatus.inProgress:
        return 'In Progress';
      case DailyTaskStatus.paused:
        return 'Paused';
      case DailyTaskStatus.completed:
        return 'Completed';
      case DailyTaskStatus.skipped:
        return 'Skipped';
      case DailyTaskStatus.archived:
        return 'Archived';
    }
  }

  bool get isTerminal =>
      this == DailyTaskStatus.completed ||
      this == DailyTaskStatus.skipped ||
      this == DailyTaskStatus.archived;
}

/// Priority levels for DailyFlow tasks.
enum DailyTaskPriority {
  low,
  medium,
  high,
  urgent;

  static DailyTaskPriority fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'low':
        return DailyTaskPriority.low;
      case 'high':
        return DailyTaskPriority.high;
      case 'urgent':
        return DailyTaskPriority.urgent;
      case 'medium':
      default:
        return DailyTaskPriority.medium;
    }
  }

  String get label {
    switch (this) {
      case DailyTaskPriority.low:
        return 'Low';
      case DailyTaskPriority.medium:
        return 'Medium';
      case DailyTaskPriority.high:
        return 'High';
      case DailyTaskPriority.urgent:
        return 'Urgent';
    }
  }

  int get weight {
    switch (this) {
      case DailyTaskPriority.urgent:
        return 4;
      case DailyTaskPriority.high:
        return 3;
      case DailyTaskPriority.medium:
        return 2;
      case DailyTaskPriority.low:
        return 1;
    }
  }
}

/// Recurrence cadence for DailyFlow tasks.
enum DailyTaskRecurrence {
  none,
  daily,
  weekdays,
  weekly;

  static DailyTaskRecurrence fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'daily':
        return DailyTaskRecurrence.daily;
      case 'weekdays':
        return DailyTaskRecurrence.weekdays;
      case 'weekly':
        return DailyTaskRecurrence.weekly;
      case 'none':
      default:
        return DailyTaskRecurrence.none;
    }
  }

  String get label {
    switch (this) {
      case DailyTaskRecurrence.none:
        return 'One-time';
      case DailyTaskRecurrence.daily:
        return 'Every day';
      case DailyTaskRecurrence.weekdays:
        return 'Weekdays';
      case DailyTaskRecurrence.weekly:
        return 'Weekly';
    }
  }
}

/// Checklist item inside a DailyFlow task.
class DailySubtaskEntity {
  final String id;
  final String title;
  final bool isDone;

  const DailySubtaskEntity({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  DailySubtaskEntity copyWith({String? id, String? title, bool? isDone}) {
    return DailySubtaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySubtaskEntity &&
          id == other.id &&
          title == other.title &&
          isDone == other.isDone;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ isDone.hashCode;
}

/// Core domain entity representing a plannable, executable task in DailyFlow.
class DailyTaskEntity {
  final String id;
  final String title;
  final String notes;
  final DailyTaskStatus status;
  final DailyTaskPriority priority;
  final DailyTaskRecurrence recurrence;
  final String scheduledDate; // YYYY-MM-DD
  final String? startTime; // HH:mm
  final int estimatedMinutes;
  final int elapsedSeconds;
  final DateTime? activeStartedAt;
  final DateTime? reminderAt;
  final String? subjectId;
  final String? timetableSessionId;
  final List<DailySubtaskEntity> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool isDeleted;

  const DailyTaskEntity({
    required this.id,
    required this.title,
    this.notes = '',
    this.status = DailyTaskStatus.planned,
    this.priority = DailyTaskPriority.medium,
    this.recurrence = DailyTaskRecurrence.none,
    required this.scheduledDate,
    this.startTime,
    this.estimatedMinutes = 30,
    this.elapsedSeconds = 0,
    this.activeStartedAt,
    this.reminderAt,
    this.subjectId,
    this.timetableSessionId,
    this.subtasks = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.isDeleted = false,
  });

  /// Total elapsed seconds including any currently running timer session.
  int totalElapsedSecondsAt(DateTime now) {
    if (status == DailyTaskStatus.inProgress && activeStartedAt != null) {
      final delta = now.difference(activeStartedAt!).inSeconds;
      return elapsedSeconds + (delta > 0 ? delta : 0);
    }
    return elapsedSeconds;
  }

  double progressRatioAt(DateTime now) {
    if (status == DailyTaskStatus.completed) return 1.0;
    if (estimatedMinutes <= 0) return 0.0;
    final totalTarget = estimatedMinutes * 60;
    return (totalElapsedSecondsAt(now) / totalTarget).clamp(0.0, 1.0);
  }

  DailyTaskEntity copyWith({
    String? id,
    String? title,
    String? notes,
    DailyTaskStatus? status,
    DailyTaskPriority? priority,
    DailyTaskRecurrence? recurrence,
    String? scheduledDate,
    String? startTime,
    bool clearStartTime = false,
    int? estimatedMinutes,
    int? elapsedSeconds,
    DateTime? activeStartedAt,
    bool clearActiveStartedAt = false,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    String? subjectId,
    bool clearSubjectId = false,
    String? timetableSessionId,
    bool clearTimetableSessionId = false,
    List<DailySubtaskEntity>? subtasks,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? isDeleted,
  }) {
    return DailyTaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      activeStartedAt: clearActiveStartedAt
          ? null
          : (activeStartedAt ?? this.activeStartedAt),
      reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      timetableSessionId: clearTimetableSessionId
          ? null
          : (timetableSessionId ?? this.timetableSessionId),
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTaskEntity &&
          id == other.id &&
          title == other.title &&
          notes == other.notes &&
          status == other.status &&
          priority == other.priority &&
          recurrence == other.recurrence &&
          scheduledDate == other.scheduledDate &&
          startTime == other.startTime &&
          estimatedMinutes == other.estimatedMinutes &&
          elapsedSeconds == other.elapsedSeconds &&
          activeStartedAt == other.activeStartedAt &&
          reminderAt == other.reminderAt &&
          subjectId == other.subjectId &&
          timetableSessionId == other.timetableSessionId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          completedAt == other.completedAt &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    notes,
    status,
    priority,
    recurrence,
    scheduledDate,
    startTime,
    estimatedMinutes,
    elapsedSeconds,
    activeStartedAt,
    reminderAt,
    subjectId,
    timetableSessionId,
    createdAt,
    updatedAt,
    completedAt,
    isDeleted,
  );
}
