import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../domain/models/calendar_day_summary.dart';
import '../../domain/services/calendar_analytics_service.dart';

/// Riverpod providers driving focused calendar month, view toggle, day summaries,
/// and 26-week heatmap records.
///
/// Ownership: Calendar Feature (Providers)
// ==========================================
// CALENDAR PROVIDERS - Focused Month, Mode & Summaries
// ==========================================

/// Supported display views for the Activity Card.
enum CalendarViewMode { calendar, heatmap }

/// Provider for pure calendar analytics calculation service.
final calendarAnalyticsServiceProvider = Provider<CalendarAnalyticsService>((
  ref,
) {
  return const CalendarAnalyticsService();
});

/// State notifier managing the currently focused month and year in the calendar view.
class CalendarDateNotifier extends StateNotifier<DateTime> {
  CalendarDateNotifier() : super(DateTime.now());

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void prevMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, 1);
  }

  void resetToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, 1);
  }
}

/// Provider holding the active year & month in the calendar view.
final calendarDateProvider =
    StateNotifierProvider<CalendarDateNotifier, DateTime>((ref) {
      return CalendarDateNotifier();
    });

/// Provider for toggling between Calendar grid and GitHub-style Heatmap views.
final calendarViewModeProvider = StateProvider<CalendarViewMode>((ref) {
  return CalendarViewMode.calendar;
});

/// Reactive provider computing day summaries for all days in the currently viewed month.
final calendarDaysInMonthProvider =
    Provider<AsyncValue<List<CalendarDaySummary>>>((ref) {
      final service = ref.watch(calendarAnalyticsServiceProvider);
      final focusedDate = ref.watch(calendarDateProvider);
      final recordsAsync = ref.watch(attendanceRecordsStreamProvider);
      final legacyAsync = ref.watch(legacyAttendanceStreamProvider);
      final settingsAsync = ref.watch(settingsStreamProvider);

      if (recordsAsync.isLoading ||
          legacyAsync.isLoading ||
          settingsAsync.isLoading) {
        return const AsyncValue.loading();
      }

      final records = recordsAsync.valueOrNull ?? <AttendanceRecordEntity>[];
      final legacyList = legacyAsync.valueOrNull ?? <LegacyAttendanceEntity>[];

      final Map<String, LegacyAttendanceEntity> legacyByDate = {
        for (final l in legacyList)
          if (!l.isDeleted) l.date: l,
      };

      // Read declared global holidays from settings/global
      final globalSettings = ref.watch(globalSettingsProvider).valueOrNull;
      final Map<String, bool> holidays = {};
      final rawHolidays = globalSettings?['holidays'];
      if (rawHolidays is Map) {
        for (final entry in rawHolidays.entries) {
          if (entry.value != false) {
            holidays[entry.key.toString()] = true;
          }
        }
      }

      try {
        final summaries = service.computeDaysInMonth(
          year: focusedDate.year,
          month: focusedDate.month,
          records: records,
          legacyByDate: legacyByDate,
          holidays: holidays,
        );
        return AsyncValue.data(summaries);
      } catch (error, stackTrace) {
        return AsyncValue.error(error, stackTrace);
      }
    });

/// Reactive provider calculating monthly summary statistics (held, attended, holidays).
final calendarMonthSummaryProvider = Provider<AsyncValue<CalendarMonthSummary>>(
  (ref) {
    final service = ref.watch(calendarAnalyticsServiceProvider);
    final focusedDate = ref.watch(calendarDateProvider);
    final daysAsync = ref.watch(calendarDaysInMonthProvider);

    return daysAsync.when(
      data: (daySummaries) {
        final summary = service.computeMonthSummary(
          year: focusedDate.year,
          month: focusedDate.month,
          daySummaries: daySummaries,
        );
        return AsyncValue.data(summary);
      },
      loading: () => const AsyncValue.loading(),
      error: (err, st) => AsyncValue.error(err, st),
    );
  },
);

/// Reactive provider calculating the 26-week heatmap data map.
final heatmapRecordsProvider =
    Provider<
      AsyncValue<Map<String, ({int held, int attended, bool isHoliday})>>
    >((ref) {
      final service = ref.watch(calendarAnalyticsServiceProvider);
      final recordsAsync = ref.watch(attendanceRecordsStreamProvider);
      final legacyAsync = ref.watch(legacyAttendanceStreamProvider);
      final settingsAsync = ref.watch(settingsStreamProvider);

      if (recordsAsync.isLoading ||
          legacyAsync.isLoading ||
          settingsAsync.isLoading) {
        return const AsyncValue.loading();
      }

      final records = recordsAsync.valueOrNull ?? <AttendanceRecordEntity>[];
      final legacyList = legacyAsync.valueOrNull ?? <LegacyAttendanceEntity>[];

      final Map<String, bool> holidays = {};

      try {
        final heatmapData = service.computeHeatmapRecords(
          records: records,
          legacyRecords: legacyList,
          holidays: holidays,
        );
        return AsyncValue.data(heatmapData);
      } catch (error, stackTrace) {
        return AsyncValue.error(error, stackTrace);
      }
    });
