part of 'data_migration.dart';

/// Entity normalization, quarantine handling, and V1 -> V2 schema migration.
///
/// Ownership: Core Data Migration
// ==========================================
// DATA MIGRATION - Primitive Normalization & Quarantine
// ==========================================

String _nowIso() => DateTime.now().toUtc().toIso8601String();

String _createId(String prefix) {
  final rand = Random().nextInt(1000000);
  return '$prefix-${DateTime.now().millisecondsSinceEpoch}-$rand';
}

String _stableLegacyId(String prefix, String value) {
  int hash = 5381;
  for (int i = 0; i < value.length; i++) {
    hash = (((hash * 33) ^ value.codeUnitAt(i)) & 0xFFFFFFFF);
  }
  return '$prefix-${hash.toRadixString(36)}';
}

bool _isObject(dynamic value) => value is Map;

String _safeString(dynamic value, [String fallback = '']) {
  if (value is String) return value.trim();
  return fallback;
}

String _validTimestamp(dynamic value, String fallback) {
  if (value is String && DateTime.tryParse(value) != null) return value;
  return fallback;
}

int? _integer(dynamic value) {
  if (value is int) return value;
  if (value is num && value.toInt() == value) return value.toInt();
  return null;
}

String _safeSerialized(dynamic value) {
  try {
    final s = jsonEncode(value);
    return s.length > 1500 ? s.substring(0, 1500) : s;
  } catch (_) {
    return '[unserializable value]';
  }
}

Map<String, dynamic> _quarantineItem(
  String kind,
  dynamic value,
  String reason,
  String receivedAt,
) {
  return {
    'id': _createId('quarantine'),
    'kind': kind,
    'reason': reason,
    'record': _safeSerialized(value),
    'receivedAt': receivedAt,
  };
}

// ==========================================
// DATA MIGRATION - Entity Normalizers
// ==========================================

Map<String, dynamic>? _normalizeSubject(dynamic value, String receivedAt) {
  if (!_isObject(value)) return null;
  final m = value as Map;
  final id = _safeString(m['id']);
  final name = _safeString(m['name']);
  if (id.isEmpty || name.isEmpty) return null;

  final color = _safeString(m['color'], '#10B981');
  return {
    'id': id,
    'name': name.length > 120 ? name.substring(0, 120) : name,
    'color': color.length > 32 ? color.substring(0, 32) : color,
    'active': m['active'] != false,
    'createdAt': _validTimestamp(m['createdAt'], receivedAt),
    'updatedAt': _validTimestamp(m['updatedAt'], receivedAt),
    'deletedAt': m['deletedAt'] != null
        ? _validTimestamp(m['deletedAt'], receivedAt)
        : null,
  };
}

Map<String, dynamic>? _normalizeSession(
  dynamic value,
  Set<String> subjectIds,
  String receivedAt,
) {
  if (!_isObject(value)) return null;
  final m = value as Map;
  final id = _safeString(m['id']);
  final subjectId = m['subjectId']?.toString();
  if (id.isEmpty || subjectId == null || !subjectIds.contains(subjectId)) {
    return null;
  }

  final label = _safeString(m['label']);
  return {
    'id': id,
    'subjectId': subjectId,
    'label': label.length > 120 ? label.substring(0, 120) : label,
    'active': m['active'] != false,
    'createdAt': _validTimestamp(m['createdAt'], receivedAt),
    'updatedAt': _validTimestamp(m['updatedAt'], receivedAt),
    'deletedAt': m['deletedAt'] != null
        ? _validTimestamp(m['deletedAt'], receivedAt)
        : null,
  };
}

Map<String, dynamic> _normalizeAttendanceRecord(
  dynamic value,
  Set<String> subjectIds,
  String receivedAt,
) {
  if (!_isObject(value)) return {'error': 'Record must be an object.'};
  final m = value as Map;
  final id = _safeString(m['id']);
  if (id.isEmpty) return {'error': 'Record is missing a stable id.'};

  final dateStr = m['date']?.toString();
  if (!AppDateUtils.isDateOnly(dateStr)) {
    return {'error': 'Record has an invalid date.'};
  }

  final rawSubId = _safeString(m['subjectId']);
  final subjectId = rawSubId.isNotEmpty ? rawSubId : dailySubjectId;
  if (subjectId != dailySubjectId && !subjectIds.contains(subjectId)) {
    return {'error': 'Record references an unknown subject.'};
  }

  final sessionId = _safeString(m['sessionId']);
  if (sessionId.isEmpty) return {'error': 'Record is missing a session id.'};

  final status = m['status']?.toString();
  const validStatuses = {'PRESENT', 'ABSENT', 'UNMARKED', 'CANCELLED'};
  if (status == null || !validStatuses.contains(status)) {
    return {'error': 'Record has an invalid attendance status.'};
  }

  return {
    'value': {
      'id': id,
      'date': dateStr!,
      'subjectId': subjectId,
      'sessionId': sessionId,
      'status': status,
      'createdAt': _validTimestamp(m['createdAt'], receivedAt),
      'updatedAt': _validTimestamp(m['updatedAt'], receivedAt),
      'deletedAt': m['deletedAt'] != null
          ? _validTimestamp(m['deletedAt'], receivedAt)
          : null,
      'source': m['source'] == 'manual' ? 'manual' : 'schedule',
    },
  };
}

