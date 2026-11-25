import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../domain/entities/timetable_session_entity.dart';

// Re-export core repository and stream providers for convenience
export '../../../../core/providers/repository_providers.dart'
    show timetableRepositoryProvider, timetableStreamProvider;

/// Provider that calculates today's scheduled sessions from the weekly timetable.
final todaysScheduledSessionsProvider = Provider<List<TimetableSessionEntity>>((
  ref,
) {
  final timetableAsync = ref.watch(timetableStreamProvider);
  final timetable = timetableAsync.valueOrNull ?? const {};
  final todayDay = DateTime.now().weekday % 7; // 0 = Sun, 1 = Mon ... 6 = Sat
  final daySessions = timetable[todayDay] ?? const [];
  return daySessions.where((s) => !s.isDeleted).toList();
});

/// Provider returning scheduled sessions for today that have not yet been marked (present, absent, cancelled).
final unmarkedTodaySessionsProvider = Provider<List<TimetableSessionEntity>>((
  ref,
) {
  final todaySessions = ref.watch(todaysScheduledSessionsProvider);
  if (todaySessions.isEmpty) return const [];

  final recordsAsync = ref.watch(attendanceRecordsStreamProvider);
  final records = recordsAsync.valueOrNull ?? const [];
  final todayStr = AppDateUtils.todayStr();

  // Find records for today
  final todayRecordsBySession = <String, AttendanceStatus>{};
  for (final record in records) {
    if (record.date == todayStr && !record.isDeleted) {
      todayRecordsBySession[record.sessionId] = record.status;
    }
  }

  // Filter sessions that have no record or are marked UNMARKED
  return todaySessions.where((session) {
    final status = todayRecordsBySession[session.id];
    return status == null || status == AttendanceStatus.unmarked;
  }).toList();
});
