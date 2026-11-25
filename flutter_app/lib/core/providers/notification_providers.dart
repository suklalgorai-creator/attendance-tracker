import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/attendance/domain/entities/attendance_status.dart';
import '../../features/sync/presentation/providers/sync_providers.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';
import 'repository_providers.dart';

/// Provider for [NotificationService] using the real local notifications implementation.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = FlutterLocalNotificationServiceImpl();
  service.initialize();
  return service;
});

/// Auto-sync notifier that schedules reminders when user settings, holidays,
/// or today's attendance marking state update.
final notificationSchedulerProvider = Provider<void>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final records =
      ref.watch(attendanceRecordsStreamProvider).valueOrNull ?? const [];
  final legacy =
      ref.watch(legacyAttendanceStreamProvider).valueOrNull ?? const [];
  final globalSettings = ref.watch(globalSettingsProvider).valueOrNull;

  settingsAsync.whenData((settings) async {
    Map<String, dynamic> holidays = {};
    if (globalSettings != null && globalSettings['holidays'] is Map) {
      holidays = Map<String, dynamic>.from(globalSettings['holidays'] as Map);
    }

    final todayKey = AppDateUtils.todayStr();
    final hasLegacyToday = legacy.any(
      (l) => !l.isDeleted && l.date == todayKey,
    );
    final hasSessionToday = records.any(
      (r) =>
          !r.isDeleted &&
          r.date == todayKey &&
          r.status != AttendanceStatus.unmarked,
    );
    final isTodayMarked = hasLegacyToday || hasSessionToday;

    await notificationService.scheduleAttendanceReminder(
      reminderTime: settings.reminderTime,
      classDays: settings.classDays,
      isEnabled: settings.pushNotificationsEnabled,
      holidays: holidays,
      isTodayMarked: isTodayMarked,
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