Map<String, dynamic>? _normalizeLegacyRecord(dynamic value, String receivedAt) {
  if (!_isObject(value)) return null;
  final m = value as Map;
  final id = _safeString(m['id']);
  final dateStr = m['date']?.toString();
  if (id.isEmpty || !AppDateUtils.isDateOnly(dateStr)) return null;

  final held = _integer(m['held']);
  final attended = _integer(m['attended']);
  if (held == null ||
      attended == null ||
      held < 0 ||
      attended < 0 ||
      attended > held) {
    return null;
  }

  final note = _safeString(m['note']);
  return {
    'id': id,
    'date': dateStr!,
    'held': held,
    'attended': attended,
    'createdAt': _validTimestamp(m['createdAt'], receivedAt),
    'updatedAt': _validTimestamp(m['updatedAt'], receivedAt),
    'deletedAt': m['deletedAt'] != null
        ? _validTimestamp(m['deletedAt'], receivedAt)
        : null,
    'note': note.length > 240 ? note.substring(0, 240) : note,
  };
}

List<Map<String, dynamic>> _uniqueById(
  List<Map<String, dynamic>> values,
  String kind,
  List<Map<String, dynamic>> quarantine,
  String receivedAt,
) {
  final byId = <String, Map<String, dynamic>>{};
  for (final value in values) {
    final id = value['id']?.toString() ?? '';
    final existing = byId[id];
    if (existing == null) {
      byId[id] = value;
    } else {
      final existingUpdated = existing['updatedAt']?.toString() ?? '';
      final valueUpdated = value['updatedAt']?.toString() ?? '';
      if (existingUpdated.compareTo(valueUpdated) < 0) {
        quarantine.add(
          _quarantineItem(
            kind,
            existing,
            'Superseded duplicate id.',
            receivedAt,
          ),
        );
        byId[id] = value;
      } else {
        quarantine.add(
          _quarantineItem(
            kind,
            value,
            'Duplicate id retained as quarantine.',
            receivedAt,
          ),
        );
      }
    }
  }
  return byId.values.toList();
}

// ==========================================
// DATA MIGRATION - V1 Legacy Upgrade Helpers
// ==========================================

List<Map<String, dynamic>> _makeLegacyRecords(
  dynamic records,
  String receivedAt,
  List<Map<String, dynamic>> quarantine,
) {
  if (!_isObject(records)) return [];
  final m = records as Map;
  final result = <Map<String, dynamic>>[];
  m.forEach((date, record) {
    final dateStr = date.toString();
    if (!AppDateUtils.isDateOnly(dateStr) || !_isObject(record)) {
      quarantine.add(
        _quarantineItem(
          'legacy-record',
          {'date': date, 'record': record},
          'Invalid legacy daily record.',
          receivedAt,
        ),
      );
      return;
    }
    final rec = record as Map;
    final held = _integer(rec['held']);
    final attended = _integer(rec['attended']);
    if (held == null ||
        attended == null ||
        held < 0 ||
        attended < 0 ||
        attended > held) {
      quarantine.add(
        _quarantineItem(
          'legacy-record',
          {'date': date, 'record': record},
          'Invalid legacy attendance totals.',
          receivedAt,
        ),
      );
      return;
    }
    result.add({
      'id': 'legacy-$dateStr',
      'date': dateStr,
      'held': held,
      'attended': attended,
      'createdAt': receivedAt,
      'updatedAt': receivedAt,
      'deletedAt': null,
      'note':
          'Migrated from the v1 daily aggregate. Subject/session detail was not available.',
    });
  });
  return result;
}

