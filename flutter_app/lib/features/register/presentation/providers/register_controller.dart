import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/view_toggles_widget.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../settings/domain/entities/user_settings_entity.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import 'register_state.dart';

class RegisterController extends StateNotifier<RegisterState> {
  final AttendanceRepository _attendanceRepository;
  final SettingsRepository? _settingsRepository;

  List<LegacyAttendanceEntity> _legacyRecords = [];
  List<AttendanceRecordEntity> _attendanceRecords = [];
  UserSettingsEntity _settings = const UserSettingsEntity();

  StreamSubscription<List<LegacyAttendanceEntity>>? _legacySub;
  StreamSubscription<List<AttendanceRecordEntity>>? _recordsSub;
  StreamSubscription<UserSettingsEntity>? _settingsSub;

  RegisterController({
    required AttendanceRepository attendanceRepository,
    SettingsRepository? settingsRepository,
    Stream<List<LegacyAttendanceEntity>>? legacyStream,
    Stream<List<AttendanceRecordEntity>>? recordsStream,
    Stream<UserSettingsEntity>? settingsStream,
    RegisterViewMode initialViewMode = RegisterViewMode.week,
  }) : _attendanceRepository = attendanceRepository,
       _settingsRepository = settingsRepository,
       super(RegisterState(viewMode: initialViewMode, isLoading: true)) {
    Stream<List<LegacyAttendanceEntity>> safeLegacy() {
      if (legacyStream != null) return legacyStream;
      try {
        return attendanceRepository.watchLegacyAttendance();
      } catch (_) {
        return const Stream.empty();
      }
    }

    Stream<List<AttendanceRecordEntity>> safeRecords() {
      if (recordsStream != null) return recordsStream;
      try {
        return attendanceRepository.watchAttendanceRecords();
      } catch (_) {
        return const Stream.empty();
      }
    }

    Stream<UserSettingsEntity>? safeSettings() {
      if (settingsStream != null) return settingsStream;
      if (settingsRepository == null) return null;
      try {
        return settingsRepository.watchSettings();
      } catch (_) {
        return const Stream.empty();
      }
    }

    _init(
      legacyStream: safeLegacy(),
      recordsStream: safeRecords(),
      settingsStream: safeSettings(),
    );
  }

  void _init({
    required Stream<List<LegacyAttendanceEntity>> legacyStream,
    required Stream<List<AttendanceRecordEntity>> recordsStream,
    Stream<UserSettingsEntity>? settingsStream,
  }) {
    // Attempt initial async load
    _loadInitial();

    _legacySub = legacyStream.listen((records) {
      _legacyRecords = records.where((r) => !r.isDeleted).toList();
      _recompute();
    });

    _recordsSub = recordsStream.listen((records) {
      _attendanceRecords = records.where((r) => !r.isDeleted).toList();
      _recompute();
    });

    if (settingsStream != null) {
      _settingsSub = settingsStream.listen((settings) {
        _settings = settings;
        _recompute();
      });
    }
  }

  Future<void> _loadInitial() async {
    try {
      if (_settingsRepository != null) {
        final initialSettings = await _settingsRepository.getSettings();
        _settings = initialSettings;
      }
      final initialLegacy = await _attendanceRepository.getLegacyAttendance();
      _legacyRecords = initialLegacy.where((r) => !r.isDeleted).toList();

      final initialRecords = await _attendanceRepository.getAttendanceRecords();
      _attendanceRecords = initialRecords.where((r) => !r.isDeleted).toList();
      _recompute();
    } catch (_) {
      // Stream subscriptions will provide updates if initial load errors
      _recompute();
    }
  }

  void setViewMode(RegisterViewMode mode) {
    if (state.viewMode == mode) return;
    state = state.copyWith(viewMode: mode);
    _recompute();
  }

  void _recompute() {
    final today = AppDateUtils.todayStr();
    final classDays = _settings.classDays.isNotEmpty
        ? _settings.classDays
        : const [1, 2, 3, 4, 5];
    final startDate = _settings.startDate;

    final knownDates = <String>{
      for (final r in _attendanceRecords)
        if (!r.isDeleted && r.date.isNotEmpty) r.date,
      for (final r in _legacyRecords)
        if (!r.isDeleted && r.date.isNotEmpty) r.date,
    };

    final classDates = AppDateUtils.classDayRangeDesc(
      startDate,
      today,
      classDays,
    );
    final fullHistory = <String>{...classDates, ...knownDates}.toList()
      ..sort((a, b) => b.compareTo(a));

    final weekRange = AppDateUtils.getCurrentWeekRangeStr();
    final monthRange = AppDateUtils.getCurrentMonthRangeStr();

    final visibleDates = switch (state.viewMode) {
      RegisterViewMode.all => fullHistory,
      RegisterViewMode.month =>
        fullHistory
            .where(
              (d) =>
                  d.compareTo(monthRange.start) >= 0 &&
                  d.compareTo(monthRange.end) <= 0,
            )
            .toList(),
      RegisterViewMode.week =>
        fullHistory
            .where(
              (d) =>
                  d.compareTo(weekRange.start) >= 0 &&
                  d.compareTo(weekRange.end) <= 0,
            )
            .toList(),
    };

    final legacyByDate = <String, LegacyAttendanceEntity>{
      for (final r in _legacyRecords)
        if (!r.isDeleted) r.date: r,
    };

    state = state.copyWith(
      visibleDates: visibleDates,
      legacyByDate: legacyByDate,
      isLoading: false,
      clearError: true,
    );
  }

  Future<bool> saveDailyAttendance({
    required String date,
    required int held,
    required int attended,
  }) async {
    if (date.isEmpty || held < 0 || attended < 0 || attended > held) {
      state = state.copyWith(errorMessage: 'Enter valid daily class totals.');
      return false;
    }

    try {
      final existing = _legacyRecords
          .where((r) => !r.isDeleted && r.date == date)
          .firstOrNull;
      final now = DateTime.now();

      final record = existing != null
          ? existing.copyWith(
              held: held,
              attended: attended,
              updatedAt: now,
              clearDeletedAt: true,
            )
          : LegacyAttendanceEntity(
              id: 'daily-$date',
              date: date,
              held: held,
              attended: attended,
              createdAt: now,
              updatedAt: now,
            );

      await _attendanceRepository.saveLegacyAttendance(record);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteDailyAttendance(String id) async {
    try {
      await _attendanceRepository.deleteLegacyAttendance(id);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteDailyAttendanceByDate(String date) async {
    final record = state.legacyByDate[date];
    if (record == null) return false;
    return deleteDailyAttendance(record.id);
  }

  @override
  void dispose() {
    _legacySub?.cancel();
    _recordsSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }
}
