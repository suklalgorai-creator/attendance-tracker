import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/dashboard_stats.dart';
import '../../domain/models/subject_attendance_stats.dart';
import '../../domain/services/dashboard_analytics_service.dart';

/// Provider for the pure Dart analytics service.
final dashboardAnalyticsServiceProvider = Provider<DashboardAnalyticsService>((ref) {
  return const DashboardAnalyticsService();
});

/// Reactive provider computing overall dashboard statistics.
final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final recordsAsync = ref.watch(attendanceRecordsStreamProvider);
  final legacyAsync = ref.watch(legacyAttendanceStreamProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final service = ref.watch(dashboardAnalyticsServiceProvider);

  if (recordsAsync.hasError) {
    return AsyncValue.error(recordsAsync.error!, recordsAsync.stackTrace!);
  }
  if (legacyAsync.hasError) {
    return AsyncValue.error(legacyAsync.error!, legacyAsync.stackTrace!);
  }
  if (settingsAsync.hasError) {
    return AsyncValue.error(settingsAsync.error!, settingsAsync.stackTrace!);
  }

  if (recordsAsync.isLoading || legacyAsync.isLoading || settingsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final records = recordsAsync.value ?? [];
  final legacy = legacyAsync.value ?? [];
  final settings = settingsAsync.value;
  final minPercent = settings?.minPercent ?? 75.0;

  final stats = service.computeOverallStats(
    attendanceRecords: records,
    legacyAttendance: legacy,
    minPercent: minPercent,
  );

  return AsyncValue.data(stats);
});

/// Reactive provider computing attendance stats for all active subjects.
final subjectStatsListProvider = Provider<AsyncValue<List<SubjectAttendanceStats>>>((ref) {
  final subjectsAsync = ref.watch(subjectsStreamProvider);
  final recordsAsync = ref.watch(attendanceRecordsStreamProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final service = ref.watch(dashboardAnalyticsServiceProvider);

  if (subjectsAsync.hasError) {
    return AsyncValue.error(subjectsAsync.error!, subjectsAsync.stackTrace!);
  }
  if (recordsAsync.hasError) {
    return AsyncValue.error(recordsAsync.error!, recordsAsync.stackTrace!);
  }
  if (settingsAsync.hasError) {
    return AsyncValue.error(settingsAsync.error!, settingsAsync.stackTrace!);
  }

  if (subjectsAsync.isLoading || recordsAsync.isLoading || settingsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final subjects = subjectsAsync.value ?? [];
  final records = recordsAsync.value ?? [];
  final settings = settingsAsync.value;
  final minPercent = settings?.minPercent ?? 75.0;

  final statsList = service.computeAllSubjectStats(
    subjects: subjects,
    attendanceRecords: records,
    minPercent: minPercent,
  );

  return AsyncValue.data(statsList);
});

/// Reactive provider computing consecutive class-day streak.
final streakCountProvider = Provider<AsyncValue<int>>((ref) {
  final recordsAsync = ref.watch(attendanceRecordsStreamProvider);
  final legacyAsync = ref.watch(legacyAttendanceStreamProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final service = ref.watch(dashboardAnalyticsServiceProvider);

  if (recordsAsync.hasError) {
    return AsyncValue.error(recordsAsync.error!, recordsAsync.stackTrace!);
  }
  if (legacyAsync.hasError) {
    return AsyncValue.error(legacyAsync.error!, legacyAsync.stackTrace!);
  }
  if (settingsAsync.hasError) {
    return AsyncValue.error(settingsAsync.error!, settingsAsync.stackTrace!);
  }

  if (recordsAsync.isLoading || legacyAsync.isLoading || settingsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final records = recordsAsync.value ?? [];
  final legacy = legacyAsync.value ?? [];
  final settings = settingsAsync.value;
  final classDays = settings?.classDays ?? const [1, 2, 3, 4, 5];

  final streak = service.computeStreak(
    attendanceRecords: records,
    legacyAttendance: legacy,
    classDays: classDays,
  );

  return AsyncValue.data(streak);
});
