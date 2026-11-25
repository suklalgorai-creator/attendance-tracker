import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/date_utils.dart';
import 'notification_service.dart';

/// Production `flutter_local_notifications` implementation for Android, iOS, and macOS.
///
/// Ownership: Core Notifications
// ==========================================
// NOTIFICATIONS - Platform Implementation
// Handles timezone setup, permissions, channels, exact/inexact zoned scheduling,
// DailyFlow routine/task alerts, note alerts, and attendance reminders.
// ==========================================

/// Production implementation integrating `flutter_local_notifications`.
class FlutterLocalNotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _initialized = false;
  Future<void>? _initializingFuture;

  FlutterLocalNotificationServiceImpl({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() {
    if (_initialized) return Future.value();
    return _initializingFuture ??= _performInitialize();
  }

  Future<void> _performInitialize() async {
    try {
      tz.initializeTimeZones();
      _configureLocalTimeZone();
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          handleAttendanceNotificationAction(response);
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _initialized = true;
    } catch (_) {
      // Safe fallback on desktop/unsupported platforms.
      _initializingFuture = null;
    }
  }

  @override
  Future<bool> requestNotificationPermissions() async {
    await initialize();
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlatform != null) {
        final granted = await iosPlatform.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (_) {}
    return true;
  }

  @override
  Future<String?> requestFCMToken() async => null;

  @override
  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }

  Future<void> cancelAttendanceReminders() async {
    for (int d = 0; d <= 6; d++) {
      try {
        await _notificationsPlugin.cancel(id: 1000 + d);
      } catch (_) {}
    }
  }

  // ==========================================
  // STICKY NOTE REMINDERS
  // ==========================================

  static int noteNotificationId(String noteId) =>
      noteReminderNotificationId(noteId);

  @override
  Future<void> scheduleNoteReminder({
    required String noteId,
    required String content,
    required DateTime reminderDate,
  }) async {
    await initialize();
    await cancelNoteReminder(noteId);
    if (!reminderDate.isAfter(DateTime.now())) return;

    try {
      final tzScheduled = tz.TZDateTime.from(reminderDate, tz.local);
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'sticky_note_reminders',
          'Sticky Note Reminders',
          channelDescription: 'Reminders for sticky notes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      final body = content.length > 100 ? content.substring(0, 100) : content;
      await _zonedScheduleWithFallback(
        id: noteNotificationId(noteId),
        title: 'Sticky Note Reminder 📝',
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: notificationDetails,
        payload: 'note:$noteId',
      );
    } catch (_) {}
  }

  @override
  Future<void> cancelNoteReminder(String noteId) async {
    try {
      await _notificationsPlugin.cancel(id: noteNotificationId(noteId));
    } catch (_) {}
  }

  // ==========================================
  // DAILYFLOW TASK & ROUTINE REMINDERS
  // ==========================================

  static int taskNotificationId(String taskId) =>
      taskReminderNotificationId(taskId);

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime reminderAt,
  }) async {
    await initialize();
    await cancelTaskReminder(taskId);
    if (!reminderAt.isAfter(DateTime.now())) return;

    try {
      final tzScheduled = tz.TZDateTime.from(reminderAt, tz.local);
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'dailyflow_task_reminders',
          'DailyFlow Task Reminders',
          channelDescription: 'Scheduled reminders for DailyFlow tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      final truncatedBody = body.length > 120 ? body.substring(0, 120) : body;
      await _zonedScheduleWithFallback(
        id: taskNotificationId(taskId),
        title: title,
        body: truncatedBody,
        scheduledDate: tzScheduled,
        notificationDetails: notificationDetails,
        payload: 'dailyflow:$taskId',
      );
    } catch (_) {}
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    try {
      await _notificationsPlugin.cancel(id: taskNotificationId(taskId));
    } catch (_) {}
  }

  static int followUpNotificationId(String taskId) =>
      followUpReminderNotificationId(taskId);

  @override
  Future<void> schedulePendingTaskFollowUp({
    required String taskId,
    required String title,
    required DateTime followUpAt,
  }) async {
    await initialize();
    await cancelPendingTaskFollowUp(taskId);
    if (!followUpAt.isAfter(DateTime.now())) return;

    try {
      final tzScheduled = tz.TZDateTime.from(followUpAt, tz.local);
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'dailyflow_followup_reminders',
          'DailyFlow Pending Task Follow-Ups',
          channelDescription: 'Follow-up reminders for pending DailyFlow tasks',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _zonedScheduleWithFallback(
        id: followUpNotificationId(taskId),
        title: 'Pending Task: $title',
        body: 'Still pending in DailyFlow. Tap to resume or complete.',
        scheduledDate: tzScheduled,
        notificationDetails: notificationDetails,
        payload: 'dailyflow:$taskId',
      );
    } catch (_) {}
  }

  @override
  Future<void> cancelPendingTaskFollowUp(String taskId) async {
    try {
      await _notificationsPlugin.cancel(id: followUpNotificationId(taskId));
    } catch (_) {}
  }

  @override
  Future<void> cancelDailyFlowRoutineReminders() async {
    for (final id in const [40001, 40002, 40003]) {
      try {
        await _notificationsPlugin.cancel(id: id);
      } catch (_) {}
    }
  }

  @override
  Future<void> scheduleDailyFlowRoutineReminders({
    required bool isEnabled,
    String morningTime = '07:00',
    String eveningTime = '22:00',
    String nextDayPlanTime = '21:15',
    int todayTaskCount = 0,
    int pendingCarryoverCount = 0,
  }) async {
    await initialize();
    await cancelDailyFlowRoutineReminders();
    if (!isEnabled) return;

    final now = DateTime.now();
    final morningBody = buildMorningBriefingBody(
      todayTaskCount: todayTaskCount,
      pendingCarryoverCount: pendingCarryoverCount,
    );
    final routines = <(int, String, String, String, String)>[
      (
        40001,
        morningTime,
        'Good Morning — DailyFlow ☀️',
        morningBody,
        'dailyflow:morning',
      ),
      (
        40002,
        eveningTime,
        'Evening DailyFlow Review 🌙',
        'Your day is almost over. Take a moment to review your tasks and prepare tomorrow.',
        'dailyflow:evening',
      ),
      (
        40003,
        nextDayPlanTime,
        'Plan Tomorrow in DailyFlow 🗓️',
        'Set priorities and reminders for tomorrow\'s schedule.',
        'dailyflow:next_day',
      ),
    ];

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'dailyflow_routine_reminders',
        'DailyFlow Planning & Review',
        channelDescription:
            'Daily morning briefing, evening review, and next-day planning alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (final (id, timeStr, title, body, payload) in routines) {
      final parts = DefaultNotificationService.parseTime(timeStr);
      var target = DateTime(now.year, now.month, now.day, parts[0], parts[1]);
      if (!target.isAfter(now)) {
        target = target.add(const Duration(days: 1));
      }

      try {
        final tzScheduled = tz.TZDateTime.from(target, tz.local);
        await _zonedScheduleWithFallback(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduled,
          notificationDetails: notificationDetails,
          payload: payload,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }

  // ==========================================
  // DAILY ATTENDANCE REMINDERS & HELPERS
  // ==========================================

  void _configureLocalTimeZone() {
    final localOffset = DateTime.now().timeZoneOffset;
    if (tz.local.currentTimeZone.offset == localOffset) return;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.currentTimeZone.offset == localOffset) {
        tz.setLocalLocation(loc);
        return;
      }
    }
  }

  Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (_) {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    }
  }

  @override
  Future<void> scheduleAttendanceReminder({
    required String reminderTime,
    required List<int> classDays,
    required bool isEnabled,
    Map<String, dynamic> holidays = const {},
    bool isTodayMarked = false,
  }) async {
    await initialize();
    await cancelAttendanceReminders();
    if (!isEnabled || classDays.isEmpty) return;

    final timeParts = DefaultNotificationService.parseTime(reminderTime);
    final hour = timeParts[0];
    final minute = timeParts[1];
    final now = DateTime.now();
    final todayKey = formatDateKey(now);

    for (final dayOfWeek in classDays) {
      var scheduledDate = DefaultNotificationService.calculateNextOccurrence(
        now: now,
        targetDayOfWeek: dayOfWeek,
        hour: hour,
        minute: minute,
      );

      var dateKey = formatDateKey(scheduledDate);
      if (isTodayMarked && dateKey == todayKey) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
        dateKey = formatDateKey(scheduledDate);
      }

      if (holidays.containsKey(dateKey)) continue;

      try {
        final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);
        const notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_attendance_reminders',
            'Daily Attendance Reminders',
            channelDescription: 'Reminders to log daily college attendance',
            importance: Importance.high,
            priority: Priority.high,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                attendanceActionPresent,
                'Present',
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                attendanceActionAbsent,
                'Absent',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(),
        );

        await _zonedScheduleWithFallback(
          id: 1000 + dayOfWeek,
          title: 'Attendance Reminder 📝',
          body: "Don't forget to mark your classes for today!",
          scheduledDate: tzScheduled,
          notificationDetails: notificationDetails,
          payload: 'attendance_reminder:$dateKey',
        );
      } catch (_) {}
    }
  }
}
