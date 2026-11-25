/// Deterministic ID allocation, time math, and message copy helpers for notifications.
///
/// Ownership: Core Notifications
library;

// ==========================================
// NOTIFICATIONS - ID Hashing & Copy Helpers
// Non-overlapping ID ranges:
//   - Attendance weekday reminders: 1000..1006
//   - DailyFlow routine reminders: 40001..40003
//   - Sticky Note reminders: 100000..199999
//   - DailyFlow task reminders: 200000..299999
//   - DailyFlow follow-ups: 300000..399999
// ==========================================

/// Deterministic 31-bit FNV-1a hash so notification IDs remain identical
/// across isolates, restarts, and platforms (unlike `String.hashCode`).
int stableNotificationHash(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

int noteReminderNotificationId(String noteId) =>
    100000 + (stableNotificationHash(noteId) % 100000);

int taskReminderNotificationId(String taskId) =>
    200000 + (stableNotificationHash(taskId) % 100000);

int followUpReminderNotificationId(String taskId) =>
    300000 + (stableNotificationHash(taskId) % 100000);

/// Builds the 07:00 DailyFlow morning briefing notification copy.
String buildMorningBriefingBody({
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

// ==========================================
// NOTIFICATIONS - Schedule Time Parsing
// ==========================================

/// Parses an `HH:mm` clock string into clamped `[hour, minute]`, falling back to `18:00`.
List<int> parseNotificationTime(String timeStr) {
  if (!timeStr.contains(':')) return [18, 0];
  final parts = timeStr.split(':');
  final h = int.tryParse(parts[0]) ?? 18;
  final m = int.tryParse(parts[1]) ?? 0;
  return [h.clamp(0, 23), m.clamp(0, 59)];
}

/// Computes the next future local [DateTime] matching [targetDayOfWeek] (`0` = Sun .. `6` = Sat).
DateTime calculateNextNotificationOccurrence({
  required DateTime now,
  required int targetDayOfWeek,
  required int hour,
  required int minute,
}) {
  for (int i = 0; i < 7; i++) {
    final candidate = DateTime(now.year, now.month, now.day + i, hour, minute);
    final candidateDayOfWeek = candidate.weekday % 7;
    if (candidateDayOfWeek == targetDayOfWeek && candidate.isAfter(now)) {
      return candidate;
    }
  }
  return DateTime(now.year, now.month, now.day + 7, hour, minute);
}