Map<String, List<Map<String, dynamic>>> _migrateLegacyTimetable(
  dynamic timetable,
  List<Map<String, dynamic>> subjects,
  String receivedAt,
) {
  final subjectByName = <String, Map<String, dynamic>>{};
  for (final s in subjects) {
    subjectByName[s['name'].toString().toLowerCase()] = s;
  }
  final result = <String, List<Map<String, dynamic>>>{};
  if (!_isObject(timetable)) return result;

  final m = timetable as Map;
  m.forEach((dayKey, values) {
    final dayStr = dayKey.toString();
    if (!RegExp(r'^[0-6]$').hasMatch(dayStr) || values is! List) return;
    final sessions = <Map<String, dynamic>>[];
    for (int index = 0; index < values.length; index++) {
      final value = values[index];
      if (_isObject(value)) {
        sessions.add(Map<String, dynamic>.from(value as Map));
        continue;
      }
      final name = _safeString(value);
      if (name.isEmpty) continue;
      var subject = subjectByName[name.toLowerCase()];
      if (subject == null) {
        final subId = _stableLegacyId('legacy-subject', name.toLowerCase());
        subject = {
          'id': subId,
          'name': name.length > 120 ? name.substring(0, 120) : name,
          'color': '#10B981',
          'active': true,
          'createdAt': receivedAt,
          'updatedAt': receivedAt,
          'deletedAt': null,
        };
        subjects.add(subject);
        subjectByName[name.toLowerCase()] = subject;
      }
      sessions.add({
        'id': _stableLegacyId(
          'legacy-schedule',
          '$dayStr:$index:${subject['id']}',
        ),
        'subjectId': subject['id'],
        'label': name.length > 120 ? name.substring(0, 120) : name,
        'active': true,
        'createdAt': receivedAt,
        'updatedAt': receivedAt,
        'deletedAt': null,
      });
    }
    result[dayStr] = sessions;
  });
  return result;
}

// ==========================================
// DATA MIGRATION - Entry Point (migrateUserData)
// ==========================================

