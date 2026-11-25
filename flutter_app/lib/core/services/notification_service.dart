import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/attendance/data/datasources/attendance_local_datasource.dart';
import '../../features/attendance/data/models/legacy_attendance_model.dart';
import '../utils/date_utils.dart';
import 'database_service.dart';

const String attendanceActionPresent = 'mark_present';
const String attendanceActionAbsent = 'mark_absent';

/// Handles quick-action taps (`Present` / `Absent`) from daily attendance
/// notifications in both foreground and background/terminated isolates.
Future<bool> handleAttendanceNotificationAction(
  NotificationResponse response, {
  AttendanceLocalDataSource? localDataSource,
}) async {
  final actionId = response.actionId;
  if (actionId != attendanceActionPresent &&
      actionId != attendanceActionAbsent) {
    return false;
  }

  final payload = response.payload ?? '';
  final dateKey = payload.startsWith('attendance_reminder:')
      ? payload.substring('attendance_reminder:'.length).trim()
      : formatDateKey(DateTime.now());
  final effectiveDate = dateKey.isNotEmpty
      ? dateKey
      : formatDateKey(DateTime.now());

  if (localDataSource == null &&
      !DatabaseService.isBoxOpen(DatabaseService.legacyAttendanceBoxName)) {
    await DatabaseService.init();
  }

  final dataSource = localDataSource ?? AttendanceLocalDataSourceImpl();
  final existing = await dataSource.getLegacyRecordById('daily-$effectiveDate');
  final now = DateTime.now().toUtc();
  final isPresent = actionId == attendanceActionPresent;

  await dataSource.saveLegacyAttendance(
    LegacyAttendanceModel(
      id: existing?.id ?? 'daily-$effectiveDate',
      date: effectiveDate,
      held: 1,
      attended: isPresent ? 1 : 0,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    ),
  );
  return true;
}

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  try {
    await handleAttendanceNotificationAction(response);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[NOTIFICATION] Background action error: $e');
    }
  }
}

