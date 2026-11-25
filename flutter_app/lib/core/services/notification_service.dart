import 'dart:async';

export 'default_notification_service.dart';
export 'flutter_local_notification_service.dart';
export 'notification_action_handler.dart';
export 'notification_helpers.dart';

/// Core notification service contract, metadata model, and module exports.
///
/// Ownership: Core Notifications
// ==========================================
// NOTIFICATIONS - Service Contract & Info Model
// Defines the platform-agnostic scheduling interface used across features.
// ==========================================

/// Contract for system notifications and scheduled reminders.
abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleAttendanceReminder({
    required String reminderTime,
    required List<int> classDays,
    required bool isEnabled,
    Map<String, dynamic> holidays = const {},
    bool isTodayMarked = false,
  });
  Future<void> cancelAllReminders();
  Future<void> scheduleNoteReminder({
    required String noteId,
    required String content,
    required DateTime reminderDate,
  });
  Future<void> cancelNoteReminder(String noteId);
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime reminderAt,
  });
  Future<void> cancelTaskReminder(String taskId);
  Future<void> schedulePendingTaskFollowUp({
    required String taskId,
    required String title,
    required DateTime followUpAt,
  });
  Future<void> cancelPendingTaskFollowUp(String taskId);
  Future<void> scheduleDailyFlowRoutineReminders({
    required bool isEnabled,
    String morningTime = '07:00',
    String eveningTime = '22:00',
    String nextDayPlanTime = '21:15',
    int todayTaskCount = 0,
    int pendingCarryoverCount = 0,
  });
  Future<void> cancelDailyFlowRoutineReminders();
  Future<String?> requestFCMToken();
  Future<bool> requestNotificationPermissions();
}

/// Snapshot metadata for an in-memory scheduled notification (used by [DefaultNotificationService]).
class ScheduledNotificationInfo {
  final int id;
  final DateTime scheduledTime;
  final String title;
  final String body;

  const ScheduledNotificationInfo({
    required this.id,
    required this.scheduledTime,
    required this.title,
    required this.body,
  });

  @override
  String toString() =>
      'ScheduledNotificationInfo(id: $id, scheduledTime: $scheduledTime, title: $title)';
}
