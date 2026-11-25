import '../../../../core/utils/date_utils.dart';
import '../../../dashboard/domain/models/subject_attendance_stats.dart';
import '../../../timetable/domain/entities/timetable_session_entity.dart';
import '../entities/daily_task_entity.dart';

/// Pure planning service merging weekly timetable classes with DailyFlow tasks
/// and computing daily progress summaries and smart recommendations.
///
/// Ownership: DailyFlow Feature (Domain Service)
// ==========================================
// DAILYFLOW PLANNER - Timeline & Day Summary Engine
// ==========================================

/// Unified timeline item combining college timetable sessions and DailyFlow tasks.
sealed class DailyFlowTimelineItem {
  int get sortMinutes;
}

class TimetableTimelineItem extends DailyFlowTimelineItem {
  final TimetableSessionEntity session;
  @override
  final int sortMinutes;

  TimetableTimelineItem({required this.session, required this.sortMinutes});
}

class TaskTimelineItem extends DailyFlowTimelineItem {
  final DailyTaskEntity task;
  final bool hasTimetableConflict;
  @override
  final int sortMinutes;

  TaskTimelineItem({
    required this.task,
    required this.sortMinutes,
    this.hasTimetableConflict = false,
  });
}

/// Summary metrics for a single day in DailyFlow.
class DailyFlowDaySummary {
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int plannedMinutes;
  final int executedSeconds;
  final DailyTaskEntity? activeTask;
  final DailyTaskEntity? recommendedNextTask;
  final String? smartFocusReason;

  const DailyFlowDaySummary({
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.plannedMinutes,
    required this.executedSeconds,
    this.activeTask,
    this.recommendedNextTask,
    this.smartFocusReason,
  });

  double get completionRate =>
      totalTasks == 0 ? 0.0 : (completedTasks / totalTasks).clamp(0.0, 1.0);
}

/// Planning & prioritization service merging timetable classes, subject risk,
/// and DailyFlow tasks into an actionable schedule.
class DailyFlowPlannerService {
  const DailyFlowPlannerService();

