part of 'data_migration.dart';

/// Deterministic local/cloud merge and Schema V2 JSON backup envelope creation/validation.
///
/// Ownership: Core Data Migration & Cloud Sync
// ==========================================
// DATA MIGRATION - Cloud/Local Deterministic Merge
// Uses timestamp precedence with deterministic structural tie-breaking.
// ==========================================

int _timestampOf(dynamic value) {
  if (value == null) return 0;
  String? timeStr;
  if (value is Map) {
    timeStr = value['updatedAt']?.toString() ?? value['deletedAt']?.toString();
  } else if (value is UserDataAttendanceRecord) {
    timeStr = value.updatedAt ?? value.deletedAt;
  } else if (value is UserDataSubject) {
    timeStr = value.updatedAt ?? value.deletedAt;
  } else {
    try {
      timeStr =
          (value as dynamic).updatedAt?.toString() ??
          (value as dynamic).deletedAt?.toString();
    } catch (_) {}
  }
  if (timeStr == null || timeStr.isEmpty) return 0;
  final dt = DateTime.tryParse(timeStr);
  return dt?.millisecondsSinceEpoch ?? 0;
}

String _stableValue(dynamic value) {
  if (value is List) {
    final sorted = value.map(_stableValue).toList()..sort();
    return '[${sorted.join(',')}]';
  }
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return '{${keys.map((k) => '${jsonEncode(k)}:${_stableValue(value[k])}').join(',')}}';
  }
  return jsonEncode(value);
}

List<Map<String, dynamic>> _mergeEntities(
  List<dynamic> localList,
  List<dynamic> cloudList,
) {
  final merged = <String, Map<String, dynamic>>{};
  for (final entity in [...cloudList, ...localList]) {
    if (entity == null) continue;
    final map = entity is Map
        ? Map<String, dynamic>.from(entity)
        : (entity is UserDataAttendanceRecord
              ? entity.toMap()
              : (entity is UserDataSubject
                    ? entity.toMap()
                    : <String, dynamic>{}));
    final id = map['id']?.toString() ?? '';
    if (id.isEmpty) continue;

    final current = merged[id];
    if (current == null) {
      merged[id] = map;
      continue;
    }

    final incomingTime = _timestampOf(map);
    final currentTime = _timestampOf(current);
    if (incomingTime > currentTime ||
        (incomingTime == currentTime &&
            _stableValue(map).compareTo(_stableValue(current)) > 0)) {
      merged[id] = map;
    }
  }
  return merged.values.toList();
}

/// Merges local and cloud user data entity-by-entity; tombstones are preserved.
UserDataModel mergeUserData(dynamic localRaw, dynamic cloudRaw) {
  final local = migrateUserData(localRaw).data;
  final cloud = migrateUserData(cloudRaw).data;
  final settings = _timestampOf(local.raw) >= _timestampOf(cloud.raw)
      ? local.raw
      : cloud.raw;

  final merged = Map<String, dynamic>.from(settings);
  merged['subjects'] = _mergeEntities(
    local.subjects.map((s) => s.toMap()).toList(),
    cloud.subjects.map((s) => s.toMap()).toList(),
  );
  merged['attendanceRecords'] = _mergeEntities(
    local.attendanceRecords.map((r) => r.toMap()).toList(),
    cloud.attendanceRecords.map((r) => r.toMap()).toList(),
  );
  merged['legacyAttendance'] = _mergeEntities(
    local.legacyAttendance,
    cloud.legacyAttendance,
  );
  merged['quarantine'] = _mergeEntities(local.quarantine, cloud.quarantine);
  merged['notes'] = _mergeEntities(local.notes, cloud.notes);

  final localTimetable = local.timetable;
  final cloudTimetable = cloud.timetable;
  final allDays = {...localTimetable.keys, ...cloudTimetable.keys};
  final mergedTimetable = <String, dynamic>{};
  for (final day in allDays) {
    mergedTimetable[day] = _mergeEntities(
      localTimetable[day] ?? [],
      cloudTimetable[day] ?? [],
    );
  }
  merged['timetable'] = mergedTimetable;

  return migrateUserData(merged).data;
}

// ==========================================
// DATA MIGRATION - Backup Envelope Export & Parse
// ==========================================

const String backupFormat = 'college-attendance-tracker-backup';
const int maxBackupBytes = 5 * 1024 * 1024;

/// Creates a JSON backup envelope matching React `createBackup`.
Map<String, dynamic> createBackup(dynamic data) {
  return {
    'format': backupFormat,
    'schemaVersion': currentSchemaVersion,
    'exportedAt': _nowIso(),
    'data': migrateUserData(data).data.toMap(),
  };
}

/// Parses and validates JSON backup string conforming 1:1 with React `parseBackup`.
ParsedBackup parseBackup(String text) {
  final byteLength = utf8.encode(text).length;
  if (text.isEmpty || byteLength > maxBackupBytes) {
    throw Exception('Backup file is empty or exceeds the 5 MB safety limit.');
  }

  dynamic parsed;
  try {
    parsed = jsonDecode(text);
  } catch (_) {
    throw Exception(
      'This file is not valid JSON. Existing data was not changed.',
    );
  }

  if (parsed is! Map ||
      parsed['format'] != backupFormat ||
      parsed['data'] == null) {
    throw Exception(
      'This is not a College Attendance Tracker backup. Existing data was not changed.',
    );
  }

  final schemaVersion = (parsed['schemaVersion'] is num)
      ? (parsed['schemaVersion'] as num).toInt()
      : int.tryParse(parsed['schemaVersion']?.toString() ?? '1') ?? 1;

  if (schemaVersion > currentSchemaVersion) {
    throw Exception(
      'This backup is from a newer app version and cannot be restored safely.',
    );
  }

  final migration = migrateUserData(parsed['data']);
  final activeSessionsCount = migration.data.timetable.values
      .expand((sessions) => sessions)
      .where((s) => s['deletedAt'] == null)
      .length;
  final activeAttendanceRecords = migration.data.attendanceRecords
      .where((r) => r.deletedAt == null)
      .length;
  final activeLegacyRecords = migration.data.legacyAttendance
      .where((r) => r['deletedAt'] == null)
      .length;

  return ParsedBackup(
    data: migration.data,
    summary: ParsedBackupSummary(
      subjects: migration.data.subjects.length,
      sessions: activeSessionsCount,
      attendanceRecords: activeAttendanceRecords,
      legacyRecords: activeLegacyRecords,
      quarantined: migration.quarantineCount,
    ),
    warnings: migration.warnings,
  );
}
