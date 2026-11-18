import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/utils/date_utils.dart';
import 'package:flutter_app/shared/widgets/view_toggles_widget.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_app/features/register/presentation/providers/register_controller.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  final List<LegacyAttendanceEntity> legacyStorage = [];
  final List<AttendanceRecordEntity> recordStorage = [];

  final _legacyStreamController =
      StreamController<List<LegacyAttendanceEntity>>.broadcast();
  final _recordsStreamController =
      StreamController<List<AttendanceRecordEntity>>.broadcast();

  @override
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance(
      {bool includeDeleted = false}) async {
    if (includeDeleted) return List.from(legacyStorage);
    return legacyStorage.where((r) => !r.isDeleted).toList();
  }

  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance(
      {bool includeDeleted = false}) {
    return _legacyStreamController.stream;
  }

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity record) async {
    final idx = legacyStorage.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      legacyStorage[idx] = record;
    } else {
      legacyStorage.add(record);
    }
    _legacyStreamController.add(List.from(legacyStorage));
  }

  @override
  Future<void> saveLegacyAttendances(
      List<LegacyAttendanceEntity> records) async {
    for (final r in records) {
      await saveLegacyAttendance(r);
    }
  }

  @override
  Future<void> deleteLegacyAttendance(String id) async {
    final idx = legacyStorage.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      legacyStorage[idx] = legacyStorage[idx].copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _legacyStreamController.add(List.from(legacyStorage));
    }
  }

  @override
  Future<void> hardDeleteLegacyAttendance(String id) async {
    legacyStorage.removeWhere((r) => r.id == id);
    _legacyStreamController.add(List.from(legacyStorage));
  }

  @override
  Future<void> restoreLegacyAttendance(String id) async {
    final idx = legacyStorage.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      legacyStorage[idx] = legacyStorage[idx].copyWith(clearDeletedAt: true);
      _legacyStreamController.add(List.from(legacyStorage));
    }
  }

  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords(
      {bool includeDeleted = false}) async {
    if (includeDeleted) return List.from(recordStorage);
    return recordStorage.where((r) => !r.isDeleted).toList();
  }

  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords(
      {bool includeDeleted = false}) {
    return _recordsStreamController.stream;
  }

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {
    final idx = recordStorage.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      recordStorage[idx] = record;
    } else {
      recordStorage.add(record);
    }
    _recordsStreamController.add(List.from(recordStorage));
  }

  @override
  Future<void> saveAttendanceRecords(
      List<AttendanceRecordEntity> records) async {
    for (final r in records) {
      await saveAttendanceRecord(r);
    }
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    final idx = recordStorage.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      recordStorage[idx] = recordStorage[idx].copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _recordsStreamController.add(List.from(recordStorage));
    }
  }

  @override
  Future<void> hardDeleteAttendanceRecord(String id) async {
    recordStorage.removeWhere((r) => r.id == id);
    _recordsStreamController.add(List.from(recordStorage));
  }

  @override
  Future<void> restoreAttendanceRecord(String id) async {
    final idx = recordStorage.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      recordStorage[idx] = recordStorage[idx].copyWith(clearDeletedAt: true);
      _recordsStreamController.add(List.from(recordStorage));
    }
  }

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(String date,
          {bool includeDeleted = false}) async =>
      [];

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(String subjectId,
          {bool includeDeleted = false}) async =>
      [];

  @override
  Future<void> clearAllAttendanceHistory() async {
    legacyStorage.clear();
    recordStorage.clear();
    _legacyStreamController.add([]);
    _recordsStreamController.add([]);
  }

  void dispose() {
    _legacyStreamController.close();
    _recordsStreamController.close();
  }
}

class FakeSettingsRepository implements SettingsRepository {
  UserSettingsEntity settings = const UserSettingsEntity(
    startDate: '2026-10-01',
    classDays: [1, 2, 3, 4, 5],
  );

  final _streamController = StreamController<UserSettingsEntity>.broadcast();

  @override
  Future<UserSettingsEntity> getSettings() async => settings;

  @override
  Stream<UserSettingsEntity> watchSettings() => _streamController.stream;

  @override
  Future<void> saveSettings(UserSettingsEntity newSettings) async {
    settings = newSettings;
    _streamController.add(settings);
  }

