import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';

/// Platform file sharing and picker I/O helpers backing [SettingsController]
/// export (JSON/CSV) and restore workflows.
///
/// Ownership: Settings & Backup Feature
// ==========================================
// SETTINGS - Export & Import File I/O
// ==========================================
class SettingsBackupIo {
  /// Builds sorted RFC-4180 CSV content for attendance records + legacy rows.
  /// Returns `null` when there are no active records to export.
  static String? buildAttendanceCsv({
    required List<AttendanceRecordEntity> attendance,
    required List<LegacyAttendanceEntity> legacy,
  }) {
    final rows = <List<String>>[
      for (final record in attendance.where((item) => !item.isDeleted))
        [record.date, record.subjectId, record.sessionId, record.status.value],
      for (final record in legacy.where((item) => !item.isDeleted))
        [record.date, 'legacy', record.id, '${record.attended}/${record.held}'],
    ]..sort((a, b) => a.first.compareTo(b.first));

    if (rows.isEmpty) return null;

    String quote(String value) => '"${value.replaceAll('"', '""')}"';
    final csv = StringBuffer('Date,Subject ID,Session ID,Status\n');
    for (final row in rows) {
      csv.writeln(row.map(quote).join(','));
    }
    return csv.toString();
  }

  /// Shares serialized text + binary attachment through the system share sheet.
  static Future<void> shareTextFile({
    required String content,
    required String subject,
    required String filename,
    required String mimeType,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        text: content,
        subject: subject,
        files: [
          XFile.fromData(
            utf8.encode(content),
            mimeType: mimeType,
            name: filename,
          ),
        ],
      ),
    );
  }

  /// Prompts the user for a `.json` backup archive and returns its bytes, or `null` on cancel.
  static Future<Uint8List?> pickJsonBackupBytes() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
