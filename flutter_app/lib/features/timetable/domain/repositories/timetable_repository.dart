import '../entities/timetable_session_entity.dart';

/// Repository interface for Timetable persistence and streaming.
abstract class TimetableRepository {
  /// Fetches the weekly timetable mapped by day of the week (0 = Sun .. 6 = Sat).
  /// If [includeDeleted] is false, only active non-deleted sessions are returned.
  Future<Map<int, List<TimetableSessionEntity>>> getTimetable({
    bool includeDeleted = false,
  });

  /// Streams updates to the weekly timetable.
  Stream<Map<int, List<TimetableSessionEntity>>> watchTimetable({
    bool includeDeleted = false,
  });

  /// Adds a recurring session on [dayOfWeek] for subject with [subjectId].
  /// Optionally accepts a cached [label]; if null, resolves the subject's name.
  Future<void> addSession(int dayOfWeek, String subjectId, {String? label});

  /// Soft deletes a session identified by [sessionId] from [dayOfWeek].
  Future<void> removeSession(int dayOfWeek, String sessionId);

  /// Clears all timetable sessions across all days.
  Future<void> clearTimetable();

  /// Persists a complete weekly timetable mapping. Used for backup restore.
  Future<void> saveTimetable(Map<int, List<TimetableSessionEntity>> timetable);
}
