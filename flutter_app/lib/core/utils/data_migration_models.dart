part of 'data_migration.dart';

/// Value models and dynamic map wrappers used by V1/V2 schema migration and backup parsing.
///
/// Ownership: Core Data Migration
// ==========================================
// DATA MIGRATION - Schema Constants & Models
// ==========================================

abstract final class AttendanceStatusConstants {
  static const String present = 'PRESENT';
  static const String absent = 'ABSENT';
  static const String unmarked = 'UNMARKED';
  static const String cancelled = 'CANCELLED';
}

/// Dynamic record wrapper supporting property dot-notation and map-indexing.
class UserDataAttendanceRecord {
  final Map<String, dynamic> raw;

  UserDataAttendanceRecord(this.raw);

  String get id => raw['id']?.toString() ?? '';
  String get date => raw['date']?.toString() ?? '';
  String get subjectId => raw['subjectId']?.toString() ?? dailySubjectId;
  String get sessionId => raw['sessionId']?.toString() ?? '';
  String get status =>
      raw['status']?.toString() ?? AttendanceStatusConstants.unmarked;
  String? get createdAt => raw['createdAt']?.toString();
  String? get updatedAt => raw['updatedAt']?.toString();
  String? get deletedAt => raw['deletedAt']?.toString();
  String get source => raw['source']?.toString() ?? 'schedule';

  dynamic operator [](String key) => raw[key];
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(raw);

  @override
  String toString() => raw.toString();
}

/// Dynamic subject wrapper supporting property dot-notation and map-indexing.
class UserDataSubject {
  final Map<String, dynamic> raw;

  UserDataSubject(this.raw);

  String get id => raw['id']?.toString() ?? '';
  String get name => raw['name']?.toString() ?? '';
  String get color => raw['color']?.toString() ?? '#10B981';
  bool get active => raw['active'] != false;
  String? get createdAt => raw['createdAt']?.toString();
  String? get updatedAt => raw['updatedAt']?.toString();
  String? get deletedAt => raw['deletedAt']?.toString();

  dynamic operator [](String key) => raw[key];
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(raw);

  @override
  String toString() => raw.toString();
}

/// Complete migrated user data model matching React V2 schema.
class UserDataModel {
  final Map<String, dynamic> raw;
  final List<UserDataSubject> subjects;
  final List<UserDataAttendanceRecord> attendanceRecords;
  final List<Map<String, dynamic>> legacyAttendance;
  final Map<String, List<Map<String, dynamic>>> timetable;
  final List<Map<String, dynamic>> quarantine;
  final List<Map<String, dynamic>> notes;
  final double minPercent;
  final List<int> classDays;

  UserDataModel({
    required this.raw,
    required this.subjects,
    required this.attendanceRecords,
    required this.legacyAttendance,
    required this.timetable,
    required this.quarantine,
    required this.notes,
    required this.minPercent,
    required this.classDays,
  });

  dynamic operator [](String key) => raw[key];
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(raw);

  @override
  String toString() => raw.toString();
}

/// Result returned by [migrateUserData] including warnings and quarantined counts.
class UserMigrationResult {
  final UserDataModel data;
  final List<String> warnings;
  final bool migrated;
  final int quarantineCount;

  const UserMigrationResult({
    required this.data,
    required this.warnings,
    required this.migrated,
    required this.quarantineCount,
  });
}

/// Entity summary counts extracted from a validated backup archive.
class ParsedBackupSummary {
  final int subjects;
  final int sessions;
  final int attendanceRecords;
  final int legacyRecords;
  final int quarantined;

  const ParsedBackupSummary({
    required this.subjects,
    required this.sessions,
    required this.attendanceRecords,
    required this.legacyRecords,
    required this.quarantined,
  });
}

/// Validated archive payload and summary returned by [parseBackup].
class ParsedBackup {
  final UserDataModel data;
  final ParsedBackupSummary summary;
  final List<String> warnings;

  const ParsedBackup({
    required this.data,
    required this.summary,
    required this.warnings,
  });
}
