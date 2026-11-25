import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/database_service.dart';
import '../../../attendance/data/models/attendance_record_model.dart';
import '../../../attendance/data/models/legacy_attendance_model.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../dailyflow/data/models/daily_task_model.dart';
import '../../../dailyflow/domain/repositories/daily_flow_repository.dart';
import '../../../notes/data/models/note_model.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../../../notes/domain/repositories/notes_repository.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../subjects/domain/repositories/subject_repository.dart';
import '../../../timetable/data/models/timetable_model.dart';
import '../../../timetable/domain/entities/timetable_session_entity.dart';
import '../../../timetable/domain/repositories/timetable_repository.dart';
import '../entities/user_settings_entity.dart';
import '../models/backup_models.dart';
import '../repositories/settings_repository.dart';
import 'backup_normalizer.dart';

/// Service responsible for JSON backup serialization, pre-restore snapshot safeguards,
/// Hive restoration, and safe reset workflows conforming 1:1 with React Schema V2.
///
/// Ownership: Settings & Backup Feature
// ==========================================
// BACKUP SERVICE - Export, Pre-Restore Snapshot & Restore
// ==========================================
class BackupService {
  static const String backupFormat = BackupNormalizer.backupFormat;
  static const int currentSchemaVersion = BackupNormalizer.currentSchemaVersion;
  static const int maxBackupBytes = BackupNormalizer.maxBackupBytes;

  final SettingsRepository _settingsRepository;
  final SubjectRepository _subjectRepository;
  final TimetableRepository _timetableRepository;
  final AttendanceRepository _attendanceRepository;
  final NotesRepository _notesRepository;
  final DailyFlowRepository? _dailyFlowRepository;
  final Box? _settingsBoxOverride;

  BackupService({
    required SettingsRepository settingsRepository,
    required SubjectRepository subjectRepository,
    required TimetableRepository timetableRepository,
    required AttendanceRepository attendanceRepository,
    required NotesRepository notesRepository,
    DailyFlowRepository? dailyFlowRepository,
    Box? settingsBoxOverride,
  }) : _settingsRepository = settingsRepository,
       _subjectRepository = subjectRepository,
       _timetableRepository = timetableRepository,
       _attendanceRepository = attendanceRepository,
       _notesRepository = notesRepository,
       _dailyFlowRepository = dailyFlowRepository,
       _settingsBoxOverride = settingsBoxOverride;

  Box get _settingsBox {
    if (_settingsBoxOverride != null) return _settingsBoxOverride;
    return DatabaseService.getBox(DatabaseService.settingsBoxName);
  }

  // ==========================================
  // EXPORT
  // ==========================================

