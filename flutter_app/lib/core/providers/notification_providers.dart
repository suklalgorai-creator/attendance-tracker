import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/attendance/domain/entities/attendance_status.dart';
import '../../features/sync/presentation/providers/sync_providers.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';
import 'repository_providers.dart';

/// Provider for [NotificationService] using the real local notifications implementation.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return FlutterLocalNotificationServiceImpl();
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
  final settings = ref.watch(settingsStreamProvider).valueOrNull;
  final smartEnabled =
      (settings?.pushNotificationsEnabled ?? false) &&
      (settings?.dailyFlowSmartRemindersEnabled ?? true);
  final followUpsEnabled =
      smartEnabled && (settings?.dailyFlowFollowUpsEnabled ?? true);

  tasksAsync.whenData((tasks) async {
    final now = DateTime.now();
    for (final task in tasks) {
      if (smartEnabled &&
          task.reminderAt != null &&
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

      if (followUpsEnabled && !task.status.isTerminal && !task.isDeleted) {
        final followUpAt = computeTaskFollowUpTime(task, now);
        if (followUpAt != null && followUpAt.isAfter(now)) {
          await notificationService.schedulePendingTaskFollowUp(
            taskId: task.id,
            title: task.title,
            followUpAt: followUpAt,
          );
        } else {
          await notificationService.cancelPendingTaskFollowUp(task.id);
        }
      } else {
        await notificationService.cancelPendingTaskFollowUp(task.id);
      }
    }
  });
});

/// Schedules recurring DailyFlow morning briefing (07:00 default), evening review
/// (22:00 default), and next-day planning notifications using OS-level daily triggers.
final dailyFlowRoutineSchedulerProvider = Provider<void>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final tasks = ref.watch(dailyFlowTasksStreamProvider).valueOrNull ?? const [];

  settingsAsync.whenData((settings) async {
    final todayKey = AppDateUtils.todayStr();
    final todayCount = tasks
        .where(
          (t) =>
              !t.isDeleted &&
              !t.status.isTerminal &&
              t.scheduledDate == todayKey,
        )
        .length;
    final carryoverCount = tasks
        .where(
          (t) =>
              !t.isDeleted &&
              !t.status.isTerminal &&
              t.scheduledDate.compareTo(todayKey) < 0,
        )
        .length;

    await notificationService.scheduleDailyFlowRoutineReminders(
      isEnabled:
          settings.pushNotificationsEnabled &&
          settings.dailyFlowSmartRemindersEnabled,
      morningTime: settings.dailyFlowMorningTime,
      eveningTime: settings.dailyFlowEveningTime,
      todayTaskCount: todayCount,
      pendingCarryoverCount: carryoverCount,
    );
  });
});

/// Computes an OS-scheduled follow-up time for a pending DailyFlow task.
DateTime? computeTaskFollowUpTime(dynamic task, DateTime now) {
  final date = DateTime.tryParse(task.scheduledDate as String);
  if (date == null) return null;
  if (task.startTime != null && (task.startTime as String).contains(':')) {
    final parts = (task.startTime as String).split(':');
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h != null && m != null) {
      final start = DateTime(date.year, date.month, date.day, h, m);
      return start.add(Duration(minutes: (task.estimatedMinutes as int) + 15));
    }
  }
  return DateTime(date.year, date.month, date.day, 19, 0);
}
