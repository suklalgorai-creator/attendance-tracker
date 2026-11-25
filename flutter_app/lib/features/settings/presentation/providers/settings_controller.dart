import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/models/backup_models.dart';
import '../../domain/services/backup_service.dart';

/// State of the settings management controller.
class SettingsState {
  final bool isLoading;
  final BackupParseResult? pendingRestore;
  final String? backupError;
  final String? successMessage;

  const SettingsState({
    this.isLoading = false,
    this.pendingRestore,
    this.backupError,
    this.successMessage,
  });

  SettingsState copyWith({
    bool? isLoading,
    BackupParseResult? pendingRestore,
    bool clearPendingRestore = false,
    String? backupError,
    bool clearBackupError = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      pendingRestore: clearPendingRestore
          ? null
          : (pendingRestore ?? this.pendingRestore),
      backupError: clearBackupError ? null : (backupError ?? this.backupError),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

/// Provider for [BackupService].
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    settingsRepository: ref.watch(settingsRepositoryProvider),
    subjectRepository: ref.watch(subjectRepositoryProvider),
    timetableRepository: ref.watch(timetableRepositoryProvider),
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
    notesRepository: ref.watch(notesRepositoryProvider),
  );
});

/// Riverpod StateNotifier controlling settings modifications, backup import/export,
/// and safe data restoration.
class SettingsController extends StateNotifier<SettingsState> {
  final Ref _ref;
  final BackupService _backupService;

  SettingsController(this._ref, this._backupService)
    : super(const SettingsState());