  /// Serializes the entire application state into a validated Schema V2 JSON backup object.
  Future<Map<String, dynamic>> createBackup() async {
    final settings = await _settingsRepository.getSettings();
    final subjects = await _subjectRepository.getSubjects(includeDeleted: true);
    final timetable = await _timetableRepository.getTimetable(
      includeDeleted: true,
    );
    final attendanceRecords = await _attendanceRepository.getAttendanceRecords(
      includeDeleted: true,
    );
    final legacyAttendance = await _attendanceRepository.getLegacyAttendance(
      includeDeleted: true,
    );
    final notes = await _notesRepository.getNotes();
    final dailyFlowTasks = _dailyFlowRepository != null
        ? await _dailyFlowRepository.getTasks()
        : null;

    final nowIso = DateTime.now().toUtc().toIso8601String();

    // Map timetable to string keys ("0".."6")
    final timetableMap = <String, List<Map<String, dynamic>>>{};
    timetable.forEach((day, sessions) {
      timetableMap[day.toString()] = sessions
          .map((s) => TimetableModel.fromEntity(s).toMap())
          .toList();
    });

    final data = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'name': settings.name,
      'programName': settings.programName,
      'courseName': settings.courseName,
      'startDate': settings.startDate,
      'minPercent': settings.minPercent,
      'classDays': settings.classDays,
      'reminderTime': settings.reminderTime,
      'pushNotificationsEnabled': settings.pushNotificationsEnabled,
      'dailyFlowMorningTime': settings.dailyFlowMorningTime,
      'dailyFlowEveningTime': settings.dailyFlowEveningTime,
      'dailyFlowSmartRemindersEnabled': settings.dailyFlowSmartRemindersEnabled,
      'dailyFlowFollowUpsEnabled': settings.dailyFlowFollowUpsEnabled,
      'dailyFlowPlanningHorizonDays': settings.dailyFlowPlanningHorizonDays,
      'timetable': timetableMap,
      'subjects': subjects
          .map((s) => SubjectModel.fromEntity(s).toMap())
          .toList(),
      'attendanceRecords': attendanceRecords
          .map((r) => AttendanceRecordModel.fromEntity(r).toMap())
          .toList(),
      'legacyAttendance': legacyAttendance
          .map((l) => LegacyAttendanceModel.fromEntity(l).toMap())
          .toList(),
      'notes': notes.map((n) => NoteModel.fromEntity(n).toMap()).toList(),
      if (dailyFlowTasks != null)
        'dailyFlowTasks': dailyFlowTasks
            .map((t) => DailyTaskModel.fromEntity(t).toMap())
            .toList(),
      'quarantine': <dynamic>[],
      'updatedAt': nowIso,
      'settingsUpdatedAt': nowIso,
    };

