import 'dart:convert';
import 'dart:typed_data';

import '../models/backup_models.dart';

/// Pure payload validation and V1/V2 schema normalization helpers for [BackupService].
///
/// Kept free of Hive/repository dependencies so archive parsing and legacy
/// schema migration remain deterministic and independently testable.
///
/// Ownership: Settings & Backup Feature
// ==========================================
// BACKUP - Payload Validation & Schema Normalizer
// ==========================================
class BackupNormalizer {
  static const String backupFormat = 'college-attendance-tracker-backup';
  static const int currentSchemaVersion = 2;
  static const int maxBackupBytes = 5 * 1024 * 1024; // 5 MB

  /// Parses and validates raw JSON text or [Uint8List] bytes with React-parity errors.
  static BackupParseResult parseBackup(dynamic input) {
    if (input == null) {
      return BackupParseResult.failure(
        'Backup file is empty or exceeds the 5 MB safety limit.',
      );
    }

    final String jsonText;
    final int byteLength;

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

    final normalized = normalizeBackupData(Map<String, dynamic>.from(rawData));
    return BackupParseResult.success(
      data: normalized['data'] as Map<String, dynamic>,
      summary: normalized['summary'] as BackupSummary,
      warnings: List<String>.from(normalized['warnings'] as List),
    );
  }

  /// Normalizes both V1 and V2 backup snapshots into canonical V2 maps + summary.
  static Map<String, dynamic> normalizeBackupData(Map<String, dynamic> raw) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final warnings = <String>[];
    final quarantine = <dynamic>[];

    // Subjects
    final subjectIds = <String>{};
    final subjects = <Map<String, dynamic>>[];
    if (raw['subjects'] is List) {
      for (final s in raw['subjects'] as List) {
        if (s is Map && s['id'] != null && s['name'] != null) {
          subjectIds.add(s['id'].toString());
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
      (raw['timetable'] as Map).forEach((key, val) {
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
              final name = item.trim();
              final existingSub = subjects.firstWhere(
                (sub) =>
                    sub['name']?.toString().toLowerCase() == name.toLowerCase(),
                orElse: () => {},
              );
              final String subId;
              if (existingSub.isNotEmpty) {
                subId = existingSub['id'].toString();
              } else {
                subId =
                    'legacy-subject-${name.toLowerCase().hashCode.toRadixString(36)}';
                subjects.add({
                  'id': subId,
                  'name': name.length > 120 ? name.substring(0, 120) : name,
                  'color': '#10B981',
                  'active': true,
                  'createdAt': nowIso,
                  'updatedAt': nowIso,
                  'deletedAt': null,
                });
                subjectIds.add(subId);
              }
              daySessions.add({
                'id': 'legacy-schedule-$dayStr:$idx:$subId',
                'subjectId': subId,
                'label': name.length > 120 ? name.substring(0, 120) : name,
                'active': true,
                'createdAt': nowIso,
                'updatedAt': nowIso,
                'deletedAt': null,
              });
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

    // V1 daily aggregates migration (`records: { "YYYY-MM-DD": { held, attended } }`)
    if (raw['records'] is Map) {
      (raw['records'] as Map).forEach((dateKey, val) {
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
            legacyAttendance.add({
              'id': 'legacy-$dateKey',
              'date': dateKey.toString(),
              'held': held,
              'attended': attended,
              'createdAt': nowIso,
              'updatedAt': nowIso,
              'deletedAt': null,
              'note':
                  'Migrated from the v1 daily aggregate. Subject/session detail was not available.',
            });
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
}
