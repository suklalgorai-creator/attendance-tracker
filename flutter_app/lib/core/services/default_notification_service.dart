import '../utils/date_utils.dart';
import 'notification_service.dart';

/// Headless / in-memory implementation of [NotificationService] used in unit/widget tests
/// and offline simulation without touching platform channels.
///
/// Ownership: Core Notifications
// ==========================================
// NOTIFICATIONS - Default Headless Implementation
// Captures scheduled reminders in memory for deterministic verification.
// ==========================================

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
  Future<bool> requestNotificationPermissions() async => _permissionGranted;

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
    _scheduledReminders.add(
      ScheduledNotificationInfo(
        id: noteReminderNotificationId(noteId),
        scheduledTime: reminderDate,
        title: 'Sticky Note Reminder 📝',
        body: content.length > 100 ? content.substring(0, 100) : content,
      ),
    );
  }

  @override
  Future<void> cancelNoteReminder(String noteId) async {
    final id = noteReminderNotificationId(noteId);
    _scheduledReminders.removeWhere((r) => r.id == id);
  }

  static int defaultTaskNotificationId(String taskId) =>
      taskReminderNotificationId(taskId);

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
      followUpReminderNotificationId(taskId);

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
    final morningBody = buildMorningBriefingBody(
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
    if (!isEnabled || classDays.isEmpty) return;

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
        // Suppress today's reminder when already marked and shift to next week.
        scheduledDate = scheduledDate.add(const Duration(days: 7));
        dateKey = formatDateKey(scheduledDate);
      }

      if (holidays.containsKey(dateKey)) continue;

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

  static List<int> parseTime(String timeStr) => parseNotificationTime(timeStr);

  static DateTime calculateNextOccurrence({
    required DateTime now,
    required int targetDayOfWeek,
    required int hour,
    required int minute,
  }) => calculateNextNotificationOccurrence(
    now: now,
    targetDayOfWeek: targetDayOfWeek,
    hour: hour,
    minute: minute,
  );
}
