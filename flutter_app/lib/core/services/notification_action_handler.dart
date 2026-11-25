import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/attendance/data/datasources/attendance_local_datasource.dart';
import '../../features/attendance/data/models/legacy_attendance_model.dart';
import '../utils/date_utils.dart';
import 'database_service.dart';

/// Quick-action notification handler for foreground and background isolates.
///
/// Ownership: Core Notifications
// ==========================================
// NOTIFICATIONS - Attendance Quick Actions
// Handles Present / Absent action button taps directly from system tray notifications.
// ==========================================

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

/// Top-level background isolate entrypoint registered with `flutter_local_notifications`.
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