/// Deterministic 31-bit FNV-1a hash so notification IDs remain identical
/// across isolates, restarts, and platforms (unlike Dart String.hashCode).
int _stableNotificationHash(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

String _buildMorningBriefingBody({
  required int todayTaskCount,
  required int pendingCarryoverCount,
}) {
  if (todayTaskCount > 0) {
    final noun = todayTaskCount == 1 ? 'task' : 'tasks';
    final carryover = pendingCarryoverCount > 0
        ? ' ($pendingCarryoverCount pending from earlier)'
        : '';
    return 'Good morning! Your DailyFlow plan is ready. You have $todayTaskCount $noun planned today$carryover.';
  }
  if (pendingCarryoverCount > 0) {
    return 'Good morning! Your DailyFlow plan is ready. You have $pendingCarryoverCount pending task(s) from earlier.';
  }
  return 'Good morning! Your DailyFlow plan is ready. Tap to plan your day.';
}

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

/// Offline-safe, headless-compatible implementation of [NotificationService].
class DefaultNotificationService implements NotificationService {
  bool _initialized = false;
  bool _permissionGranted = true;
  String? _simulatedFCMToken = 'mock_fcm_token_offline_device_101';
  final List<ScheduledNotificationInfo> _scheduledReminders = [];

  bool get isInitialized => _initialized;
  List<ScheduledNotificationInfo> get scheduledReminders =>
      List.unmodifiable(_scheduledReminders);

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> requestNotificationPermissions() async {
    return _permissionGranted;
  }

  void setPermissionGranted(bool granted) {
    _permissionGranted = granted;
  }

  void setFCMToken(String? token) {
    _simulatedFCMToken = token;
  }

  @override
  Future<String?> requestFCMToken() async {
    if (!_permissionGranted) return null;
    return _simulatedFCMToken;
  }

  @override
  Future<void> cancelAllReminders() async {
    _scheduledReminders.clear();
  }

  Future<void> cancelAttendanceReminders() async {
    _scheduledReminders.removeWhere((r) => r.id >= 1000 && r.id <= 1006);
  }

  @override
  Future<void> scheduleNoteReminder({
    required String noteId,
    required String content,
    required DateTime reminderDate,
  }) async {
    await cancelNoteReminder(noteId);
    if (!reminderDate.isAfter(DateTime.now())) return;
    final id = 100000 + (_stableNotificationHash(noteId) % 100000);
    _scheduledReminders.add(
      ScheduledNotificationInfo(
        id: id,
        scheduledTime: reminderDate,
        title: 'Sticky Note Reminder 📝',
        body: content.length > 100 ? content.substring(0, 100) : content,
      ),
    );
  }

  @override
  Future<void> cancelNoteReminder(String noteId) async {
    final id = 100000 + (_stableNotificationHash(noteId) % 100000);
    _scheduledReminders.removeWhere((r) => r.id == id);
  }

  static int defaultTaskNotificationId(String taskId) =>
      200000 + (_stableNotificationHash(taskId) % 100000);

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime reminderAt,
  }) async {
    await cancelTaskReminder(taskId);
    if (!reminderAt.isAfter(DateTime.now())) return;
    _scheduledReminders.add(
      ScheduledNotificationInfo(
        id: defaultTaskNotificationId(taskId),
        scheduledTime: reminderAt,
        title: title,
        body: body.length > 120 ? body.substring(0, 120) : body,
      ),
    );
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    final id = defaultTaskNotificationId(taskId);
    _scheduledReminders.removeWhere((r) => r.id == id);
  }

  static int defaultFollowUpNotificationId(String taskId) =>
      300000 + (_stableNotificationHash(taskId) % 100000);

  @override
  Future<void> schedulePendingTaskFollowUp({
    required String taskId,
    required String title,
    required DateTime followUpAt,
  }) async {
    await cancelPendingTaskFollowUp(taskId);
    if (!followUpAt.isAfter(DateTime.now())) return;
    _scheduledReminders.add(
      ScheduledNotificationInfo(
        id: defaultFollowUpNotificationId(taskId),
        scheduledTime: followUpAt,
        title: 'Pending Task: $title',
        body: 'Still pending in DailyFlow. Tap to start or mark complete.',
      ),
    );
  }

  @override
  Future<void> cancelPendingTaskFollowUp(String taskId) async {
    final id = defaultFollowUpNotificationId(taskId);
    _scheduledReminders.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> cancelDailyFlowRoutineReminders() async {
    _scheduledReminders.removeWhere((r) => r.id >= 40001 && r.id <= 40003);
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
    final morningBody = _buildMorningBriefingBody(
      todayTaskCount: todayTaskCount,
      pendingCarryoverCount: pendingCarryoverCount,
    );
    final items = <(int, String, String, String)>[
      (40001, morningTime, 'Good Morning — DailyFlow ☀️', morningBody),
      (
        40002,
        eveningTime,
        'Evening DailyFlow Review 🌙',
        'Your day is almost over. Take a moment to review your tasks and prepare tomorrow.',
      ),
      (
        40003,
        nextDayPlanTime,
        'Plan Tomorrow in DailyFlow 🗓️',
        'Set priorities and reminders for tomorrow\'s schedule.',
      ),
    ];

    for (final (id, timeStr, title, body) in items) {
      final parts = parseTime(timeStr);
      var target = DateTime(now.year, now.month, now.day, parts[0], parts[1]);
      if (!target.isAfter(now)) {
        target = target.add(const Duration(days: 1));
      }
      _scheduledReminders.add(
        ScheduledNotificationInfo(
          id: id,
          scheduledTime: target,
          title: title,
          body: body,
        ),
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
    DateTime? nowOverride,
  }) async {
    await cancelAttendanceReminders();

    if (!isEnabled || classDays.isEmpty) {
      return;
    }

    final timeParts = parseTime(reminderTime);
    final hour = timeParts[0];
    final minute = timeParts[1];

    final now = nowOverride ?? DateTime.now();
    final todayKey = formatDateKey(now);

    for (final dayOfWeek in classDays) {
      var scheduledDate = calculateNextOccurrence(
        now: now,
        targetDayOfWeek: dayOfWeek,
        hour: hour,
        minute: minute,
      );

      var dateKey = formatDateKey(scheduledDate);
      if (isTodayMarked && dateKey == todayKey) {
        // Attendance already marked for today -> suppress today and schedule next week
        scheduledDate = scheduledDate.add(const Duration(days: 7));
        dateKey = formatDateKey(scheduledDate);
      }

      if (holidays.containsKey(dateKey)) {
        // Skip declared holiday
        continue;
      }

      _scheduledReminders.add(
        ScheduledNotificationInfo(
          id: 1000 + dayOfWeek,
          scheduledTime: scheduledDate,
          title: 'Attendance Reminder 📝',
          body: "Don't forget to mark your classes for today!",
        ),
      );
    }
  }

  static List<int> parseTime(String timeStr) {
    if (!timeStr.contains(':')) return [18, 0];
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0]) ?? 18;
    final m = int.tryParse(parts[1]) ?? 0;
    return [h.clamp(0, 23), m.clamp(0, 59)];
  }

  static DateTime calculateNextOccurrence({
    required DateTime now,
    required int targetDayOfWeek,
    required int hour,
    required int minute,
  }) {
    // targetDayOfWeek: 0 = Sun, 1 = Mon ... 6 = Sat
    for (int i = 0; i < 7; i++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day + i,
        hour,
        minute,
      );
      final candidateDayOfWeek = candidate.weekday % 7;
      if (candidateDayOfWeek == targetDayOfWeek) {
        if (candidate.isAfter(now)) {
          return candidate;
        }
      }
    }
    // Next week if already passed today
    final nextWeekDay = DateTime(
      now.year,
      now.month,
      now.day + 7,
      hour,
      minute,
    );
    return nextWeekDay;
  }
}

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
      // Safe fallback on desktop/unsupported platforms
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
  Future<String?> requestFCMToken() async {
    // Platform-specific FCM token resolution
    return null;
  }

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

  static int noteNotificationId(String noteId) =>
      100000 + (_stableNotificationHash(noteId) % 100000);

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
    } catch (_) {
      // Safe fallback in headless/test/desktop environments
    }
  }

  @override
  Future<void> cancelNoteReminder(String noteId) async {
    try {
      await _notificationsPlugin.cancel(id: noteNotificationId(noteId));
    } catch (_) {}
  }

  static int taskNotificationId(String taskId) =>
      200000 + (_stableNotificationHash(taskId) % 100000);

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
    } catch (_) {
      // Safe fallback in headless/test/desktop environments
    }
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    try {
      await _notificationsPlugin.cancel(id: taskNotificationId(taskId));
    } catch (_) {}
  }

  static int followUpNotificationId(String taskId) =>
      300000 + (_stableNotificationHash(taskId) % 100000);

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
    final morningBody = _buildMorningBriefingBody(
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
        // Attendance already marked for today -> suppress today and schedule next week
        scheduledDate = scheduledDate.add(const Duration(days: 7));
        dateKey = formatDateKey(scheduledDate);
      }

      if (holidays.containsKey(dateKey)) {
        continue;
      }

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
      } catch (_) {
        // Fallback or test environment
      }
    }
  }
}
