import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/core/utils/date_utils.dart';
import 'package:flutter_app/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:flutter_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:flutter_app/features/attendance/data/models/legacy_attendance_model.dart';

class _MemoryAttendanceLocalDataSource implements AttendanceLocalDataSource {
  final Map<String, LegacyAttendanceModel> legacy = {};

  @override
  Future<LegacyAttendanceModel?> getLegacyRecordById(String id) async =>
      legacy[id];

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceModel record) async {
    legacy[record.id] = record;
  }

  @override
  Future<List<AttendanceRecordModel>> getAttendanceRecords() async => [];
  @override
  Stream<List<AttendanceRecordModel>> watchAttendanceRecords() =>
      const Stream.empty();
  @override
  Future<AttendanceRecordModel?> getRecordById(String id) async => null;
  @override
  Future<void> saveAttendanceRecord(AttendanceRecordModel record) async {}
  @override
  Future<void> saveAttendanceRecords(
    List<AttendanceRecordModel> records,
  ) async {}
  @override
  Future<void> deleteAttendanceRecord(String id) async {}
  @override
  Future<List<LegacyAttendanceModel>> getLegacyAttendance() async =>
      legacy.values.toList();
  @override
  Stream<List<LegacyAttendanceModel>> watchLegacyAttendance() =>
      const Stream.empty();
  @override
  Future<void> saveLegacyAttendances(
    List<LegacyAttendanceModel> records,
  ) async {}
  @override
  Future<void> deleteLegacyAttendance(String id) async {}
  @override
  Future<void> clearAllAttendanceHistory() async => legacy.clear();
}

