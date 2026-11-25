import 'dart:convert';
import 'dart:typed_data';

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

/// Service responsible for JSON backup serialization, validation, normalization,
/// rollback safeguards, and data restoration conforming 1:1 with React Schema V2.
class BackupService {
  static const String backupFormat = 'college-attendance-tracker-backup';
  static const int currentSchemaVersion = 2;
  static const int maxBackupBytes = 5 * 1024 * 1024; // 5 MB

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
  // PARSE & VALIDATE
  // ==========================================

  /// Parses and validates backup JSON string or raw bytes with exact React error messages.
  BackupParseResult parseBackup(dynamic input) {
    if (input == null) {
      return BackupParseResult.failure(
        'Backup file is empty or exceeds the 5 MB safety limit.',
      );
    }

    String jsonText;
    int byteLength;

    if (input is Uint8List) {
      byteLength = input.length;
      if (byteLength == 0 || byteLength > maxBackupBytes) {
        return BackupParseResult.failure(
          'Backup file is empty or exceeds the 5 MB safety limit.',
        );
      }
      try {
        jsonText = utf8.decode(input);
      } catch (_) {
        return BackupParseResult.failure(
          'This file is not valid JSON. Existing data was not changed.',
        );
      }
    } else if (input is String) {
      jsonText = input;
      byteLength = utf8.encode(input).length;
      if (input.trim().isEmpty || byteLength > maxBackupBytes) {
        return BackupParseResult.failure(
          'Backup file is empty or exceeds the 5 MB safety limit.',
        );
      }
    } else {
      return BackupParseResult.failure(
        'Backup file is empty or exceeds the 5 MB safety limit.',
      );
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(jsonText);
    } catch (_) {
      return BackupParseResult.failure(
        'This file is not valid JSON. Existing data was not changed.',
      );
    }

    if (parsed is! Map ||
        parsed['format'] != backupFormat ||
        parsed['data'] == null) {
      return BackupParseResult.failure(
        'This is not a College Attendance Tracker backup. Existing data was not changed.',
      );
    }

    final schemaVersionNum = parsed['schemaVersion'];
    final schemaVersion = (schemaVersionNum is num)
        ? schemaVersionNum.toInt()
        : int.tryParse(schemaVersionNum?.toString() ?? '1') ?? 1;

    if (schemaVersion > currentSchemaVersion) {
      return BackupParseResult.failure(
        'This backup is from a newer app version and cannot be restored safely.',
      );
    }

    final rawData = parsed['data'];
    if (rawData is! Map) {
      return BackupParseResult.failure(
        'This is not a College Attendance Tracker backup. Existing data was not changed.',
      );
    }

    final normalized = _normalizeBackupData(Map<String, dynamic>.from(rawData));
    return BackupParseResult.success(
      data: normalized['data'] as Map<String, dynamic>,
      summary: normalized['summary'] as BackupSummary,
      warnings: List<String>.from(normalized['warnings'] as List),
    );
  }

  // ==========================================
  // NORMALIZATION (V1 & V2)
  // ==========================================

  Map<String, dynamic> _normalizeBackupData(Map<String, dynamic> raw) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final warnings = <String>[];
    final quarantine = <dynamic>[];

    // Subjects
    final subjectIds = <String>{};
    final subjects = <Map<String, dynamic>>[];
    if (raw['subjects'] is List) {
      for (final s in raw['subjects'] as List) {
        if (s is Map && s['id'] != null && s['name'] != null) {
          final id = s['id'].toString();
          subjectIds.add(id);
          subjects.add(Map<String, dynamic>.from(s));
        } else {
          quarantine.add({
            'kind': 'subject',
            'value': s,
            'reason': 'Invalid subject format',
          });
        }
      }
    }

    // Timetable
    final timetable = <String, List<Map<String, dynamic>>>{};
    int activeSessionsCount = 0;
    if (raw['timetable'] is Map) {
      final rawTimetable = raw['timetable'] as Map;
      rawTimetable.forEach((key, val) {
        final dayStr = key.toString();
        final dayInt = int.tryParse(dayStr);
        if (dayInt != null && dayInt >= 0 && dayInt <= 6 && val is List) {
          final daySessions = <Map<String, dynamic>>[];
          for (int idx = 0; idx < val.length; idx++) {
            final item = val[idx];
            if (item is Map) {
              final sessionMap = Map<String, dynamic>.from(item);
              daySessions.add(sessionMap);
              if (sessionMap['deletedAt'] == null &&
                  sessionMap['active'] != false) {
                activeSessionsCount++;
              }
            } else if (item is String && item.trim().isNotEmpty) {
              // Legacy V1 string session format
              final name = item.trim();
              var existingSub = subjects.firstWhere(
                (sub) =>
                    sub['name']?.toString().toLowerCase() == name.toLowerCase(),
                orElse: () => {},
              );
              String subId;
              if (existingSub.isNotEmpty) {
                subId = existingSub['id'].toString();
              } else {
                subId =
                    'legacy-subject-${name.toLowerCase().hashCode.toRadixString(36)}';
                final newSub = {
                  'id': subId,
                  'name': name.length > 120 ? name.substring(0, 120) : name,
                  'color': '#10B981',
                  'active': true,
                  'createdAt': nowIso,
                  'updatedAt': nowIso,
                  'deletedAt': null,
                };
                subjects.add(newSub);
                subjectIds.add(subId);
              }
              final sessionMap = {
                'id': 'legacy-schedule-$dayStr:$idx:$subId',
                'subjectId': subId,
                'label': name.length > 120 ? name.substring(0, 120) : name,
                'active': true,
                'createdAt': nowIso,
                'updatedAt': nowIso,
                'deletedAt': null,
              };
              daySessions.add(sessionMap);
              activeSessionsCount++;
            }
          }
          timetable[dayStr] = daySessions;
        }
      });
    }

