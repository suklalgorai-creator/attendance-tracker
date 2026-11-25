import 'package:flutter_app/features/dailyflow/domain/entities/daily_task_entity.dart';
import 'package:flutter_app/features/dailyflow/domain/services/daily_flow_planner_service.dart';
import 'package:flutter_app/features/dashboard/domain/models/subject_attendance_stats.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/timetable/domain/entities/timetable_session_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const planner = DailyFlowPlannerService();

  group('DailyFlowPlannerService', () {
    test(
      'buildDayTimeline sorts chronologically and detects timetable conflicts',
      () {
        final date = DateTime(2026, 11, 25);
        final sessions = [
          TimetableSessionEntity(
            id: 'sess_1',
            dayOfWeek: 3,
            subjectId: 'sub_1',
            label: 'Operating Systems 10:00',
            createdAt: date,
            updatedAt: date,
          ),
        ];
        final tasks = [
          DailyTaskEntity(
            id: 't_overlap',
            title: 'Overlapping task',
            scheduledDate: '2026-11-25',
            startTime: '10:30',
            estimatedMinutes: 30,
            createdAt: date,
            updatedAt: date,
          ),
          DailyTaskEntity(
            id: 't_early',
            title: 'Morning review',
            scheduledDate: '2026-11-25',
            startTime: '08:00',
            estimatedMinutes: 30,
            createdAt: date,
            updatedAt: date,
          ),
        ];

        final timeline = planner.buildDayTimeline(
          date: date,
          tasks: tasks,
          daySessions: sessions,
        );

        expect(timeline.length, 3);
        expect((timeline[0] as TaskTimelineItem).task.id, 't_early');
        expect((timeline[0] as TaskTimelineItem).hasTimetableConflict, isFalse);
        expect((timeline[1] as TimetableTimelineItem).session.id, 'sess_1');
        expect((timeline[2] as TaskTimelineItem).task.id, 't_overlap');
        expect((timeline[2] as TaskTimelineItem).hasTimetableConflict, isTrue);
      },
    );

    test(
      'computeDaySummary prioritizes tasks linked to low-attendance subjects',
      () {
        final date = DateTime(2026, 11, 25, 9, 0);
        final safeSub = SubjectEntity(
          id: 'sub_safe',
          name: 'Math',
          createdAt: date,
          updatedAt: date,
        );
        final riskSub = SubjectEntity(
          id: 'sub_risk',
          name: 'Physics',
          createdAt: date,
          updatedAt: date,
        );

        final subjectStats = [
          SubjectAttendanceStats(
            subject: safeSub,
            conducted: 10,
            present: 9,
            absent: 1,
            percentage: 90.0,
            isSafe: true,
            isImpossible: false,
            canMiss: 2,
            needToAttend: 0,
          ),
          SubjectAttendanceStats(
            subject: riskSub,
            conducted: 10,
            present: 6,
            absent: 4,
            percentage: 60.0,
            isSafe: false,
            isImpossible: false,
            canMiss: 0,
            needToAttend: 6,
          ),
        ];

        final tasks = [
          DailyTaskEntity(
            id: 't_safe',
            title: 'Math Homework',
            priority: DailyTaskPriority.medium,
            scheduledDate: '2026-11-25',
            subjectId: 'sub_safe',
            createdAt: date,
            updatedAt: date,
          ),
          DailyTaskEntity(
            id: 't_risk',
            title: 'Physics Lab Prep',
            priority: DailyTaskPriority.medium,
            scheduledDate: '2026-11-25',
            subjectId: 'sub_risk',
            createdAt: date,
            updatedAt: date,
          ),
        ];

        final summary = planner.computeDaySummary(
          date: date,
          tasks: tasks,
          subjectStats: subjectStats,
          now: date,
        );

        expect(summary.totalTasks, 2);
        expect(summary.recommendedNextTask?.id, 't_risk');
        expect(summary.smartFocusReason, contains('Physics'));
      },
    );
  });
}
