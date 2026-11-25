import '../../../../core/utils/date_utils.dart';
import '../entities/daily_task_entity.dart';

/// State transition engine managing task execution timers, completions, and recurrences.
///
/// Ownership: DailyFlow Feature (Domain Service)
// ==========================================
// DAILYFLOW ENGINE - Execution Lifecycle & Recurrence
// ==========================================

/// Result of transitioning a task's execution state.
class ExecutionTransitionResult {
  final DailyTaskEntity updatedTask;
  final DailyTaskEntity? spawnedNextTask;

  const ExecutionTransitionResult({
    required this.updatedTask,
    this.spawnedNextTask,
  });
}

/// Manages the real execution lifecycle of DailyFlow tasks:
/// - Starting / resuming execution (persisting activeStartedAt)
/// - Pausing execution (accumulating elapsedSeconds)
/// - Completing execution (stopping timer + spawning recurring next instance)
/// - Skipping / resetting / snoozing reminders
class DailyFlowExecutionEngine {
  const DailyFlowExecutionEngine();

  /// Starts or resumes [task] at [now].
  /// If [task] is already [DailyTaskStatus.inProgress], returns it unchanged.
  DailyTaskEntity startOrResume(DailyTaskEntity task, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    if (task.status == DailyTaskStatus.inProgress &&
        task.activeStartedAt != null) {
      return task;
    }

    return task.copyWith(
      status: DailyTaskStatus.inProgress,
      activeStartedAt: effectiveNow,
      clearCompletedAt: true,
      updatedAt: effectiveNow,
    );
  }

  /// Pauses an active [task], folding elapsed time since [activeStartedAt]
  /// into [elapsedSeconds].
  DailyTaskEntity pause(DailyTaskEntity task, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    if (task.status != DailyTaskStatus.inProgress) {
      return task;
    }
    final accumulated = task.totalElapsedSecondsAt(effectiveNow);
    return task.copyWith(
      status: DailyTaskStatus.paused,
      elapsedSeconds: accumulated,
      clearActiveStartedAt: true,
      updatedAt: effectiveNow,
    );
  }

  /// Marks [task] as completed, stops any active timer, and generates the next
  /// recurring occurrence if [task.recurrence] is not [DailyTaskRecurrence.none].
  ExecutionTransitionResult complete(
    DailyTaskEntity task, {
    DateTime? now,
    String Function()? idGenerator,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final accumulated = task.totalElapsedSecondsAt(effectiveNow);
    final completedTask = task.copyWith(
      status: DailyTaskStatus.completed,
      elapsedSeconds: accumulated,
      clearActiveStartedAt: true,
      completedAt: effectiveNow,
      updatedAt: effectiveNow,
    );

    DailyTaskEntity? nextOccurrence;
    if (task.recurrence != DailyTaskRecurrence.none) {
      nextOccurrence = _buildNextRecurrence(
        task,
        effectiveNow,
        idGenerator: idGenerator,
      );
    }

    return ExecutionTransitionResult(
      updatedTask: completedTask,
      spawnedNextTask: nextOccurrence,
    );
  }

  /// Skips [task] for the scheduled day, stopping any active timer.
  DailyTaskEntity skip(DailyTaskEntity task, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    final accumulated = task.totalElapsedSecondsAt(effectiveNow);
    return task.copyWith(
      status: DailyTaskStatus.skipped,
      elapsedSeconds: accumulated,
      clearActiveStartedAt: true,
      updatedAt: effectiveNow,
    );
  }

  /// Reopens a completed or skipped task back to [DailyTaskStatus.planned].
  DailyTaskEntity reopen(DailyTaskEntity task, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    return task.copyWith(
      status: DailyTaskStatus.planned,
      clearActiveStartedAt: true,
      clearCompletedAt: true,
      updatedAt: effectiveNow,
    );
  }

  /// Snoozes [task]'s reminder by [duration] from [now] (or current reminder if future).
  DailyTaskEntity snoozeReminder(
    DailyTaskEntity task,
    Duration duration, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final base =
        (task.reminderAt != null && task.reminderAt!.isAfter(effectiveNow))
        ? task.reminderAt!
        : effectiveNow;
    return task.copyWith(
      reminderAt: base.add(duration),
      updatedAt: effectiveNow,
    );
  }

  /// Toggles a subtask by [subtaskId] and updates [updatedAt].
  DailyTaskEntity toggleSubtask(
    DailyTaskEntity task,
    String subtaskId, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final updatedSubtasks = task.subtasks
        .map((s) => s.id == subtaskId ? s.copyWith(isDone: !s.isDone) : s)
        .toList();
    return task.copyWith(subtasks: updatedSubtasks, updatedAt: effectiveNow);
  }

  DailyTaskEntity _buildNextRecurrence(
    DailyTaskEntity source,
    DateTime now, {
    String Function()? idGenerator,
  }) {
    final baseDate =
        DateTime.tryParse(source.scheduledDate) ??
        DateTime(now.year, now.month, now.day);
    DateTime nextDate;
    switch (source.recurrence) {
      case DailyTaskRecurrence.daily:
        nextDate = baseDate.add(const Duration(days: 1));
      case DailyTaskRecurrence.weekdays:
        nextDate = baseDate.add(const Duration(days: 1));
        while (nextDate.weekday == DateTime.saturday ||
            nextDate.weekday == DateTime.sunday) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
      case DailyTaskRecurrence.weekly:
        nextDate = baseDate.add(const Duration(days: 7));
      case DailyTaskRecurrence.none:
        nextDate = baseDate;
    }

    DateTime? nextReminder;
    if (source.reminderAt != null) {
      final diff = nextDate.difference(
        DateTime(baseDate.year, baseDate.month, baseDate.day),
      );
      nextReminder = source.reminderAt!.add(diff);
    }

    final nextId =
        idGenerator?.call() ??
        'df_${now.microsecondsSinceEpoch}_${source.id.hashCode.abs()}';

    return DailyTaskEntity(
      id: nextId,
      title: source.title,
      notes: source.notes,
      status: DailyTaskStatus.planned,
      priority: source.priority,
      recurrence: source.recurrence,
      scheduledDate: AppDateUtils.formatDateKey(nextDate),
      startTime: source.startTime,
      estimatedMinutes: source.estimatedMinutes,
      elapsedSeconds: 0,
      reminderAt: nextReminder,
      subjectId: source.subjectId,
      timetableSessionId: source.timetableSessionId,
      subtasks: source.subtasks.map((s) => s.copyWith(isDone: false)).toList(),
      createdAt: now,
      updatedAt: now,
    );
  }
}
