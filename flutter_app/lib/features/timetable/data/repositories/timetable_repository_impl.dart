import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/database_service.dart';
import '../../../subjects/domain/repositories/subject_repository.dart';
import '../../domain/entities/timetable_session_entity.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../models/timetable_model.dart';

/// Hive-backed implementation of [TimetableRepository], storing the weekly timetable
/// in `settings_box['timetable']` for Schema Version 2 parity.
class TimetableRepositoryImpl implements TimetableRepository {
  final Box? _boxOverride;
  final SubjectRepository? _subjectRepository;

  TimetableRepositoryImpl({
    Box? box,
    SubjectRepository? subjectRepository,
  })  : _boxOverride = box,
        _subjectRepository = subjectRepository;

  Box get _box {
    if (_boxOverride != null) return _boxOverride;
    return DatabaseService.getBox(DatabaseService.settingsBoxName);
  }

  @override
  Future<Map<int, List<TimetableSessionEntity>>> getTimetable({
    bool includeDeleted = false,
  }) async {
    try {
      final raw = _box.get('timetable');
      final Map<dynamic, dynamic>? rawMap;
      if (raw is Map) {
        rawMap = raw;
      } else {
        rawMap = null;
      }

      final parsed = TimetableModel.timetableFromMap(rawMap);
      final result = <int, List<TimetableSessionEntity>>{};
      parsed.forEach((day, sessions) {
        if (includeDeleted) {
          result[day] = List<TimetableSessionEntity>.from(sessions);
        } else {
          result[day] = sessions.where((s) => !s.isDeleted).toList();
        }
      });
      return result;
    } catch (e) {
      throw CacheException('Failed to get timetable: $e');
    }
  }

  @override
  Stream<Map<int, List<TimetableSessionEntity>>> watchTimetable({
    bool includeDeleted = false,
  }) async* {
    yield await getTimetable(includeDeleted: includeDeleted);
    yield* _box.watch(key: 'timetable').asyncMap((_) => getTimetable(includeDeleted: includeDeleted));
  }

  @override
  Future<void> addSession(int dayOfWeek, String subjectId, {String? label}) async {
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      return; // Invalid day index
    }

    try {
      String resolvedLabel = label ?? '';
      if (resolvedLabel.isEmpty && _subjectRepository != null) {
        final subject = await _subjectRepository.getSubjectById(subjectId);
        if (subject != null) {
          resolvedLabel = subject.name;
        }
      }
      if (resolvedLabel.isEmpty) {
        resolvedLabel = 'Unknown subject';
      }

      final now = DateTime.now();
      final newSession = TimetableModel(
        id: 'schedule-${now.microsecondsSinceEpoch}',
        subjectId: subjectId,
        label: resolvedLabel,
        dayOfWeek: dayOfWeek,
        active: true,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      );

      final current = await getTimetable(includeDeleted: true);
      final daySessions = List<TimetableSessionEntity>.from(current[dayOfWeek] ?? []);
      daySessions.add(newSession);
      current[dayOfWeek] = daySessions;

      await _box.put('timetable', TimetableModel.timetableToMap(current));
    } catch (e) {
      throw CacheException('Failed to add timetable session: $e');
    }
  }

  @override
  Future<void> removeSession(int dayOfWeek, String sessionId) async {
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      return;
    }

    try {
      final current = await getTimetable(includeDeleted: true);
      final daySessions = current[dayOfWeek];
      if (daySessions == null || daySessions.isEmpty) {
        return;
      }

      final now = DateTime.now();
      bool modified = false;

      final updatedSessions = daySessions.map((session) {
        if (session.id == sessionId) {
          modified = true;
          return session.copyWith(
            active: false,
            deletedAt: now,
            updatedAt: now,
          );
        }
        return session;
      }).toList();

      if (modified) {
        current[dayOfWeek] = updatedSessions;
        await _box.put('timetable', TimetableModel.timetableToMap(current));
      }
    } catch (e) {
      throw CacheException('Failed to remove timetable session: $e');
    }
  }

  @override
  Future<void> clearTimetable() async {
    try {
      await _box.delete('timetable');
    } catch (e) {
      throw CacheException('Failed to clear timetable: $e');
    }
  }

  @override
  Future<void> saveTimetable(Map<int, List<TimetableSessionEntity>> timetable) async {
    try {
      await _box.put('timetable', TimetableModel.timetableToMap(timetable));
    } catch (e) {
      throw CacheException('Failed to save timetable: $e');
    }
  }
}
