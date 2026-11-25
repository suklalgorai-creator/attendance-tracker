import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../dashboard/domain/models/subject_attendance_stats.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import 'subject_controller.dart';

/// Provider exposing [SubjectController].
final subjectControllerProvider =
    StateNotifierProvider<SubjectController, AsyncValue<void>>((ref) {
      return SubjectController(ref.watch(subjectRepositoryProvider));
    });

/// Reactive provider computing detailed attendance statistics for an individual subject by ID.
final subjectDetailStatsProvider =
    Provider.family<AsyncValue<SubjectAttendanceStats?>, String>((
      ref,
      subjectId,
    ) {
      final subjectsAsync = ref.watch(subjectsStreamProvider);
      final recordsAsync = ref.watch(attendanceRecordsStreamProvider);
      final settingsAsync = ref.watch(settingsStreamProvider);
      final service = ref.watch(dashboardAnalyticsServiceProvider);

      if (subjectsAsync.hasError) {
        return AsyncValue.error(
          subjectsAsync.error!,
          subjectsAsync.stackTrace!,
        );
      }
      if (recordsAsync.hasError) {
        return AsyncValue.error(recordsAsync.error!, recordsAsync.stackTrace!);
      }

      if (subjectsAsync.isLoading || recordsAsync.isLoading) {
        return const AsyncValue.loading();
      }

      final subjects = subjectsAsync.value ?? [];
      final subject = subjects.cast<dynamic>().firstWhere(
        (s) => s.id == subjectId && !s.isDeleted,
        orElse: () => null,
      );

      if (subject == null) {
        return const AsyncValue.data(null);
      }

      final records = recordsAsync.value ?? [];
      final settings = settingsAsync.value;
      final minPercent = settings?.minPercent ?? 75.0;
      final rawHolidays = ref.watch(globalSettingsProvider).valueOrNull?['holidays'];
      final holidays = rawHolidays is Map
          ? rawHolidays.keys.map((k) => k.toString()).toSet()
          : const <String>{};

      final stats = service.computeSubjectStats(
        subject: subject,
        attendanceRecords: records,
        minPercent: minPercent,
        holidays: holidays,
      );

      return AsyncValue.data(stats);
    });

/// Reactive provider returning session history records for a specific subject,
/// sorted descending by date/time.
final subjectHistoryProvider =
    Provider.family<AsyncValue<List<AttendanceRecordEntity>>, String>((
      ref,
      subjectId,
    ) {
      final recordsAsync = ref.watch(attendanceRecordsStreamProvider);

      if (recordsAsync.hasError) {
        return AsyncValue.error(recordsAsync.error!, recordsAsync.stackTrace!);
      }
      if (recordsAsync.isLoading) {
        return const AsyncValue.loading();
      }

      final allRecords = recordsAsync.value ?? [];
      final subjectRecords =
          allRecords
              .where((r) => r.subjectId == subjectId && !r.isDeleted)
              .toList()
            ..sort((a, b) {
              // Sort reverse-chronological by date, then createdAt
              final dateComp = b.date.compareTo(a.date);
              if (dateComp != 0) return dateComp;
              return b.createdAt.compareTo(a.createdAt);
            });

      return AsyncValue.data(subjectRecords);
    });
