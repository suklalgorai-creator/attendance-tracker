import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/notification_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../domain/repositories/daily_flow_repository.dart';
import '../../domain/services/daily_flow_execution_engine.dart';

/// Controller orchestrating DailyFlow task CRUD, real execution lifecycle
/// transitions, recurring task generation, and local reminder scheduling.
class DailyFlowController extends StateNotifier<AsyncValue<void>> {
  final DailyFlowRepository _repository;
  final DailyFlowExecutionEngine _engine;
  final NotificationService _notificationService;
  final void Function()? _onDataMutated;

  DailyFlowController({
    required DailyFlowRepository repository,
    required DailyFlowExecutionEngine engine,
    required NotificationService notificationService,
    void Function()? onDataMutated,
  }) : _repository = repository,
       _engine = engine,
       _notificationService = notificationService,
       _onDataMutated = onDataMutated,
       super(const AsyncValue.data(null));

  Future<void> saveTask(DailyTaskEntity task) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveTask(task);
      await _syncReminder(task);
      _onDataMutated?.call();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Starts or resumes [task], automatically pausing any other currently
  /// running task so focus execution remains single-threaded.
  Future<void> startTask(DailyTaskEntity task, {DateTime? now}) async {
    state = const AsyncValue.loading();
    try {
      final effectiveNow = now ?? DateTime.now();
      final all = await _repository.getTasks();
      for (final existing in all) {
        if (existing.id != task.id &&
            !existing.isDeleted &&
            existing.status == DailyTaskStatus.inProgress) {
          final paused = _engine.pause(existing, now: effectiveNow);
          await _repository.saveTask(paused);
        }
      }

      final started = _engine.startOrResume(task, now: effectiveNow);
      await _repository.saveTask(started);
      _onDataMutated?.call();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> pauseTask(DailyTaskEntity task, {DateTime? now}) async {
    state = const AsyncValue.loading();
    try {
      final paused = _engine.pause(task, now: now);
      await _repository.saveTask(paused);
      _onDataMutated?.call();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeTask(DailyTaskEntity task, {DateTime? now}) async {
    state = const AsyncValue.loading();
    try {
      final result = _engine.complete(task, now: now);
      await _repository.saveTask(result.updatedTask);
      await _notificationService.cancelTaskReminder(result.updatedTask.id);
      await _notificationService.cancelPendingTaskFollowUp(
        result.updatedTask.id,
      );

      if (result.spawnedNextTask != null) {
        await _repository.saveTask(result.spawnedNextTask!);
        await _syncReminder(result.spawnedNextTask!);
      }

      _onDataMutated?.call();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> skipTask(DailyTaskEntity task, {DateTime? now}) async {
    state = const AsyncValue.loading();
    try {
      final skipped = _engine.skip(task, now: now);
      await _repository.saveTask(skipped);
      await _notificationService.cancelTaskReminder(skipped.id);
      await _notificationService.cancelPendingTaskFollowUp(skipped.id);
      _onDataMutated?.call();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reopenTask(DailyTaskEntity task, {DateTime? now}) async {
    state = const AsyncValue.loading();
    try {
      final reopened = _engine.reopen(task, now: now);
      await _repository.saveTask(reopened);
      await _syncReminder(reopened);
      _onDataMutated?.call();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> snoozeReminder(
    DailyTaskEntity task,
    Duration duration, {
    DateTime? now,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = _engine.snoozeReminder(task, duration, now: now);
      await _repository.saveTask(updated);
      await _syncReminder(updated);
      _onDataMutated?.call();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSubtask(
    DailyTaskEntity task,
    String subtaskId, {
    DateTime? now,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = _engine.toggleSubtask(task, subtaskId, now: now);
      await _repository.saveTask(updated);
      _onDataMutated?.call();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTask(id);
      await _notificationService.cancelTaskReminder(id);
      await _notificationService.cancelPendingTaskFollowUp(id);
      _onDataMutated?.call();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _syncReminder(DailyTaskEntity task) async {
    if (task.reminderAt != null &&
        !task.status.isTerminal &&
        !task.isDeleted &&
        task.reminderAt!.isAfter(DateTime.now())) {
      await _notificationService.scheduleTaskReminder(
        taskId: task.id,
        title: 'DailyFlow: ${task.title}',
        body: task.notes.trim().isNotEmpty
            ? task.notes.trim()
            : 'Scheduled ${task.priority.label.toLowerCase()} priority task (${task.estimatedMinutes}m)',
        reminderAt: task.reminderAt!,
      );
    } else {
      await _notificationService.cancelTaskReminder(task.id);
    }
  }
}

final dailyFlowExecutionEngineProvider = Provider<DailyFlowExecutionEngine>((
  ref,
) {
  return const DailyFlowExecutionEngine();
});

final dailyFlowControllerProvider =
    StateNotifierProvider<DailyFlowController, AsyncValue<void>>((ref) {
      return DailyFlowController(
        repository: ref.watch(dailyFlowRepositoryProvider),
        engine: ref.watch(dailyFlowExecutionEngineProvider),
        notificationService: ref.watch(notificationServiceProvider),
      );
    });