  /// Title-cases a string on focus loss matching React `toTitleCase`.
  static String toTitleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              word[0].toUpperCase() +
              (word.length > 1 ? word.substring(1) : ''),
        )
        .join(' ');
  }

  /// Updates settings partially while preserving unspecified properties.
  Future<void> updateSettings(
    UserSettingsEntity Function(UserSettingsEntity current) updateFn,
  ) async {
    final settingsRepo = _ref.read(settingsRepositoryProvider);
    final current = await settingsRepo.getSettings();
    final updated = updateFn(current);
    await settingsRepo.saveSettings(updated);
  }

  Future<void> updateDailyFlowPreferences({
    String? morningTime,
    String? eveningTime,
    bool? smartRemindersEnabled,
    bool? followUpsEnabled,
    int? planningHorizonDays,
  }) async {
    await updateSettings(
      (current) => current.copyWith(
        dailyFlowMorningTime: morningTime,
        dailyFlowEveningTime: eveningTime,
        dailyFlowSmartRemindersEnabled: smartRemindersEnabled,
        dailyFlowFollowUpsEnabled: followUpsEnabled,
        dailyFlowPlanningHorizonDays: planningHorizonDays,
      ),
    );
  }

  Future<void> updateName(String name) async {
    await updateSettings((c) => c.copyWith(name: name.trim()));
  }

  Future<void> updateProgramName(String programName) async {
    await updateSettings((c) => c.copyWith(programName: programName.trim()));
  }

  Future<void> updateCourseName(String courseName) async {
    await updateSettings((c) => c.copyWith(courseName: courseName.trim()));
  }

  Future<void> updateStartDate(String startDate) async {
    await updateSettings((c) => c.copyWith(startDate: startDate.trim()));
  }

  Future<void> updateMinPercent(double minPercent) async {
    final clamped = minPercent.clamp(1.0, 100.0);
    await updateSettings((c) => c.copyWith(minPercent: clamped));
  }

  Future<void> updateClassDays(List<int> classDays) async {
    final days = classDays.isNotEmpty ? classDays : const [1, 2, 3, 4, 5];
    await updateSettings((c) => c.copyWith(classDays: days));
  }

  Future<void> updateReminderTime(String reminderTime) async {
    await updateSettings((c) => c.copyWith(reminderTime: reminderTime.trim()));
  }

  Future<void> togglePushNotifications() async {
    await updateSettings(
      (c) => c.copyWith(pushNotificationsEnabled: !c.pushNotificationsEnabled),
    );
  }

  // ==========================================
  // BACKUP EXPORT & IMPORT
  // ==========================================

  /// Exports Schema V2 JSON backup and triggers platform sharing.
  Future<void> exportBackup() async {
    state = state.copyWith(isLoading: true, clearBackupError: true);
    try {
      final jsonStr = await _backupService.createBackupJsonString();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final filename = 'attendance-backup-$todayStr.json';

      await SharePlus.instance.share(
        ShareParams(
          text: jsonStr,
          subject: 'College Attendance Tracker Backup',
          files: [
            XFile.fromData(
              utf8.encode(jsonStr),
              mimeType: 'application/json',
              name: filename,
            ),
          ],
        ),
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        backupError: 'Unable to export backup: $e',
      );
    }
  }

  /// Exports the same compact CSV shape as the React desktop/drawer action.
  Future<void> exportCsv() async {
    state = state.copyWith(isLoading: true, clearBackupError: true);
    try {
      final attendance = await _ref
          .read(attendanceRepositoryProvider)
          .getAttendanceRecords();
      final legacy = await _ref
          .read(attendanceRepositoryProvider)
          .getLegacyAttendance();
      final rows = <List<String>>[
        for (final record in attendance.where((item) => !item.isDeleted))
          [
            record.date,
            record.subjectId,
            record.sessionId,
            record.status.value,
          ],
        for (final record in legacy.where((item) => !item.isDeleted))
          [
            record.date,
            'legacy',
            record.id,
            '${record.attended}/${record.held}',
          ],
      ]..sort((a, b) => a.first.compareTo(b.first));

      if (rows.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          backupError: 'No attendance data available to export.',
        );
        return;
      }

      String quote(String value) => '"${value.replaceAll('"', '""')}"';
      final csv = StringBuffer('Date,Subject ID,Session ID,Status\n');
      for (final row in rows) {
        csv.writeln(row.map(quote).join(','));
      }
      final date = DateTime.now().toIso8601String().substring(0, 10);
      await SharePlus.instance.share(
        ShareParams(
          text: csv.toString(),
          subject: 'Attendance export',
          files: [
            XFile.fromData(
              utf8.encode(csv.toString()),
              mimeType: 'text/csv',
              name: 'attendance_export_$date.csv',
            ),
          ],
        ),
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        backupError: 'Unable to export attendance data: $e',
      );
    }
  }

  /// Opens the system file picker to select a JSON backup.
  Future<void> chooseBackup() async {
    state = state.copyWith(
      clearBackupError: true,
      clearPendingRestore: true,
      isLoading: true,
    );

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (file == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final Uint8List bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        state = state.copyWith(
          isLoading: false,
          backupError: 'Backup file is empty or exceeds the 5 MB safety limit.',
        );
        return;
      }

      if (bytes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          backupError: 'Backup file is empty or exceeds the 5 MB safety limit.',
        );
        return;
      }

      final parseResult = _backupService.parseBackup(bytes);
      if (parseResult.isValid) {
        state = state.copyWith(
          isLoading: false,
          pendingRestore: parseResult,
          clearBackupError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          backupError: parseResult.error ?? 'Unable to read backup.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        backupError: e is Exception ? e.toString() : 'Unable to read backup.',
      );
    }
  }

  /// Confirms and commits the pending restore data into local storage.
  Future<bool> confirmRestore() async {
    final pending = state.pendingRestore;
    if (pending == null || pending.data == null) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearBackupError: true);
    final result = await _backupService.restoreBackup(pending.data!);

    if (result.ok) {
      state = state.copyWith(
        isLoading: false,
        clearPendingRestore: true,
        successMessage: 'Backup successfully restored!',
      );
      // Invalidate stream providers to notify active UI
      _ref.invalidate(settingsStreamProvider);
      _ref.invalidate(subjectsStreamProvider);
      _ref.invalidate(timetableStreamProvider);
      _ref.invalidate(attendanceRecordsStreamProvider);
      _ref.invalidate(legacyAttendanceStreamProvider);
      _ref.invalidate(notesStreamProvider);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        backupError:
            result.error ?? 'Restore failed; existing data was not changed.',
      );
      return false;
    }
  }

  /// Cancels the pending restore preview.
  void cancelRestore() {
    state = state.copyWith(clearPendingRestore: true, clearBackupError: true);
  }

  // ==========================================
  // DANGER ZONE (RESET)
  // ==========================================

  /// Clears attendance history and sticky notes with pre-restore safety snapshot.
  Future<bool> resetAllAttendanceAndNotes() async {
    state = state.copyWith(isLoading: true);
    final success = await _backupService.resetAllAttendanceAndNotes();
    if (success) {
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Attendance history and notes cleared.',
      );
      _ref.invalidate(attendanceRecordsStreamProvider);
      _ref.invalidate(legacyAttendanceStreamProvider);
      _ref.invalidate(notesStreamProvider);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        backupError: 'Unable to reset attendance history safely.',
      );
      return false;
    }
  }
}

/// Riverpod StateNotifierProvider for [SettingsController].
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final backupService = ref.watch(backupServiceProvider);
      return SettingsController(ref, backupService);
    });