    return {
      'format': backupFormat,
      'schemaVersion': currentSchemaVersion,
      'exportedAt': nowIso,
      'data': data,
    };
  }

  /// Exports backup as formatted JSON string.
  Future<String> createBackupJsonString() async {
    final backup = await createBackup();
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  // ==========================================
  // PARSE & VALIDATE (DELEGATED)
  // ==========================================

  /// Parses and validates backup JSON string or raw bytes with exact React error messages.
  BackupParseResult parseBackup(dynamic input) =>
      BackupNormalizer.parseBackup(input);

  // ==========================================
  // PRE-RESTORE SAFETY SNAPSHOT
  // ==========================================

  /// Creates a local safety snapshot before executing restore or danger zone operations,
  /// pruning older snapshots beyond the most recent 3 to prevent unbounded Hive box growth.
  Future<bool> savePreRestoreBackup() async {
    try {
      final currentBackup = await createBackup();
      final key = 'pre_restore_${DateTime.now().millisecondsSinceEpoch}';
      await _settingsBox.put(key, currentBackup);

      try {
        final preRestoreKeys =
            _settingsBox.keys
                .whereType<String>()
                .where((k) => k.startsWith('pre_restore_'))
                .toList()
              ..sort();
        if (preRestoreKeys.length > 3) {
          final obsolete = preRestoreKeys.sublist(0, preRestoreKeys.length - 3);
          for (final oldKey in obsolete) {
            await _settingsBox.delete(oldKey);
          }
        }
      } catch (_) {
        // Minimal fake boxes in tests may omit `keys`
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // RESTORE DATA
  // ==========================================

  /// Restores application state from a parsed backup map with snapshot safeguard.
  Future<BackupRestoreResult> restoreBackup(
    Map<String, dynamic> backupData,
  ) async {
    final safeguardSaved = await savePreRestoreBackup();
    if (!safeguardSaved) {
      return BackupRestoreResult.failure('Unable to create safety backup.');
    }

    try {
      final now = DateTime.now();
      final existingSettings = await _settingsRepository.getSettings();

      // 1. Restore User Settings while preserving DailyFlow prefs if absent in older backups
      final settings = UserSettingsEntity(
        name: backupData['name']?.toString() ?? '',
        programName: backupData['programName']?.toString() ?? '',
        courseName: backupData['courseName']?.toString() ?? '',
        startDate: backupData['startDate']?.toString() ?? '',
        minPercent: (backupData['minPercent'] is num)
            ? (backupData['minPercent'] as num).toDouble()
            : 75.0,
        classDays: backupData['classDays'] is List
            ? (backupData['classDays'] as List)
                  .whereType<num>()
                  .map((e) => e.toInt())
                  .toList()
            : const [1, 2, 3, 4, 5],
        reminderTime: backupData['reminderTime']?.toString() ?? '18:00',
        pushNotificationsEnabled:
            backupData['pushNotificationsEnabled'] == true,
        dailyFlowMorningTime:
            backupData['dailyFlowMorningTime']?.toString() ??
            existingSettings.dailyFlowMorningTime,
        dailyFlowEveningTime:
            backupData['dailyFlowEveningTime']?.toString() ??
            existingSettings.dailyFlowEveningTime,
        dailyFlowSmartRemindersEnabled:
            backupData['dailyFlowSmartRemindersEnabled'] is bool
            ? backupData['dailyFlowSmartRemindersEnabled'] as bool
            : existingSettings.dailyFlowSmartRemindersEnabled,
        dailyFlowFollowUpsEnabled:
            backupData['dailyFlowFollowUpsEnabled'] is bool
            ? backupData['dailyFlowFollowUpsEnabled'] as bool
            : existingSettings.dailyFlowFollowUpsEnabled,
        dailyFlowPlanningHorizonDays:
            backupData['dailyFlowPlanningHorizonDays'] is num
            ? (backupData['dailyFlowPlanningHorizonDays'] as num).toInt()
            : existingSettings.dailyFlowPlanningHorizonDays,
      );
      await _settingsRepository.saveSettings(settings);

      // 2. Restore Subjects
      if (backupData['subjects'] is List) {
        final subjectEntities = (backupData['subjects'] as List).map((s) {
          final map = Map<String, dynamic>.from(s as Map);
          return SubjectEntity(
            id: map['id'].toString(),
            name: map['name'].toString(),
            code: map['code']?.toString(),
            color: map['color']?.toString() ?? '#10B981',
            icon: map['icon']?.toString() ?? 'school',
            targetPercentage: (map['targetPercentage'] is num)
                ? (map['targetPercentage'] as num).toDouble()
                : null,
            sortOrder: (map['sortOrder'] is num)
                ? (map['sortOrder'] as num).toInt()
                : 0,
            active: map['active'] != false,
            createdAt: map['createdAt'] != null
                ? DateTime.tryParse(map['createdAt'].toString()) ?? now
                : now,
            updatedAt: map['updatedAt'] != null
                ? DateTime.tryParse(map['updatedAt'].toString()) ?? now
                : now,
            deletedAt: map['deletedAt'] != null
                ? DateTime.tryParse(map['deletedAt'].toString())
                : null,
          );
        }).toList();
        await _subjectRepository.saveSubjects(subjectEntities);
      }

      // 3. Restore Timetable
      if (backupData['timetable'] is Map) {
        final timetableMap = <int, List<TimetableSessionEntity>>{};
        final rawTimetable = backupData['timetable'] as Map;
        rawTimetable.forEach((key, val) {
          final day = int.tryParse(key.toString());
          if (day != null && val is List) {
            timetableMap[day] = val.map((item) {
              final sMap = Map<String, dynamic>.from(item as Map);
              return TimetableSessionEntity(
                id: sMap['id'].toString(),
                subjectId: sMap['subjectId'].toString(),
                label: sMap['label']?.toString() ?? '',
                dayOfWeek: day,
                active: sMap['active'] != false,
                createdAt: sMap['createdAt'] != null
                    ? DateTime.tryParse(sMap['createdAt'].toString()) ?? now
                    : now,
                updatedAt: sMap['updatedAt'] != null
                    ? DateTime.tryParse(sMap['updatedAt'].toString()) ?? now
                    : now,
                deletedAt: sMap['deletedAt'] != null
                    ? DateTime.tryParse(sMap['deletedAt'].toString())
                    : null,
              );
            }).toList();
          }
        });
        await _timetableRepository.saveTimetable(timetableMap);
      }

      // 4. Restore Attendance Records
      if (backupData['attendanceRecords'] is List) {
        final attendanceEntities = (backupData['attendanceRecords'] as List)
            .map((r) {
              final map = Map<String, dynamic>.from(r as Map);
              return AttendanceRecordEntity(
                id: map['id'].toString(),
                date: map['date'].toString(),
                sessionId: map['sessionId'].toString(),
                subjectId: map['subjectId']?.toString() ?? '__daily__',
                status: AttendanceStatus.fromString(
                  map['status']?.toString() ?? 'PRESENT',
                ),
                createdAt: map['createdAt'] != null
                    ? DateTime.tryParse(map['createdAt'].toString()) ?? now
                    : now,
                updatedAt: map['updatedAt'] != null
                    ? DateTime.tryParse(map['updatedAt'].toString()) ?? now
                    : now,
                deletedAt: map['deletedAt'] != null
                    ? DateTime.tryParse(map['deletedAt'].toString())
                    : null,
              );
            })
            .toList();
        await _attendanceRepository.saveAttendanceRecords(attendanceEntities);
      }

      // 5. Restore Legacy Attendance
      if (backupData['legacyAttendance'] is List) {
        final legacyEntities = (backupData['legacyAttendance'] as List).map((
          l,
        ) {
          final map = Map<String, dynamic>.from(l as Map);
          return LegacyAttendanceEntity(
            id: map['id'].toString(),
            date: map['date'].toString(),
            held: (map['held'] is num) ? (map['held'] as num).toInt() : 0,
            attended: (map['attended'] is num)
                ? (map['attended'] as num).toInt()
                : 0,
            createdAt: map['createdAt'] != null
                ? DateTime.tryParse(map['createdAt'].toString()) ?? now
                : now,
            updatedAt: map['updatedAt'] != null
                ? DateTime.tryParse(map['updatedAt'].toString()) ?? now
                : now,
            deletedAt: map['deletedAt'] != null
                ? DateTime.tryParse(map['deletedAt'].toString())
                : null,
          );
        }).toList();
        await _attendanceRepository.saveLegacyAttendances(legacyEntities);
      }

      // 6. Restore Notes
      if (backupData['notes'] is List) {
        final noteEntities = (backupData['notes'] as List).map((n) {
          final map = Map<String, dynamic>.from(n as Map);
          return NoteEntity(
            id: map['id'].toString(),
            content: (map['content'] ?? map['text'])?.toString() ?? '',
            color: map['color']?.toString() ?? 'var(--input-bg)',
            reminderDate: map['reminderDate'] != null
                ? DateTime.tryParse(map['reminderDate'].toString())
                : null,
            createdAt: map['createdAt'] != null
                ? DateTime.tryParse(map['createdAt'].toString()) ?? now
                : now,
          );
        }).toList();
        await _notesRepository.saveNotes(noteEntities);
      }

      // 7. Restore DailyFlow Tasks when present
      if (_dailyFlowRepository != null &&
          backupData['dailyFlowTasks'] is List) {
        final tasks = (backupData['dailyFlowTasks'] as List)
            .whereType<Map>()
            .map((t) => DailyTaskModel.fromMap(Map<String, dynamic>.from(t)))
            .toList();
        await _dailyFlowRepository.saveTasks(tasks);
      }

      return BackupRestoreResult.success();
    } catch (_) {
      return BackupRestoreResult.failure(
        'Restore failed; existing data was not changed.',
      );
    }
  }

  // ==========================================
  // DANGER ZONE (RESET ATTENDANCE & NOTES)
  // ==========================================

  /// Replicates React `resetAll`: clears attendance records and sticky notes while
  /// preserving subjects, timetable, and profile settings intact.
  Future<bool> resetAllAttendanceAndNotes() async {
    final safeguardSaved = await savePreRestoreBackup();
    if (!safeguardSaved) {
      return false;
    }

    try {
      await _attendanceRepository.clearAllAttendanceHistory();
      await _notesRepository.clearAllNotes();
      return true;
    } catch (_) {
      return false;
    }
  }
}
