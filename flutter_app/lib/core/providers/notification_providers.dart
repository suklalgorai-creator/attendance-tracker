import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/sync/presentation/providers/sync_providers.dart';
import '../services/notification_service.dart';
import 'repository_providers.dart';

/// Provider for [NotificationService] using the real local notifications implementation.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = FlutterLocalNotificationServiceImpl();
  service.initialize();
  return service;
});

/// Auto-sync notifier that schedules reminders when user settings or holidays update.
final notificationSchedulerProvider = Provider<void>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);

  settingsAsync.whenData((settings) async {
    final remoteDataSource = ref.watch(remoteSyncDataSourceProvider);
    Map<String, dynamic> holidays = {};
    try {
      final global = await remoteDataSource.fetchGlobalSettings();
      if (global['holidays'] is Map) {
        holidays = Map<String, dynamic>.from(global['holidays'] as Map);
      }
    } catch (_) {}

    await notificationService.scheduleAttendanceReminder(
      reminderTime: settings.reminderTime,
      classDays: settings.classDays,
      isEnabled: settings.pushNotificationsEnabled,
      holidays: holidays,
    );
  });
});

/// Reconciles DailyFlow task reminders with the OS notification scheduler
/// whenever tasks are loaded or modified.
final dailyFlowReminderSchedulerProvider = Provider<void>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final tasksAsync = ref.watch(dailyFlowTasksStreamProvider);

  tasksAsync.whenData((tasks) async {
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.reminderAt != null &&
          !task.status.isTerminal &&
          !task.isDeleted &&
          task.reminderAt!.isAfter(now)) {
        await notificationService.scheduleTaskReminder(
          taskId: task.id,
          title: 'DailyFlow: ${task.title}',
          body: task.notes.trim().isNotEmpty
              ? task.notes.trim()
              : 'Scheduled ${task.priority.label.toLowerCase()} priority task (${task.estimatedMinutes}m)',
          reminderAt: task.reminderAt!,
        );
      } else {
        await notificationService.cancelTaskReminder(task.id);
      }
    }
  });
});
