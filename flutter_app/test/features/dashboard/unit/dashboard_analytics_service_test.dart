import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/dashboard/domain/services/dashboard_analytics_service.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';

void main() {
  const service = DashboardAnalyticsService();

  group('DashboardAnalyticsService - calculateAttendance', () {
    test('Calculates valid percentages accurately', () {
      expect(service.calculateAttendance(18, 20), closeTo(90.0, 1e-6));
      expect(service.calculateAttendance(3, 4), closeTo(75.0, 1e-6));
      expect(service.calculateAttendance(1, 3), closeTo(33.333333, 1e-4));
      expect(service.calculateAttendance(0, 10), 0.0);
    });

    test('Returns null when conducted <= 0', () {
      expect(service.calculateAttendance(0, 0), isNull);
      expect(service.calculateAttendance(0, -1), isNull);
      expect(service.calculateAttendance(5, 0), isNull);
    });

    test('Returns null on invalid constraints (present < 0 or present > conducted)', () {
      expect(service.calculateAttendance(-1, 10), isNull);
      expect(service.calculateAttendance(11, 10), isNull);
    });
  });

  group('DashboardAnalyticsService - calculateMaximumAbsences (Safe Bunks)', () {
    test('Returns correct allowable absences for safe attendance', () {
      // 10 / 10 at 75% -> floor((10 * 100) / 75 - 10 + 1e-10) = floor(13.333 - 10) = 3
      expect(service.calculateMaximumAbsences(10, 10, 75.0), 3);

      // 20 / 20 at 80% -> floor(25 - 20) = 5
      expect(service.calculateMaximumAbsences(20, 20, 80.0), 5);

      // 8 / 10 at 75% -> 80% >= 75%: floor(10.666 - 10) = 0
      expect(service.calculateMaximumAbsences(8, 10, 75.0), 0);
    });

    test('Returns 0 when attendance is exactly at threshold', () {
      // 75 / 100 at 75% -> 0
      expect(service.calculateMaximumAbsences(75, 100, 75.0), 0);
    });

    test('Returns 0 when attendance is below threshold', () {
      // 74 / 100 at 75% -> below threshold
      expect(service.calculateMaximumAbsences(74, 100, 75.0), 0);
      expect(service.calculateMaximumAbsences(0, 10, 75.0), 0);
    });

    test('Returns 0 for invalid inputs', () {
      expect(service.calculateMaximumAbsences(0, 0, 75.0), 0);
      expect(service.calculateMaximumAbsences(10, 10, 0.0), 0);
      expect(service.calculateMaximumAbsences(10, 10, -5.0), 0);
      expect(service.calculateMaximumAbsences(10, 10, 105.0), 0);
    });
  });

  group('DashboardAnalyticsService - calculateRequiredRecoveryClasses', () {
    test('Returns 0 when attendance is already at or above threshold', () {
      expect(service.calculateRequiredRecoveryClasses(80, 100, 75.0), 0);
      expect(service.calculateRequiredRecoveryClasses(75, 100, 75.0), 0);
      expect(service.calculateRequiredRecoveryClasses(10, 10, 75.0), 0);
    });

    test('Calculates recovery classes accurately using ceiling with guard', () {
      // 60 / 100 at 75% -> ceil(((75 * 100) - (100 * 60)) / 25 - 1e-10) = ceil(1500 / 25) = 60
      expect(service.calculateRequiredRecoveryClasses(60, 100, 75.0), 60);

      // 74 / 100 at 75% -> ceil((7500 - 7400) / 25) = ceil(100 / 25) = 4
      expect(service.calculateRequiredRecoveryClasses(74, 100, 75.0), 4);

      // 0 / 4 at 75% -> ceil(300 / 25) = 12
      expect(service.calculateRequiredRecoveryClasses(0, 4, 75.0), 12);

      // 5 / 10 at 75% -> ceil((750 - 500) / 25) = 10
      expect(service.calculateRequiredRecoveryClasses(5, 10, 75.0), 10);
    });

    test('Returns -1 when threshold >= 100 and any class is missed (impossible)', () {
      expect(service.calculateRequiredRecoveryClasses(9, 10, 100.0), -1);
      expect(service.calculateRequiredRecoveryClasses(0, 1, 100.0), -1);
    });

    test('Returns 0 for conducted <= 0 or invalid threshold', () {
      expect(service.calculateRequiredRecoveryClasses(0, 0, 75.0), 0);
      expect(service.calculateRequiredRecoveryClasses(5, 10, 0.0), 0);
    });
  });

  group('DashboardAnalyticsService - Day mapping & Streak logic', () {
    test('toClassDayIndex maps Sunday to 0 and other days correctly', () {
      expect(service.toClassDayIndex(DateTime.sunday), 0);
      expect(service.toClassDayIndex(DateTime.monday), 1);
      expect(service.toClassDayIndex(DateTime.tuesday), 2);
      expect(service.toClassDayIndex(DateTime.wednesday), 3);
      expect(service.toClassDayIndex(DateTime.thursday), 4);
      expect(service.toClassDayIndex(DateTime.friday), 5);
      expect(service.toClassDayIndex(DateTime.saturday), 6);
    });

    test('computeStreak returns 0 if classDays is empty', () {
      final records = [
        AttendanceRecordEntity(
          id: '1',
          date: '2026-11-18',
          subjectId: 'sub_1',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: DateTime(2026, 11, 18),
          updatedAt: DateTime(2026, 11, 18),
        ),
      ];

      expect(service.computeStreak(attendanceRecords: records, classDays: []), 0);
    });

    test('computeStreak counts consecutive class days backwards', () {
      // 2026-11-18 is Wednesday.
      // Class days: Mon(1), Tue(2), Wed(3), Thu(4), Fri(5).
      final ref = DateTime(2026, 11, 18);
      final records = [
        AttendanceRecordEntity(
          id: '1',
          date: '2026-11-18', // Wed
          subjectId: 'sub_1',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
        ),
        AttendanceRecordEntity(
          id: '2',
          date: '2026-11-17', // Tue
          subjectId: 'sub_1',
          sessionId: 's2',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
        ),
        AttendanceRecordEntity(
          id: '3',
          date: '2026-11-16', // Mon
          subjectId: 'sub_1',
          sessionId: 's3',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
        ),
      ];

      final streak = service.computeStreak(
        attendanceRecords: records,
        classDays: [1, 2, 3, 4, 5],
        referenceDate: ref,
      );

      expect(streak, 3);
    });

    test('computeStreak skips weekend days without breaking streak', () {
      // 2026-11-16 is Monday.
      // Attended Friday (2026-11-13) and Monday (2026-11-16).
      // Saturday (14) and Sunday (15) are skipped.
      final ref = DateTime(2026, 11, 16);
      final records = [
        AttendanceRecordEntity(
          id: '1',
          date: '2026-11-16', // Mon
          subjectId: 'sub_1',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
        ),
        AttendanceRecordEntity(
          id: '2',
          date: '2026-11-13', // Fri
          subjectId: 'sub_1',
          sessionId: 's2',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
        ),
      ];

      final streak = service.computeStreak(
        attendanceRecords: records,
        classDays: [1, 2, 3, 4, 5],
        referenceDate: ref,
      );

      expect(streak, 2);
    });

    test('computeStreak skips declared holidays without breaking streak', () {
      // Reference: Wednesday 2026-11-18. Attended Wed (18) and Mon (16).
      // Tuesday 2026-11-17 is a declared holiday.
      final ref = DateTime(2026, 11, 18);
      final records = [
        AttendanceRecordEntity(
          id: '1',
          date: '2026-11-18', // Wed
          subjectId: 'sub_1',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
        ),
        AttendanceRecordEntity(
          id: '2',
          date: '2026-11-16', // Mon
          subjectId: 'sub_1',
          sessionId: 's2',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
        ),
      ];

      final streak = service.computeStreak(
        attendanceRecords: records,
        classDays: [1, 2, 3, 4, 5],
        holidays: {'2026-11-17'},
        referenceDate: ref,
      );

      expect(streak, 2);
    });

    test('computeStreak applies today grace period if today is un-attended', () {
      // Today is Wednesday 2026-11-18 (class day). No class logged yet today.
      // Tuesday 2026-11-17 was attended.
      final ref = DateTime(2026, 11, 18);
      final records = [
        AttendanceRecordEntity(
          id: '1',
          date: '2026-11-17', // Tue
          subjectId: 'sub_1',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
        ),
      ];

      final streak = service.computeStreak(
        attendanceRecords: records,
        classDays: [1, 2, 3, 4, 5],
        referenceDate: ref,
      );

      // Falls back to yesterday without breaking streak -> 1 day
      expect(streak, 1);
    });

    test('computeStreak ignores soft-deleted records', () {
      final ref = DateTime(2026, 11, 18);
      final records = [
        AttendanceRecordEntity(
          id: '1',
          date: '2026-11-18',
          subjectId: 'sub_1',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
          deletedAt: ref, // soft-deleted!
        ),
        AttendanceRecordEntity(
          id: '2',
          date: '2026-11-17',
          subjectId: 'sub_1',
          sessionId: 's2',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
        ),
      ];

      final streak = service.computeStreak(
        attendanceRecords: records,
        classDays: [1, 2, 3, 4, 5],
        referenceDate: ref,
      );

      // 18th is un-attended due to soft delete, grace period falls back to 17th -> 1
      expect(streak, 1);
    });

    test('computeStreak factors in legacy attendance where held == attended', () {
      final ref = DateTime(2026, 11, 18);
      final records = [
        AttendanceRecordEntity(
          id: '1',
          date: '2026-11-18',
          subjectId: 'sub_1',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: ref,
          updatedAt: ref,
        ),
      ];
      final legacy = [
        LegacyAttendanceEntity(
          id: 'leg_1',
          date: '2026-11-17',
          held: 4,
          attended: 4,
          createdAt: ref,
          updatedAt: ref,
        ),
      ];

      final streak = service.computeStreak(
        attendanceRecords: records,
        legacyAttendance: legacy,
        classDays: [1, 2, 3, 4, 5],
        referenceDate: ref,
      );

      expect(streak, 2);
    });
  });

  group('DashboardAnalyticsService - computeOverallStats & computeSubjectStats', () {
    final now = DateTime(2026, 11, 18);
    final mathSub = SubjectEntity(
      id: 'sub_math',
      name: 'Mathematics',
      color: '#3B82F6',
      createdAt: now,
      updatedAt: now,
    );
    final physicsSub = SubjectEntity(
      id: 'sub_phys',
      name: 'Physics',
      color: '#10B981',
      createdAt: now,
      updatedAt: now,
    );

    test('computeOverallStats combines session and legacy attendance', () {
      final records = [
        AttendanceRecordEntity(
          id: 'r1',
          date: '2026-11-18',
          subjectId: 'sub_math',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r2',
          date: '2026-11-18',
          subjectId: 'sub_math',
          sessionId: 's2',
          status: AttendanceStatus.absent,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r3',
          date: '2026-11-17',
          subjectId: 'sub_phys',
          sessionId: 's3',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final legacy = [
        LegacyAttendanceEntity(
          id: 'leg_1',
          date: '2026-11-15',
          held: 5,
          attended: 4,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final stats = service.computeOverallStats(
        attendanceRecords: records,
        legacyAttendance: legacy,
        minPercent: 75.0,
      );

      // Present: 1 (r1) + 1 (r3) + 4 (legacy) = 6
      // Absent: 1 (r2) + 1 (legacy: 5-4) = 2
      // Conducted: 8
      // Percentage: 6 / 8 = 75.0%
      expect(stats.conducted, 8);
      expect(stats.present, 6);
      expect(stats.absent, 2);
      expect(stats.percentage, 75.0);
      expect(stats.isSafe, isTrue);
      expect(stats.canMiss, 0);
      expect(stats.needToAttend, 0);
    });

    test('computeSubjectStats filters by subjectId and ignores soft-deleted records', () {
      final records = [
        AttendanceRecordEntity(
          id: 'r1',
          date: '2026-11-18',
          subjectId: 'sub_math',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r2',
          date: '2026-11-18',
          subjectId: 'sub_math',
          sessionId: 's2',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r3',
          date: '2026-11-18',
          subjectId: 'sub_math',
          sessionId: 's3',
          status: AttendanceStatus.absent,
          createdAt: now,
          updatedAt: now,
          deletedAt: now, // deleted!
        ),
        AttendanceRecordEntity(
          id: 'r4',
          date: '2026-11-18',
          subjectId: 'sub_phys',
          sessionId: 's4',
          status: AttendanceStatus.absent,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final mathStats = service.computeSubjectStats(
        subject: mathSub,
        attendanceRecords: records,
        minPercent: 75.0,
      );

      expect(mathStats.conducted, 2);
      expect(mathStats.present, 2);
      expect(mathStats.absent, 0);
      expect(mathStats.percentage, 100.0);
      expect(mathStats.isSafe, isTrue);

      final physStats = service.computeSubjectStats(
        subject: physicsSub,
        attendanceRecords: records,
        minPercent: 75.0,
      );

      expect(physStats.conducted, 1);
      expect(physStats.present, 0);
      expect(physStats.absent, 1);
      expect(physStats.percentage, 0.0);
      expect(physStats.isSafe, isFalse);
    });

    test('computeAllSubjectStats filters deleted and inactive subjects', () {
      final inactiveSub = SubjectEntity(
        id: 'sub_inact',
        name: 'Inactive',
        active: false,
        createdAt: now,
        updatedAt: now,
      );
      final deletedSub = SubjectEntity(
        id: 'sub_del',
        name: 'Deleted',
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      );

      final allStats = service.computeAllSubjectStats(
        subjects: [mathSub, physicsSub, inactiveSub, deletedSub],
        attendanceRecords: [],
        minPercent: 75.0,
      );

      expect(allStats.length, 2);
      expect(allStats[0].subject.id, 'sub_math');
      expect(allStats[1].subject.id, 'sub_phys');
    });
  });
}
