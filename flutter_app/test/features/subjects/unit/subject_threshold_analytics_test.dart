import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/dashboard/domain/services/dashboard_analytics_service.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';

void main() {
  const service = DashboardAnalyticsService();
  final now = DateTime(2026, 3, 1, 10, 0);

  group('Subject Threshold Analytics & Overrides Unit Tests', () {
    test(
      'falls back to global minPercent when subject targetPercentage is null',
      () {
        final subject = SubjectEntity(
          id: 'sub_math',
          name: 'Mathematics',
          targetPercentage: null, // No custom override
          createdAt: now,
          updatedAt: now,
        );

        // 15 attended out of 20 conducted -> exactly 75.0%
        final records = List.generate(20, (i) {
          return AttendanceRecordEntity(
            id: 'rec_$i',
            date: '2026-03-${(i + 1).toString().padLeft(2, '0')}',
            subjectId: 'sub_math',
            sessionId: 's_$i',
            status: i < 15 ? AttendanceStatus.present : AttendanceStatus.absent,
            createdAt: now,
            updatedAt: now,
          );
        });

        final stats = service.computeSubjectStats(
          subject: subject,
          attendanceRecords: records,
          minPercent: 75.0,
        );

        expect(stats.conducted, 20);
        expect(stats.present, 15);
        expect(stats.absent, 5);
        expect(stats.percentage, 75.0);
        expect(stats.isSafe, isTrue);
        expect(stats.canMiss, 0);
        expect(stats.needToAttend, 0);
        expect(stats.isImpossible, isFalse);
      },
    );

    test(
      'custom threshold override: higher target than global makes 80% unsafe when target is 85%',
      () {
        final subjectWithOverride = SubjectEntity(
          id: 'sub_chem',
          name: 'Chemistry',
          targetPercentage: 85.0, // Custom higher target
          createdAt: now,
          updatedAt: now,
        );

        // 16 attended out of 20 conducted -> 80.0%
        final records = List.generate(20, (i) {
          return AttendanceRecordEntity(
            id: 'rec_$i',
            date: '2026-03-${(i + 1).toString().padLeft(2, '0')}',
            subjectId: 'sub_chem',
            sessionId: 's_$i',
            status: i < 16 ? AttendanceStatus.present : AttendanceStatus.absent,
            createdAt: now,
            updatedAt: now,
          );
        });

        // Under global 75%: 80% would be safe.
        // Under custom 85%: 80% is unsafe!
        final stats = service.computeSubjectStats(
          subject: subjectWithOverride,
          attendanceRecords: records,
          minPercent: 75.0,
        );

        expect(stats.percentage, 80.0);
        expect(stats.isSafe, isFalse);
        expect(stats.canMiss, 0);
        // Recovery calculation: ((85 * 20) - (100 * 16)) / (100 - 85) = (1700 - 1600) / 15 = 100 / 15 = 6.666 -> 7
        expect(stats.needToAttend, 7);
        expect(stats.isImpossible, isFalse);
      },
    );

    test(
      'custom threshold override: lower target than global makes 70% safe when target is 60%',
      () {
        final subjectWithLower = SubjectEntity(
          id: 'sub_elective',
          name: 'Elective Art',
          targetPercentage: 60.0, // Custom lower target
          createdAt: now,
          updatedAt: now,
        );

        // 14 attended out of 20 conducted -> 70.0%
        final records = List.generate(20, (i) {
          return AttendanceRecordEntity(
            id: 'rec_$i',
            date: '2026-03-${(i + 1).toString().padLeft(2, '0')}',
            subjectId: 'sub_elective',
            sessionId: 's_$i',
            status: i < 14 ? AttendanceStatus.present : AttendanceStatus.absent,
            createdAt: now,
            updatedAt: now,
          );
        });

        // Under global 75%: 70% would be unsafe.
        // Under custom 60%: 70% is safe!
        final stats = service.computeSubjectStats(
          subject: subjectWithLower,
          attendanceRecords: records,
          minPercent: 75.0,
        );

        expect(stats.percentage, 70.0);
        expect(stats.isSafe, isTrue);
        // Safe absences: floor((14 * 100) / 60 - 20 + 1e-10) = floor(23.333 - 20) = 3
        expect(stats.canMiss, 3);
        expect(stats.needToAttend, 0);
        expect(stats.isImpossible, isFalse);
      },
    );

    test(
      'custom threshold 100% becomes impossible once a single class is missed',
      () {
        final subjectPerfect = SubjectEntity(
          id: 'sub_lab',
          name: 'Lab Work',
          targetPercentage: 100.0,
          createdAt: now,
          updatedAt: now,
        );

        final records = [
          AttendanceRecordEntity(
            id: 'r1',
            date: '2026-03-01',
            subjectId: 'sub_lab',
            sessionId: 's1',
            status: AttendanceStatus.present,
            createdAt: now,
            updatedAt: now,
          ),
          AttendanceRecordEntity(
            id: 'r2',
            date: '2026-03-02',
            subjectId: 'sub_lab',
            sessionId: 's2',
            status: AttendanceStatus.absent,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final stats = service.computeSubjectStats(
          subject: subjectPerfect,
          attendanceRecords: records,
          minPercent: 75.0,
        );

        expect(stats.percentage, 50.0);
        expect(stats.isSafe, isFalse);
        expect(stats.isImpossible, isTrue);
        expect(stats.canMiss, 0);
        expect(stats.needToAttend, 0); // impossible flag handles display
      },
    );

    test('zero conducted classes yields null percentage and isSafe true', () {
      final subject = SubjectEntity(
        id: 'sub_new',
        name: 'New Subject',
        targetPercentage: 80.0,
        createdAt: now,
        updatedAt: now,
      );

      final stats = service.computeSubjectStats(
        subject: subject,
        attendanceRecords: [],
        minPercent: 75.0,
      );

      expect(stats.conducted, 0);
      expect(stats.present, 0);
      expect(stats.absent, 0);
      expect(stats.percentage, isNull);
      expect(stats.isSafe, isTrue);
      expect(stats.canMiss, 0);
      expect(stats.needToAttend, 0);
      expect(stats.isImpossible, isFalse);
    });
  });
}
