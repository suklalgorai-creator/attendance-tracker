import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/dashboard/domain/models/dashboard_stats.dart';
import 'package:flutter_app/features/dashboard/domain/models/subject_attendance_stats.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';

void main() {
  group('DashboardStats Model Tests', () {
    test(
      'DashboardStats.empty() instantiates with zero counts and null percentage',
      () {
        final stats = DashboardStats.empty(minPercent: 80.0);
        expect(stats.conducted, 0);
        expect(stats.present, 0);
        expect(stats.absent, 0);
        expect(stats.percentage, isNull);
        expect(stats.minPercent, 80.0);
        expect(stats.canMiss, 0);
        expect(stats.needToAttend, 0);
        expect(stats.isImpossible, isFalse);
        expect(stats.isSafe, isTrue);
        expect(stats.unmarkedPastSessions, 0);
      },
    );

    test('DashboardStats equality, hashCode and toString', () {
      final stats1 = const DashboardStats(
        conducted: 20,
        present: 18,
        absent: 2,
        percentage: 90.0,
        minPercent: 75.0,
        canMiss: 4,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
        unmarkedPastSessions: 1,
      );

      final stats2 = const DashboardStats(
        conducted: 20,
        present: 18,
        absent: 2,
        percentage: 90.0,
        minPercent: 75.0,
        canMiss: 4,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
        unmarkedPastSessions: 1,
      );

      final stats3 = const DashboardStats(
        conducted: 10,
        present: 5,
        absent: 5,
        percentage: 50.0,
        minPercent: 75.0,
        canMiss: 0,
        needToAttend: 10,
        isImpossible: false,
        isSafe: false,
        unmarkedPastSessions: 0,
      );

      expect(stats1, equals(stats2));
      expect(stats1.hashCode, equals(stats2.hashCode));
      expect(stats1 == stats3, isFalse);
      expect(stats1.toString(), contains('conducted: 20'));
      expect(stats1.toString(), contains('present: 18'));
    });
  });

  group('SubjectAttendanceStats Model Tests', () {
    final now = DateTime(2026, 11, 18);
    final subject = SubjectEntity(
      id: 'sub_1',
      name: 'Mathematics',
      color: '#3B82F6',
      createdAt: now,
      updatedAt: now,
    );

    test('SubjectAttendanceStats equality, hashCode and toString', () {
      final s1 = SubjectAttendanceStats(
        subject: subject,
        conducted: 15,
        present: 12,
        absent: 3,
        percentage: 80.0,
        canMiss: 1,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      final s2 = SubjectAttendanceStats(
        subject: subject,
        conducted: 15,
        present: 12,
        absent: 3,
        percentage: 80.0,
        canMiss: 1,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      final s3 = SubjectAttendanceStats(
        subject: subject,
        conducted: 10,
        present: 5,
        absent: 5,
        percentage: 50.0,
        canMiss: 0,
        needToAttend: 10,
        isImpossible: false,
        isSafe: false,
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1 == s3, isFalse);
      expect(s1.toString(), contains('subject: Mathematics'));
      expect(s1.toString(), contains('conducted: 15'));
    });
  });
}