/// Migrates persisted v1/v2 data into a validated v2 model conforming 1:1 with React.
UserMigrationResult migrateUserData(dynamic rawData) {
  final raw = _isObject(rawData)
      ? Map<String, dynamic>.from(rawData as Map)
      : <String, dynamic>{};
  final receivedAt = raw['schemaVersion'] == currentSchemaVersion
      ? _nowIso()
      : _validTimestamp(raw['updatedAt'], '2000-01-01T00:00:00.000Z');

  final quarantine = <Map<String, dynamic>>[];
  if (raw['quarantine'] is List) {
    for (final q in raw['quarantine'] as List) {
      if (_isObject(q)) quarantine.add(Map<String, dynamic>.from(q as Map));
    }
  }

  final warnings = <String>[];
  final sourceSubjects = raw['subjects'] is List
      ? (raw['subjects'] as List)
      : [];
  final normalizedSubjectList = <Map<String, dynamic>>[];
  for (final value in sourceSubjects) {
    final norm = _normalizeSubject(value, receivedAt);
    if (norm == null) {
      quarantine.add(
        _quarantineItem('subject', value, 'Invalid subject.', receivedAt),
      );
    } else {
      normalizedSubjectList.add(norm);
    }
  }
  final subjects = _uniqueById(
    normalizedSubjectList,
    'subject',
    quarantine,
    receivedAt,
  );

  final timetableSource = raw['timetable'] ?? {};
  final legacyTimetable = raw['schemaVersion'] == currentSchemaVersion
      ? (timetableSource is Map ? timetableSource : {})
      : _migrateLegacyTimetable(timetableSource, subjects, receivedAt);

  final subjectIds = subjects.map((s) => s['id']?.toString() ?? '').toSet();
  final timetable = <String, List<Map<String, dynamic>>>{};
  legacyTimetable.forEach((dayKey, values) {
    final dayStr = dayKey.toString();
    if (!RegExp(r'^[0-6]$').hasMatch(dayStr) || values is! List) return;
    final sessionList = <Map<String, dynamic>>[];
    for (final value in values) {
      final norm = _normalizeSession(value, subjectIds, receivedAt);
      if (norm == null) {
        quarantine.add(
          _quarantineItem(
            'schedule-session',
            value,
            'Invalid timetable session.',
            receivedAt,
          ),
        );
      } else {
        sessionList.add(norm);
      }
    }
    timetable[dayStr] = _uniqueById(
      sessionList,
      'schedule-session',
      quarantine,
      receivedAt,
    );
  });

  final rawRecords = raw['attendanceRecords'] is List
      ? (raw['attendanceRecords'] as List)
      : [];
  final normalizedRecordList = <Map<String, dynamic>>[];
  for (final value in rawRecords) {
    final norm = _normalizeAttendanceRecord(value, subjectIds, receivedAt);
    if (norm.containsKey('error')) {
      quarantine.add(
        _quarantineItem(
          'attendance-record',
          value,
          norm['error'] as String,
          receivedAt,
        ),
      );
    } else {
      normalizedRecordList.add(norm['value'] as Map<String, dynamic>);
    }
  }
  final attendanceRecords = _uniqueById(
    normalizedRecordList,
    'attendance-record',
    quarantine,
    receivedAt,
  );

  final sourceLegacy = raw['legacyAttendance'] is List
      ? (raw['legacyAttendance'] as List)
      : _makeLegacyRecords(raw['records'], receivedAt, quarantine);
  final normalizedLegacyList = <Map<String, dynamic>>[];
  for (final value in sourceLegacy) {
    final norm = _normalizeLegacyRecord(value, receivedAt);
    if (norm == null) {
      quarantine.add(
        _quarantineItem(
          'legacy-record',
          value,
          'Invalid legacy aggregate.',
          receivedAt,
        ),
      );
    } else {
      normalizedLegacyList.add(norm);
    }
  }
  final legacyAttendance = _uniqueById(
    normalizedLegacyList,
    'legacy-record',
    quarantine,
    receivedAt,
  );

  final minPercentNum = raw['minPercent'] is num
      ? (raw['minPercent'] as num).toDouble()
      : double.tryParse(raw['minPercent']?.toString() ?? '');
  final normalizedMin =
      (minPercentNum != null && minPercentNum > 0 && minPercentNum <= 100)
      ? minPercentNum
      : 75.0;
  if (minPercentNum != null && normalizedMin != minPercentNum) {
    warnings.add('Invalid attendance threshold was reset to the default.');
  }

  final classDays = raw['classDays'] is List
      ? ((raw['classDays'] as List)
            .whereType<num>()
            .map((n) => n.toInt())
            .where((d) => d >= 0 && d <= 6)
            .toSet()
            .toList()
          ..sort())
      : [1, 2, 3, 4, 5];

  final effectiveClassDays = classDays.isNotEmpty ? classDays : [1, 2, 3, 4, 5];

  final timetableRaw = <String, dynamic>{};
  timetable.forEach((k, v) {
    timetableRaw[k] = v;
  });

  final notes = raw['notes'] is List
      ? (raw['notes'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
      : <Map<String, dynamic>>[];

  final finalDataMap = <String, dynamic>{
    'schemaVersion': currentSchemaVersion,
    'programName': _safeString(raw['programName']),
    'courseName': _safeString(raw['courseName']),
    'name': _safeString(raw['name']),
    'startDate': AppDateUtils.isDateOnly(raw['startDate']?.toString())
        ? raw['startDate'].toString()
        : '',
    'minPercent': normalizedMin,
    'classDays': effectiveClassDays,
    'timetable': timetableRaw,
    'subjects': subjects,
    'attendanceRecords': attendanceRecords,
    'legacyAttendance': legacyAttendance,
    'quarantine': quarantine.length > 100
        ? quarantine.sublist(quarantine.length - 100)
        : quarantine,
    'notes': notes.length > 500 ? notes.sublist(notes.length - 500) : notes,
    'theme': raw['theme'] == 'light' ? 'light' : 'dark',
    'reminderTime':
        RegExp(r'^\d{2}:\d{2}$').hasMatch(raw['reminderTime']?.toString() ?? '')
        ? raw['reminderTime'].toString()
        : '18:00',
    'pushNotificationsEnabled': raw['pushNotificationsEnabled'] == true,
    'leaderboardOptIn': true,
    'fcmToken': raw['fcmToken'] is String ? raw['fcmToken'] : null,
    'adminRequestedPush': raw['adminRequestedPush'] == true,
    'lastNotified': AppDateUtils.isDateOnly(raw['lastNotified']?.toString())
        ? raw['lastNotified'].toString()
        : null,
    'settingsUpdatedAt': _validTimestamp(raw['settingsUpdatedAt'], receivedAt),
    'updatedAt': _validTimestamp(raw['updatedAt'], receivedAt),
  };

  final dataModel = UserDataModel(
    raw: finalDataMap,
    subjects: subjects.map((s) => UserDataSubject(s)).toList(),
    attendanceRecords: attendanceRecords
        .map((r) => UserDataAttendanceRecord(r))
        .toList(),
    legacyAttendance: legacyAttendance,
    timetable: timetable,
    quarantine: finalDataMap['quarantine'] as List<Map<String, dynamic>>,
    notes: notes,
    minPercent: normalizedMin,
    classDays: effectiveClassDays,
  );

  final migrated =
      raw['schemaVersion'] != currentSchemaVersion || raw['records'] != null;
  if (migrated) {
    warnings.insert(
      0,
      'Your existing daily totals were preserved as legacy history. They cannot be split by subject because v1 did not store that information.',
    );
  }

  return UserMigrationResult(
    data: dataModel,
    warnings: warnings,
    migrated: migrated,
    quarantineCount: dataModel.quarantine.length,
  );
}