  /// Parses `HH:mm` into minutes since midnight; returns [fallback] if invalid.
  static int parseMinutes(String? timeStr, {int fallback = 23 * 60 + 59}) {
    if (timeStr == null || !timeStr.contains(':')) return fallback;
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) return fallback;
    return (h.clamp(0, 23) * 60) + m.clamp(0, 59);
  }

  static int? _extractTimeMinutes(String label) {
    final match = RegExp(r'\b(\d{1,2}):(\d{2})\b').firstMatch(label);
    if (match == null) return null;
    final h = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    if (h == null || m == null) return null;
    return (h.clamp(0, 23) * 60) + m.clamp(0, 59);
  }

  /// Builds a chronologically sorted timeline for [date] combining scheduled
  /// timetable classes and DailyFlow tasks, flagging time-block overlaps.
  List<DailyFlowTimelineItem> buildDayTimeline({
    required DateTime date,
    required List<DailyTaskEntity> tasks,
    required List<TimetableSessionEntity> daySessions,
  }) {
    final dateKey = AppDateUtils.formatDateKey(date);
    final activeTasks = tasks
        .where(
          (t) =>
              !t.isDeleted &&
              t.scheduledDate == dateKey &&
              t.status != DailyTaskStatus.archived,
        )
        .toList();

    final sessionIntervals = <(int, int)>[];
    final items = <DailyFlowTimelineItem>[];

    var sessionIndex = 0;
    for (final session in daySessions.where((s) => !s.isDeleted)) {
      final parsedStart = _extractTimeMinutes(session.label);
      final startMin = parsedStart ?? (8 * 60 + sessionIndex * 60);
      if (parsedStart != null) {
        sessionIntervals.add((startMin, startMin + 60));
      }
      items.add(TimetableTimelineItem(session: session, sortMinutes: startMin));
      sessionIndex++;
    }

    for (final task in activeTasks) {
      final hasTime = task.startTime != null && task.startTime!.contains(':');
      final taskStart = hasTime ? parseMinutes(task.startTime) : 24 * 60;
      final taskEnd = taskStart + task.estimatedMinutes;

      var conflict = false;
      if (hasTime && !task.status.isTerminal) {
        for (final (sStart, sEnd) in sessionIntervals) {
          if (taskStart < sEnd && taskEnd > sStart) {
            conflict = true;
            break;
          }
        }
      }

      items.add(
        TaskTimelineItem(
          task: task,
          sortMinutes: taskStart,
          hasTimetableConflict: conflict,
        ),
      );
    }

    items.sort((a, b) => a.sortMinutes.compareTo(b.sortMinutes));
    return items;
  }

  /// Computes daily execution metrics and selects the highest-leverage next task
  /// using priority, scheduled time, and linked subject attendance risk.
  DailyFlowDaySummary computeDaySummary({
    required DateTime date,
    required List<DailyTaskEntity> tasks,
    List<SubjectAttendanceStats> subjectStats = const [],
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final dateKey = AppDateUtils.formatDateKey(date);

    final dayTasks = tasks
        .where(
          (t) =>
              !t.isDeleted &&
              t.scheduledDate == dateKey &&
              t.status != DailyTaskStatus.archived,
        )
        .toList();

    var completed = 0;
    var inProgress = 0;
    var plannedMins = 0;
    var executedSecs = 0;
    DailyTaskEntity? activeTask;

    for (final t in dayTasks) {
      if (t.status == DailyTaskStatus.completed) {
        completed++;
      } else if (t.status == DailyTaskStatus.inProgress) {
        inProgress++;
        activeTask ??= t;
      }
      if (t.status != DailyTaskStatus.skipped) {
        plannedMins += t.estimatedMinutes;
      }
      executedSecs += t.totalElapsedSecondsAt(effectiveNow);
    }

    final statsBySubjectId = {for (final s in subjectStats) s.subject.id: s};

    final candidates = dayTasks
        .where(
          (t) =>
              t.status == DailyTaskStatus.planned ||
              t.status == DailyTaskStatus.paused,
        )
        .toList();

    DailyTaskEntity? recommended;
    String? reason;

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) {
        final scoreB = _scoreTask(b, statsBySubjectId, effectiveNow);
        final scoreA = _scoreTask(a, statsBySubjectId, effectiveNow);
        return scoreB.compareTo(scoreA);
      });
      recommended = candidates.first;
      reason = _buildReason(recommended, statsBySubjectId);
    }

    return DailyFlowDaySummary(
      totalTasks: dayTasks.length,
      completedTasks: completed,
      inProgressTasks: inProgress,
      plannedMinutes: plannedMins,
      executedSeconds: executedSecs,
      activeTask: activeTask,
      recommendedNextTask: recommended,
      smartFocusReason: reason,
    );
  }

  int _scoreTask(
    DailyTaskEntity task,
    Map<String, SubjectAttendanceStats> statsBySubjectId,
    DateTime now,
  ) {
    var score = task.priority.weight * 100;
    if (task.status == DailyTaskStatus.paused) score += 50;
    if (task.startTime != null) {
      final nowMins = now.hour * 60 + now.minute;
      final taskMins = parseMinutes(task.startTime);
      if (taskMins <= nowMins + 60) score += 40;
    }
    if (task.subjectId != null) {
      final stats = statsBySubjectId[task.subjectId];
      if (stats != null && !stats.isSafe) {
        score += 60; // Prioritize tasks tied to subjects below threshold
      }
    }
    return score;
  }

  String _buildReason(
    DailyTaskEntity task,
    Map<String, SubjectAttendanceStats> statsBySubjectId,
  ) {
    if (task.status == DailyTaskStatus.paused) {
      return 'Resume paused session';
    }
    if (task.subjectId != null) {
      final stats = statsBySubjectId[task.subjectId];
      if (stats != null && !stats.isSafe) {
        return 'Linked to ${stats.subject.name} (needs attention)';
      }
    }
    if (task.priority == DailyTaskPriority.urgent ||
        task.priority == DailyTaskPriority.high) {
      return '${task.priority.label} priority focus block';
    }
    if (task.startTime != null) {
      return 'Scheduled for ${task.startTime}';
    }
    return 'Next up in your plan';
  }
}
