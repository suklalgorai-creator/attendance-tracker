import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../domain/services/daily_flow_planner_service.dart';

export '../../../../core/providers/repository_providers.dart'
    show dailyFlowRepositoryProvider, dailyFlowTasksStreamProvider;

// ==========================================
// DAILYFLOW PROVIDERS - Date Filter, Timeline & Summary
// Manages selected planning date, status filters, merged timeline, and day metrics.
// ==========================================

final dailyFlowSelectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final dailyFlowStatusFilterProvider = StateProvider<DailyTaskStatus?>(
  (ref) => null,
);

final dailyFlowPlannerServiceProvider = Provider<DailyFlowPlannerService>((
  ref,
) {
  return const DailyFlowPlannerService();
});

/// Chronological timeline for [dailyFlowSelectedDateProvider] combining
/// weekly college timetable sessions and DailyFlow tasks.
final dailyFlowTimelineProvider = Provider<List<DailyFlowTimelineItem>>((ref) {
  final date = ref.watch(dailyFlowSelectedDateProvider);
  final tasks = ref.watch(dailyFlowTasksStreamProvider).valueOrNull ?? const [];
  final timetable = ref.watch(timetableStreamProvider).valueOrNull ?? const {};
  final statusFilter = ref.watch(dailyFlowStatusFilterProvider);
  final planner = ref.watch(dailyFlowPlannerServiceProvider);

  final dayOfWeek = date.weekday % 7;
  final daySessions = timetable[dayOfWeek] ?? const [];

  final filteredTasks = statusFilter == null
      ? tasks
      : tasks.where((t) => t.status == statusFilter).toList();

  return planner.buildDayTimeline(
    date: date,
    tasks: filteredTasks,
    daySessions: daySessions,
  );
});

/// Daily execution summary & smart next-task recommendation for [dailyFlowSelectedDateProvider].
final dailyFlowDaySummaryProvider = Provider<DailyFlowDaySummary>((ref) {
  final date = ref.watch(dailyFlowSelectedDateProvider);
  final tasks = ref.watch(dailyFlowTasksStreamProvider).valueOrNull ?? const [];
  final subjectStats =
      ref.watch(subjectStatsListProvider).valueOrNull ?? const [];
  final planner = ref.watch(dailyFlowPlannerServiceProvider);

  return planner.computeDaySummary(
    date: date,
    tasks: tasks,
    subjectStats: subjectStats,
  );
});

/// Today's DailyFlow summary for the Dashboard overview card.
final todaysDailyFlowSummaryProvider = Provider<DailyFlowDaySummary>((ref) {
  final tasks = ref.watch(dailyFlowTasksStreamProvider).valueOrNull ?? const [];
  final subjectStats =
      ref.watch(subjectStatsListProvider).valueOrNull ?? const [];
  final planner = ref.watch(dailyFlowPlannerServiceProvider);

  return planner.computeDaySummary(
    date: DateTime.now(),
    tasks: tasks,
    subjectStats: subjectStats,
  );
});
