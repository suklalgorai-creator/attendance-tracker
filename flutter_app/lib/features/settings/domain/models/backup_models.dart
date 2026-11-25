/// Summary of entities extracted during backup parsing.
class BackupSummary {
  final int subjectsCount;
  final int sessionsCount;
  final int attendanceRecordsCount;
  final int legacyRecordsCount;
  final int notesCount;
  final int quarantinedCount;

  const BackupSummary({
    this.subjectsCount = 0,
    this.sessionsCount = 0,
    this.attendanceRecordsCount = 0,
    this.legacyRecordsCount = 0,
    this.notesCount = 0,
    this.quarantinedCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupSummary &&
          subjectsCount == other.subjectsCount &&
          sessionsCount == other.sessionsCount &&
          attendanceRecordsCount == other.attendanceRecordsCount &&
          legacyRecordsCount == other.legacyRecordsCount &&
          notesCount == other.notesCount &&
          quarantinedCount == other.quarantinedCount;

  @override
  int get hashCode =>
      subjectsCount.hashCode ^
      sessionsCount.hashCode ^
      attendanceRecordsCount.hashCode ^
      legacyRecordsCount.hashCode ^
      notesCount.hashCode ^
      quarantinedCount.hashCode;
}

/// Result of parsing a backup file.
class BackupParseResult {
  final bool isValid;
  final String? error;
  final BackupSummary? summary;
  final Map<String, dynamic>? data;
  final List<String> warnings;

  const BackupParseResult({
    required this.isValid,
    this.error,
    this.summary,
    this.data,
    this.warnings = const [],
  });

  factory BackupParseResult.failure(String errorMessage) {
    return BackupParseResult(
      isValid: false,
      error: errorMessage,
      summary: null,
      data: null,
      warnings: const [],
    );
  }

  factory BackupParseResult.success({
    required Map<String, dynamic> data,
    required BackupSummary summary,
    List<String> warnings = const [],
  }) {
    return BackupParseResult(
      isValid: true,
      error: null,
      summary: summary,
      data: data,
      warnings: warnings,
    );
  }
}

/// Result of executing a backup restore operation.
class BackupRestoreResult {
  final bool ok;
  final String? error;
  final BackupSummary? summary;

  const BackupRestoreResult({required this.ok, this.error, this.summary});

  factory BackupRestoreResult.success([BackupSummary? summary]) =>
      BackupRestoreResult(ok: true, summary: summary);

  factory BackupRestoreResult.failure(String error) =>
      BackupRestoreResult(ok: false, error: error);
}
