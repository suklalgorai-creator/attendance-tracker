import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';

/// StateNotifier handling attendance actions (mark present/absent) and undo functionality.
class DashboardController extends StateNotifier<AsyncValue<void>> {
  final AttendanceRepository _attendanceRepository;
  AttendanceRecordEntity? _lastLoggedRecord;

  DashboardController(this._attendanceRepository)
    : super(const AsyncValue.data(null));

  /// Returns the most recently logged attendance record for undo purposes.
  AttendanceRecordEntity? get lastLoggedRecord => _lastLoggedRecord;

  /// Logs a present session for the specified subject.
  Future<void> markPresent(String subjectId) =>
      _logAttendance(subjectId, AttendanceStatus.present);

  /// Logs an absent session for the specified subject.
  Future<void> markAbsent(String subjectId) =>
      _logAttendance(subjectId, AttendanceStatus.absent);

  Future<void> _logAttendance(String subjectId, AttendanceStatus status) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final record = AttendanceRecordEntity(
        id: 'rec_${now.millisecondsSinceEpoch}_$subjectId',
        date: dateStr,
        subjectId: subjectId,
        sessionId: 'quick_${now.millisecondsSinceEpoch}',
        status: status,
        createdAt: now,
        updatedAt: now,
      );

      await _attendanceRepository.saveAttendanceRecord(record);
      _lastLoggedRecord = record;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reverts the most recent attendance action by soft-deleting the logged record.
  /// Returns `true` if a record was successfully undone, `false` otherwise.
  Future<bool> undoLastAction() async {
    final record = _lastLoggedRecord;
    if (record == null) return false;

    state = const AsyncValue.loading();
    try {
      await _attendanceRepository.deleteAttendanceRecord(record.id);
      _lastLoggedRecord = null;
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider exposing [DashboardController].
final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<void>>((ref) {
      return DashboardController(ref.watch(attendanceRepositoryProvider));
    });
