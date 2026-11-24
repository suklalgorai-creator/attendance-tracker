import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/core/utils/date_utils.dart';

void main() {
  group('NotificationService Unit Tests', () {
    late DefaultNotificationService service;

    setUp(() {
      service = DefaultNotificationService();
    });

    test('parseTime handles valid and invalid inputs gracefully', () {
      expect(DefaultNotificationService.parseTime('18:00'), [18, 0]);
      expect(DefaultNotificationService.parseTime('09:30'), [9, 30]);
      expect(DefaultNotificationService.parseTime('invalid'), [18, 0]);
      expect(DefaultNotificationService.parseTime('25:70'), [23, 59]);
    });

    test('calculateNextOccurrence returns future datetime matching dayOfWeek and time', () {
      // 2026-11-23 was Monday (weekday % 7 = 1)
      final mondayMorning = DateTime(2026, 11, 23, 8, 0);

      // Target Tuesday (weekday % 7 = 2) at 18:00
      final nextTuesday = DefaultNotificationService.calculateNextOccurrence(
        now: mondayMorning,
        targetDayOfWeek: 2,
        hour: 18,
        minute: 0,
      );
      expect(nextTuesday.year, 2026);
      expect(nextTuesday.month, 11);
      expect(nextTuesday.day, 24);
      expect(nextTuesday.hour, 18);
      expect(nextTuesday.minute, 0);
      expect(nextTuesday.weekday % 7, 2);

      // Target Monday at 7:00 (already passed for today) -> next week Monday
      final nextMonday = DefaultNotificationService.calculateNextOccurrence(
        now: mondayMorning,
        targetDayOfWeek: 1,
        hour: 7,
        minute: 0,
      );
      expect(nextMonday.isAfter(mondayMorning), isTrue);
      expect(nextMonday.day, 30); // 23 + 7 = 30
      expect(nextMonday.weekday % 7, 1);
    });

    test('scheduleAttendanceReminder registers notifications for active classDays', () async {
      await service.scheduleAttendanceReminder(
        reminderTime: '17:30',
        classDays: [1, 2, 3], // Mon, Tue, Wed
        isEnabled: true,
      );

      expect(service.scheduledReminders.length, 3);
      final reminderIds = service.scheduledReminders.map((r) => r.id).toList();
      expect(reminderIds, containsAll([1001, 1002, 1003]));
    });

    test('scheduleAttendanceReminder skips declared holidays', () async {
      final now = DateTime.now();
      // Calculate what date next occurrence for Tuesday (2) will be
      final nextTue = DefaultNotificationService.calculateNextOccurrence(
        now: now,
        targetDayOfWeek: 2,
        hour: 18,
        minute: 0,
      );
      final holidayDateKey = formatDateKey(nextTue);

      await service.scheduleAttendanceReminder(
        reminderTime: '18:00',
        classDays: [2], // Tuesday only
        isEnabled: true,
        holidays: {holidayDateKey: 'College Foundation Day'},
      );

      // Because Tuesday is a holiday, it must be skipped!
      expect(service.scheduledReminders, isEmpty);
    });

    test('scheduleAttendanceReminder clears reminders when disabled', () async {
      await service.scheduleAttendanceReminder(
        reminderTime: '18:00',
        classDays: [1, 2, 3],
        isEnabled: true,
      );
      expect(service.scheduledReminders.isNotEmpty, isTrue);

      await service.scheduleAttendanceReminder(
        reminderTime: '18:00',
        classDays: [1, 2, 3],
        isEnabled: false,
      );
      expect(service.scheduledReminders, isEmpty);
    });

    test('requestFCMToken respects permission status', () async {
      service.setPermissionGranted(true);
      expect(await service.requestFCMToken(), isNotNull);

      service.setPermissionGranted(false);
      expect(await service.requestFCMToken(), isNull);
    });
  });
}