void main() {
  group('NotificationService Unit Tests', () {
    late DefaultNotificationService service;

    setUp(() {
      service = DefaultNotificationService();
    });

    test('parseTime handles valid HH:mm and invalid fallback', () {
      expect(DefaultNotificationService.parseTime('18:30'), equals([18, 30]));
      expect(DefaultNotificationService.parseTime('08:05'), equals([8, 5]));
      expect(DefaultNotificationService.parseTime('25:70'), equals([23, 59]));
      expect(DefaultNotificationService.parseTime('invalid'), equals([18, 0]));
    });

    test('calculateNextOccurrence finds correct future day and time', () {
      // Wednesday Nov 25, 2026, 10:00
      final now = DateTime(2026, 11, 25, 10, 0);

      // Target Thursday (weekday 4 -> targetDayOfWeek 4) at 18:00
      final nextDay = DefaultNotificationService.calculateNextOccurrence(
        now: now,
        targetDayOfWeek: 4,
        hour: 18,
        minute: 0,
      );

      expect(nextDay.year, 2026);
      expect(nextDay.month, 11);
      expect(nextDay.day, 26);
      expect(nextDay.hour, 18);
      expect(nextDay.minute, 0);
    });

    test(
      'scheduleAttendanceReminder schedules for all classDays when enabled',
      () async {
        await service.scheduleAttendanceReminder(
          reminderTime: '17:00',
          classDays: [1, 2, 3, 4, 5], // Mon to Fri
          isEnabled: true,
        );

        expect(service.scheduledReminders.length, 5);
        expect(
          service.scheduledReminders.map((r) => r.id).toList(),
          equals([1001, 1002, 1003, 1004, 1005]),
        );
      },
    );

    test(
      'scheduleAttendanceReminder cancels all when isEnabled is false or classDays empty',
      () async {
        await service.scheduleAttendanceReminder(
          reminderTime: '17:00',
          classDays: [1, 2, 3],
          isEnabled: true,
        );
        expect(service.scheduledReminders.length, 3);

        await service.scheduleAttendanceReminder(
          reminderTime: '17:00',
          classDays: [1, 2, 3],
          isEnabled: false,
        );
        expect(service.scheduledReminders.length, 0);

        await service.scheduleAttendanceReminder(
          reminderTime: '17:00',
          classDays: [],
          isEnabled: true,
        );
        expect(service.scheduledReminders.length, 0);
      },
    );

    test('scheduleAttendanceReminder skips declared holidays', () async {
      final now = DateTime.now();
      // Calculate what date next Monday (1) will be
      final mondayDate = DefaultNotificationService.calculateNextOccurrence(
        now: now,
        targetDayOfWeek: 1,
        hour: 18,
        minute: 0,
      );
      final mondayDateKey = formatDateKey(mondayDate);

      final holidays = {mondayDateKey: 'Diwali Holiday'};

      await service.scheduleAttendanceReminder(
        reminderTime: '18:00',
        classDays: [1, 2], // Mon, Tue
        isEnabled: true,
        holidays: holidays,
      );

      // Monday should be skipped, so only Tuesday is scheduled
      expect(service.scheduledReminders.length, 1);
      expect(service.scheduledReminders.first.id, 1002);
    });

    test(
      'requestNotificationPermissions and requestFCMToken reflect permission state',
      () async {
        expect(await service.requestNotificationPermissions(), isTrue);
        expect(await service.requestFCMToken(), isNotNull);

        service.setPermissionGranted(false);
        expect(await service.requestNotificationPermissions(), isFalse);
        expect(await service.requestFCMToken(), isNull);
      },
    );

    test(
      'scheduleNoteReminder and cancelNoteReminder manage future note reminders',
      () async {
        final futureDate = DateTime.now().add(const Duration(hours: 2));
        await service.scheduleNoteReminder(
          noteId: 'note-123',
          content: 'Submit OS assignment',
          reminderDate: futureDate,
        );
        expect(service.scheduledReminders.length, 1);
        expect(
          service.scheduledReminders.first.title,
          'Sticky Note Reminder 📝',
        );

        await service.cancelNoteReminder('note-123');
        expect(service.scheduledReminders, isEmpty);
      },
    );

    test('scheduleNoteReminder ignores past reminder dates', () async {
      final pastDate = DateTime.now().subtract(const Duration(hours: 1));
      await service.scheduleNoteReminder(
        noteId: 'note-past',
        content: 'Old reminder',
        reminderDate: pastDate,
      );
      expect(service.scheduledReminders, isEmpty);
    });

    test(
      'handleAttendanceNotificationAction saves Present and Absent from action buttons',
      () async {
        final localDs = _MemoryAttendanceLocalDataSource();

        final handledPresent = await handleAttendanceNotificationAction(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: attendanceActionPresent,
            payload: 'attendance_reminder:2026-11-25',
          ),
          localDataSource: localDs,
        );

        expect(handledPresent, isTrue);
        final savedPresent = localDs.legacy['daily-2026-11-25'];
        expect(savedPresent, isNotNull);
        expect(savedPresent!.held, 1);
        expect(savedPresent.attended, 1);

        final handledAbsent = await handleAttendanceNotificationAction(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: attendanceActionAbsent,
            payload: 'attendance_reminder:2026-11-25',
          ),
          localDataSource: localDs,
        );

        expect(handledAbsent, isTrue);
        final savedAbsent = localDs.legacy['daily-2026-11-25'];
        expect(savedAbsent!.held, 1);
        expect(savedAbsent.attended, 0);
      },
    );

    test(
      'suppresses today reminder when isTodayMarked is true and preserves note/task reminders',
      () async {
        final now = DateTime(2026, 11, 25, 10, 0); // Wednesday (dayOfWeek = 3)
        await service.scheduleTaskReminder(
          taskId: 'df_keep',
          title: 'Keep me',
          body: 'Do not cancel',
          reminderAt: DateTime.now().add(const Duration(hours: 3)),
        );

        await service.scheduleAttendanceReminder(
          reminderTime: '18:00',
          classDays: [3, 4], // Wed, Thu
          isEnabled: true,
          isTodayMarked: true,
          nowOverride: now,
        );

        // Task reminder preserved + 2 attendance reminders (no duplicates)
        final wedReminder = service.scheduledReminders.firstWhere(
          (r) => r.id == 1003,
        );
        final thuReminder = service.scheduledReminders.firstWhere(
          (r) => r.id == 1004,
        );
        expect(wedReminder.scheduledTime, DateTime(2026, 12, 2, 18, 0));
        expect(thuReminder.scheduledTime, DateTime(2026, 11, 26, 18, 0));
        expect(
          service.scheduledReminders.any(
            (r) => r.id == DefaultNotificationService.defaultTaskNotificationId('df_keep'),
          ),
          isTrue,
        );
      },
    );

    test(
      'schedules and cancels DailyFlow routine and pending follow-up notifications',
      () async {
        await service.scheduleDailyFlowRoutineReminders(
          isEnabled: true,
          todayTaskCount: 5,
          pendingCarryoverCount: 0,
        );
        expect(
          service.scheduledReminders.map((r) => r.id),
          containsAll([40001, 40002, 40003]),
        );

        final morning = service.scheduledReminders.firstWhere(
          (r) => r.id == 40001,
        );
        expect(morning.scheduledTime.hour, 7);
        expect(morning.scheduledTime.minute, 0);
        expect(
          morning.body,
          'Good morning! Your DailyFlow plan is ready. You have 5 tasks planned today.',
        );

        final evening = service.scheduledReminders.firstWhere(
          (r) => r.id == 40002,
        );
        expect(evening.scheduledTime.hour, 22);
        expect(evening.scheduledTime.minute, 0);
        expect(
          evening.body,
          'Your day is almost over. Take a moment to review your tasks and prepare tomorrow.',
        );

        final followUpAt = DateTime.now().add(const Duration(hours: 2));
        await service.schedulePendingTaskFollowUp(
          taskId: 'df_99',
          title: 'DBMS Lab',
          followUpAt: followUpAt,
        );
        expect(
          service.scheduledReminders.any(
            (r) =>
                r.id ==
                DefaultNotificationService.defaultFollowUpNotificationId('df_99'),
          ),
          isTrue,
        );

        await service.cancelPendingTaskFollowUp('df_99');
        expect(
          service.scheduledReminders.any(
            (r) =>
                r.id ==
                DefaultNotificationService.defaultFollowUpNotificationId('df_99'),
          ),
          isFalse,
        );

        await service.scheduleDailyFlowRoutineReminders(isEnabled: false);
        expect(
          service.scheduledReminders.where((r) => r.id >= 40001 && r.id <= 40003),
          isEmpty,
        );
      },
    );
  });
}
