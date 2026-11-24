import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/date_utils.dart';

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

      _scheduledReminders.add(ScheduledNotificationInfo(
        id: 1000 + dayOfWeek,
        scheduledTime: scheduledDate,
        title: 'Attendance Reminder 📝',
        body: "Don't forget to mark your classes for today!",
      ));
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
      final candidate = DateTime(now.year, now.month, now.day + i, hour, minute);
      final candidateDayOfWeek = candidate.weekday % 7;
      if (candidateDayOfWeek == targetDayOfWeek) {
        if (candidate.isAfter(now)) {
          return candidate;
        }
      }
    }
    // Next week if already passed today
    final nextWeekDay = DateTime(now.year, now.month, now.day + 7, hour, minute);
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

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
      );
      _initialized = true;
    } catch (_) {
      // Safe fallback on desktop/unsupported platforms
    }
  }

  @override
  Future<bool> requestNotificationPermissions() async {
    try {
      final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
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
        );
      } catch (_) {
        // Fallback or test environment
      }
    }
  }
}
