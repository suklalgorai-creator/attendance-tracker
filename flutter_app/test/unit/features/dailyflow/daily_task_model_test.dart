import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/features/dailyflow/data/models/daily_task_model.dart';
import 'package:flutter_app/features/dailyflow/domain/entities/daily_task_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyTaskModel Serialization', () {
    test('round-trips entity through toMap and fromMap', () {
      final now = DateTime(2026, 11, 25, 14, 0);
      final reminder = DateTime(2026, 11, 25, 16, 0);
      final entity = DailyTaskEntity(
        id: 'df_1',
        title: 'Finish DBMS ER Diagram',
        notes: 'Normalize to 3NF',
        status: DailyTaskStatus.paused,
        priority: DailyTaskPriority.high,
        recurrence: DailyTaskRecurrence.weekly,
        scheduledDate: '2026-11-25',
        startTime: '15:30',
        estimatedMinutes: 45,
        elapsedSeconds: 320,
        reminderAt: reminder,
        subjectId: 'sub_dbms',
        subtasks: const [
          DailySubtaskEntity(id: 'st_1', title: 'Entities', isDone: true),
          DailySubtaskEntity(id: 'st_2', title: 'Relations', isDone: false),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final map = DailyTaskModel.fromEntity(entity).toMap();
      final decoded = DailyTaskModel.fromMap(map);

      expect(decoded.id, entity.id);
      expect(decoded.title, entity.title);
      expect(decoded.notes, entity.notes);
      expect(decoded.status, DailyTaskStatus.paused);
      expect(decoded.priority, DailyTaskPriority.high);
      expect(decoded.recurrence, DailyTaskRecurrence.weekly);
      expect(decoded.startTime, '15:30');
      expect(decoded.estimatedMinutes, 45);
      expect(decoded.elapsedSeconds, 320);
      expect(decoded.reminderAt, reminder);
      expect(decoded.subjectId, 'sub_dbms');
      expect(decoded.subtasks.length, 2);
      expect(decoded.subtasks.first.isDone, isTrue);
    });
  });

  group('DefaultNotificationService DailyFlow Reminders', () {
    test(
      'schedules and cancels task reminders in dedicated namespace',
      () async {
        final service = DefaultNotificationService();
        await service.initialize();

        final future = DateTime.now().add(const Duration(hours: 2));
        await service.scheduleTaskReminder(
          taskId: 'df_42',
          title: 'DailyFlow: OS Lab',
          body: 'Review scheduling algorithms',
          reminderAt: future,
        );

        expect(service.scheduledReminders.length, 1);
        expect(
          service.scheduledReminders.first.id,
          DefaultNotificationService.defaultTaskNotificationId('df_42'),
        );

        await service.cancelTaskReminder('df_42');
        expect(service.scheduledReminders, isEmpty);
      },
    );
  });
}
