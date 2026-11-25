import 'package:flutter_app/features/dailyflow/domain/entities/daily_task_entity.dart';
import 'package:flutter_app/features/dailyflow/domain/services/daily_flow_execution_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = DailyFlowExecutionEngine();

  DailyTaskEntity makeTask({
    DailyTaskStatus status = DailyTaskStatus.planned,
    DailyTaskRecurrence recurrence = DailyTaskRecurrence.none,
    String scheduledDate = '2026-11-27', // Friday
    int elapsedSeconds = 0,
    DateTime? activeStartedAt,
    DateTime? reminderAt,
    List<DailySubtaskEntity> subtasks = const [],
  }) {
    final base = DateTime(2026, 11, 27, 9, 0);
    return DailyTaskEntity(
      id: 'task_1',
      title: 'Study OS Scheduling',
      status: status,
      recurrence: recurrence,
      scheduledDate: scheduledDate,
      elapsedSeconds: elapsedSeconds,
      activeStartedAt: activeStartedAt,
      reminderAt: reminderAt,
      subtasks: subtasks,
      createdAt: base,
      updatedAt: base,
    );
  }

  group('DailyFlowExecutionEngine', () {
    test('startOrResume sets inProgress and activeStartedAt', () {
      final now = DateTime(2026, 11, 27, 10, 0);
      final started = engine.startOrResume(makeTask(), now: now);

      expect(started.status, DailyTaskStatus.inProgress);
      expect(started.activeStartedAt, now);
    });

    test('pause accumulates elapsedSeconds and clears activeStartedAt', () {
      final start = DateTime(2026, 11, 27, 10, 0);
      final pauseAt = DateTime(2026, 11, 27, 10, 12, 30);
      final running = makeTask(
        status: DailyTaskStatus.inProgress,
        elapsedSeconds: 60,
        activeStartedAt: start,
      );

      final paused = engine.pause(running, now: pauseAt);

      expect(paused.status, DailyTaskStatus.paused);
      expect(paused.activeStartedAt, isNull);
      expect(paused.elapsedSeconds, 60 + 750);
    });

    test('complete stops timer and spawns next weekday skipping weekend', () {
      final start = DateTime(2026, 11, 27, 10, 0);
      final doneAt = DateTime(2026, 11, 27, 10, 20);
      final reminder = DateTime(2026, 11, 27, 9, 30);
      final task = makeTask(
        status: DailyTaskStatus.inProgress,
        recurrence: DailyTaskRecurrence.weekdays,
        scheduledDate: '2026-11-27', // Friday
        activeStartedAt: start,
        reminderAt: reminder,
        subtasks: const [
          DailySubtaskEntity(id: 's1', title: 'Read chapter', isDone: true),
        ],
      );

      final result = engine.complete(
        task,
        now: doneAt,
        idGenerator: () => 'task_next',
      );

      expect(result.updatedTask.status, DailyTaskStatus.completed);
      expect(result.updatedTask.elapsedSeconds, 1200);
      expect(result.updatedTask.completedAt, doneAt);

      final next = result.spawnedNextTask;
      expect(next, isNotNull);
      expect(next!.id, 'task_next');
      expect(next.scheduledDate, '2026-11-30'); // Monday
      expect(next.status, DailyTaskStatus.planned);
      expect(next.subtasks.single.isDone, isFalse);
      expect(next.reminderAt, DateTime(2026, 11, 30, 9, 30));
    });

    test('snoozeReminder shifts future reminder by duration', () {
      final now = DateTime(2026, 11, 27, 10, 0);
      final task = makeTask(reminderAt: DateTime(2026, 11, 27, 10, 30));
      final snoozed = engine.snoozeReminder(
        task,
        const Duration(minutes: 15),
        now: now,
      );

      expect(snoozed.reminderAt, DateTime(2026, 11, 27, 10, 45));
    });

    test('toggleSubtask flips subtask completion state', () {
      final task = makeTask(
        subtasks: const [DailySubtaskEntity(id: 's1', title: 'Step 1')],
      );
      final toggled = engine.toggleSubtask(task, 's1');
      expect(toggled.subtasks.single.isDone, isTrue);
    });
  });
}
