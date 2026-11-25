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
  final existing = await dataSource.getLegacyRecordById(
    'daily-$effectiveDate',
  );
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
    debugPrint('[NOTIFICATION] Background action error: $e');
  }
}

/// Contract for system notifications and scheduled reminders.
abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleAttendanceReminder({
    required String reminderTime,
    required List<int> classDays,
    required bool isEnabled,
    Map<String, dynamic> holidays = const {},
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

  @override
  Future<void> scheduleNoteReminder({
    required String noteId,
    required String content,
    required DateTime reminderDate,
  }) async {
    await cancelNoteReminder(noteId);
    if (!reminderDate.isAfter(DateTime.now())) return;
    final id = 20000 + (noteId.hashCode.abs() % 100000);
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
    final id = 20000 + (noteId.hashCode.abs() % 100000);
    _scheduledReminders.removeWhere((r) => r.id == id);
  }

  static int defaultTaskNotificationId(String taskId) =>
      30000 + (taskId.hashCode.abs() % 100000);

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

  @override
  Future<void> scheduleAttendanceReminder({
    required String reminderTime,
    required List<int> classDays,
    required bool isEnabled,
    Map<String, dynamic> holidays = const {},
  }) async {
    await cancelAllReminders();

    if (!isEnabled || classDays.isEmpty) {
      return;
    }

    final timeParts = parseTime(reminderTime);
    final hour = timeParts[0];
    final minute = timeParts[1];

    final now = DateTime.now();

    for (final dayOfWeek in classDays) {
      final scheduledDate = calculateNextOccurrence(
        now: now,
        targetDayOfWeek: dayOfWeek,
        hour: hour,
        minute: minute,
      );

      final dateKey = formatDateKey(scheduledDate);
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

  FlutterLocalNotificationServiceImpl({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
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
    }
  }

  @override
  Future<bool> requestNotificationPermissions() async {
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

  static int noteNotificationId(String noteId) =>
      20000 + (noteId.hashCode.abs() % 100000);

  @override
  Future<void> scheduleNoteReminder({
    required String noteId,
    required String content,
    required DateTime reminderDate,
  }) async {
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
      await _notificationsPlugin.zonedSchedule(
        id: noteNotificationId(noteId),
        title: 'Sticky Note Reminder 📝',
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
      30000 + (taskId.hashCode.abs() % 100000);

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime reminderAt,
  }) async {
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
      await _notificationsPlugin.zonedSchedule(
        id: taskNotificationId(taskId),
        title: title,
        body: truncatedBody,
        scheduledDate: tzScheduled,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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

  @override
  Future<void> scheduleAttendanceReminder({
    required String reminderTime,
    required List<int> classDays,
    required bool isEnabled,
    Map<String, dynamic> holidays = const {},
  }) async {
    await cancelAllReminders();

    if (!isEnabled || classDays.isEmpty) return;

    final timeParts = DefaultNotificationService.parseTime(reminderTime);
    final hour = timeParts[0];
    final minute = timeParts[1];

    final now = DateTime.now();

    for (final dayOfWeek in classDays) {
      final scheduledDate = DefaultNotificationService.calculateNextOccurrence(
        now: now,
        targetDayOfWeek: dayOfWeek,
        hour: hour,
        minute: minute,
      );

      final dateKey = formatDateKey(scheduledDate);
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

        await _notificationsPlugin.zonedSchedule(
          id: 1000 + dayOfWeek,
          title: 'Attendance Reminder 📝',
          body: "Don't forget to mark your classes for today!",
          scheduledDate: tzScheduled,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'attendance_reminder:$dateKey',
        );
      } catch (_) {
        // Fallback or test environment
      }
    }
  }
}