  @override
  Future<void> resetSettings() async {
    settings = const UserSettingsEntity();
    _streamController.add(settings);
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  late FakeAttendanceRepository attendanceRepo;
  late FakeSettingsRepository settingsRepo;
  late RegisterController controller;

  setUp(() {
    attendanceRepo = FakeAttendanceRepository();
    settingsRepo = FakeSettingsRepository();
    controller = RegisterController(
      attendanceRepository: attendanceRepo,
      settingsRepository: settingsRepo,
      legacyStream: attendanceRepo.watchLegacyAttendance(),
      recordsStream: attendanceRepo.watchAttendanceRecords(),
      settingsStream: settingsRepo.watchSettings(),
    );
  });

  tearDown(() {
    controller.dispose();
    attendanceRepo.dispose();
    settingsRepo.dispose();
  });

  group('RegisterController State Management', () {
    test('initializes with default week view mode and visible dates', () async {
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.viewMode, equals(RegisterViewMode.week));
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);

      final weekRange = AppDateUtils.getCurrentWeekRangeStr();
      for (final date in controller.state.visibleDates) {
        expect(date.compareTo(weekRange.start) >= 0, isTrue);
        expect(date.compareTo(weekRange.end) <= 0, isTrue);
      }
    });

    test('toggling view mode to month updates visibleDates to month range', () async {
      await Future<void>.delayed(Duration.zero);
      controller.setViewMode(RegisterViewMode.month);
      expect(controller.state.viewMode, equals(RegisterViewMode.month));

      final monthRange = AppDateUtils.getCurrentMonthRangeStr();
      for (final date in controller.state.visibleDates) {
        expect(date.compareTo(monthRange.start) >= 0, isTrue);
        expect(date.compareTo(monthRange.end) <= 0, isTrue);
      }
    });

    test('toggling view mode to all returns full historical descending rows', () async {
      await Future<void>.delayed(Duration.zero);
      controller.setViewMode(RegisterViewMode.all);
      expect(controller.state.viewMode, equals(RegisterViewMode.all));

      final today = AppDateUtils.todayStr();
      final expectedDates = AppDateUtils.classDayRangeDesc(
        '2026-10-01',
        today,
        const [1, 2, 3, 4, 5],
      );

      expect(controller.state.visibleDates, equals(expectedDates));
    });

    test('unions known non-class dates with classDayRangeDesc', () async {
      await Future<void>.delayed(Duration.zero);
      // Add a Saturday (non-class day) record
      // e.g. 2026-11-21 is Saturday
      const saturday = '2026-11-21';
      final satRecord = LegacyAttendanceEntity(
        id: 'daily-$saturday',
        date: saturday,
        held: 1,
        attended: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await attendanceRepo.saveLegacyAttendance(satRecord);
      await Future<void>.delayed(Duration.zero);

      controller.setViewMode(RegisterViewMode.all);
      expect(controller.state.visibleDates.contains(saturday), isTrue);
      expect(controller.state.legacyByDate[saturday], equals(satRecord));
    });

    test('saveDailyAttendance validates input and rejects invalid totals', () async {
      await Future<void>.delayed(Duration.zero);

      final r1 = await controller.saveDailyAttendance(date: '', held: 1, attended: 1);
      expect(r1, isFalse);
      expect(controller.state.errorMessage, equals('Enter valid daily class totals.'));

      final r2 = await controller.saveDailyAttendance(date: '2026-11-18', held: -1, attended: 0);
      expect(r2, isFalse);

      final r3 = await controller.saveDailyAttendance(date: '2026-11-18', held: 1, attended: 2);
      expect(r3, isFalse);
    });

    test('saveDailyAttendance creates new record when none exists', () async {
      await Future<void>.delayed(Duration.zero);
      const testDate = '2026-11-18';

      final success = await controller.saveDailyAttendance(
        date: testDate,
        held: 1,
        attended: 1,
      );

      expect(success, isTrue);
      expect(controller.state.errorMessage, isNull);

      await Future<void>.delayed(Duration.zero);
      expect(attendanceRepo.legacyStorage.any((r) => r.date == testDate && r.held == 1 && r.attended == 1), isTrue);
      expect(controller.state.legacyByDate[testDate]?.held, equals(1));
      expect(controller.state.legacyByDate[testDate]?.attended, equals(1));
    });

    test('saveDailyAttendance updates existing record preserving id and createdAt', () async {
      await Future<void>.delayed(Duration.zero);
      const testDate = '2026-11-18';
      final initialCreated = DateTime(2026, 11, 10);

      await attendanceRepo.saveLegacyAttendance(LegacyAttendanceEntity(
        id: 'daily-$testDate',
        date: testDate,
        held: 1,
        attended: 0,
        createdAt: initialCreated,
        updatedAt: initialCreated,
      ));

      await Future<void>.delayed(Duration.zero);

      final success = await controller.saveDailyAttendance(
        date: testDate,
        held: 1,
        attended: 1,
      );

      expect(success, isTrue);
      await Future<void>.delayed(Duration.zero);

      final saved = attendanceRepo.legacyStorage.firstWhere((r) => r.date == testDate);
      expect(saved.id, equals('daily-$testDate'));
      expect(saved.held, equals(1));
      expect(saved.attended, equals(1));
      expect(saved.createdAt, equals(initialCreated));
    });

    test('deleteDailyAttendance soft-deletes record', () async {
      await Future<void>.delayed(Duration.zero);
      const testDate = '2026-11-18';

      await controller.saveDailyAttendance(date: testDate, held: 1, attended: 1);
      await Future<void>.delayed(Duration.zero);

      final record = controller.state.legacyByDate[testDate]!;
      final deleted = await controller.deleteDailyAttendance(record.id);
      expect(deleted, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(controller.state.legacyByDate.containsKey(testDate), isFalse);
    });

    test('deleteDailyAttendanceByDate soft-deletes record by date key', () async {
      await Future<void>.delayed(Duration.zero);
      const testDate = '2026-11-18';

      await controller.saveDailyAttendance(date: testDate, held: 1, attended: 1);
      await Future<void>.delayed(Duration.zero);

      final deleted = await controller.deleteDailyAttendanceByDate(testDate);
      expect(deleted, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(controller.state.legacyByDate.containsKey(testDate), isFalse);
    });

    test('reacts to settings stream updates', () async {
      await Future<void>.delayed(Duration.zero);

      await settingsRepo.saveSettings(const UserSettingsEntity(
        startDate: '2026-11-01',
        classDays: [1, 3, 5], // Mon, Wed, Fri
      ));

      await Future<void>.delayed(Duration.zero);
      controller.setViewMode(RegisterViewMode.all);

      for (final date in controller.state.visibleDates) {
        expect(AppDateUtils.isClassDay(date, [1, 3, 5]), isTrue);
      }
    });
  });
}