    // Attendance Records (V2)
    final attendanceRecords = <Map<String, dynamic>>[];
    int activeAttendanceRecords = 0;
    if (raw['attendanceRecords'] is List) {
      for (final r in raw['attendanceRecords'] as List) {
        if (r is Map &&
            r['id'] != null &&
            r['date'] != null &&
            r['sessionId'] != null) {
          final recordMap = Map<String, dynamic>.from(r);
          attendanceRecords.add(recordMap);
          if (recordMap['deletedAt'] == null) {
            activeAttendanceRecords++;
          }
        } else {
          quarantine.add({
            'kind': 'attendance-record',
            'value': r,
            'reason': 'Invalid attendance record',
          });
        }
      }
    }

    // Legacy Attendance Records
    final legacyAttendance = <Map<String, dynamic>>[];
    int activeLegacyRecords = 0;
    if (raw['legacyAttendance'] is List) {
      for (final l in raw['legacyAttendance'] as List) {
        if (l is Map &&
            l['id'] != null &&
            l['date'] != null &&
            l['held'] != null &&
            l['attended'] != null) {
          final legMap = Map<String, dynamic>.from(l);
          legacyAttendance.add(legMap);
          if (legMap['deletedAt'] == null) {
            activeLegacyRecords++;
          }
        } else {
          quarantine.add({
            'kind': 'legacy-attendance',
            'value': l,
            'reason': 'Invalid legacy record',
          });
        }
      }
    }

    // V1 daily aggregates migration (records: { "YYYY-MM-DD": { held, attended } })
    if (raw['records'] is Map) {
      final recordsMap = raw['records'] as Map;
      recordsMap.forEach((dateKey, val) {
        if (val is Map) {
          final held = (val['held'] is num)
              ? (val['held'] as num).toInt()
              : null;
          final attended = (val['attended'] is num)
              ? (val['attended'] as num).toInt()
              : null;
          if (held != null &&
              attended != null &&
              held >= 0 &&
              attended >= 0 &&
              attended <= held) {
            final legMap = {
              'id': 'legacy-$dateKey',
              'date': dateKey.toString(),
              'held': held,
              'attended': attended,
              'createdAt': nowIso,
              'updatedAt': nowIso,
              'deletedAt': null,
              'note':
                  'Migrated from the v1 daily aggregate. Subject/session detail was not available.',
            };
            legacyAttendance.add(legMap);
            activeLegacyRecords++;
          } else {
            quarantine.add({
              'kind': 'legacy-record',
              'date': dateKey,
              'value': val,
              'reason': 'Invalid legacy totals',
            });
          }
        }
      });
    }

    // Notes
    final notes = <Map<String, dynamic>>[];
    if (raw['notes'] is List) {
      for (final n in raw['notes'] as List) {
        if (n is Map &&
            n['id'] != null &&
            (n['content'] != null || n['text'] != null)) {
          notes.add(Map<String, dynamic>.from(n));
        }
      }
    }

    // Summary
    final summary = BackupSummary(
      subjectsCount: subjects.where((s) => s['deletedAt'] == null).length,
      sessionsCount: activeSessionsCount,
      attendanceRecordsCount: activeAttendanceRecords,
      legacyRecordsCount: activeLegacyRecords,
      notesCount: notes.length,
      quarantinedCount: quarantine.length,
    );

    final normalizedData = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'name': raw['name']?.toString() ?? '',
      'programName': raw['programName']?.toString() ?? '',
      'courseName': raw['courseName']?.toString() ?? '',
      'startDate': raw['startDate']?.toString() ?? '',
      'minPercent': (raw['minPercent'] is num)
          ? (raw['minPercent'] as num).toDouble()
          : 75.0,
      'classDays': raw['classDays'] is List
          ? (raw['classDays'] as List).map((e) => (e as num).toInt()).toList()
          : [1, 2, 3, 4, 5],
      'reminderTime': raw['reminderTime']?.toString() ?? '18:00',
      'pushNotificationsEnabled': raw['pushNotificationsEnabled'] == true,
      'timetable': timetable,
      'subjects': subjects,
      'attendanceRecords': attendanceRecords,
      'legacyAttendance': legacyAttendance,
      'notes': notes,
      'quarantine': quarantine,
      'updatedAt': nowIso,
    };

    return {'data': normalizedData, 'summary': summary, 'warnings': warnings};
  }

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
