import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/utils/attendance_calculator.dart';

void main() {
  group('AttendanceCalculator React parity', () {
    test('attendance percentage returns null for zero conducted classes', () {
      expect(AttendanceCalculator.calculateAttendance(0, 0), isNull);
      expect(AttendanceCalculator.calculateAttendance(5, 10), 50.0);
      expect(AttendanceCalculator.calculateAttendance(0, 10), 0.0);
    });

    test('safe bunk math handles exact boundaries and epsilon', () {
      expect(AttendanceCalculator.calculateMaximumAbsences(10, 10, 75), 3);
      expect(AttendanceCalculator.calculateMaximumAbsences(75, 100, 75), 0);
      expect(AttendanceCalculator.calculateMaximumAbsences(76, 100, 75), 1);
      expect(AttendanceCalculator.calculateMaximumAbsences(746, 1000, 75), 0);
      expect(AttendanceCalculator.calculateMaximumAbsences(74, 100, 75), 0);
    });

    test('recovery math returns the minimum integer solution', () {
      expect(AttendanceCalculator.calculateRequiredRecoveryClasses(60, 100, 75), 60);
      expect(AttendanceCalculator.calculateRequiredRecoveryClasses(70, 100, 75), 20);
      expect(AttendanceCalculator.calculateRequiredRecoveryClasses(74, 100, 75), 4);
      expect(AttendanceCalculator.calculateRequiredRecoveryClasses(75, 100, 75), 0);
    });

    test('100 percent recovery is represented as impossible', () {
      expect(AttendanceCalculator.calculateRequiredRecoveryClasses(9, 10, 100), -1);
      expect(AttendanceCalculator.calculateRequiredRecoveryClasses(10, 10, 100), 0);
    });

    test('invalid thresholds and impossible records are rejected safely', () {
      expect(AttendanceCalculator.isValidThreshold(0), isFalse);
      expect(AttendanceCalculator.isValidThreshold(double.nan), isFalse);
      expect(AttendanceCalculator.isValidThreshold(100.01), isFalse);
      expect(AttendanceCalculator.calculateMaximumAbsences(10, 10, 0), 0);
      expect(AttendanceCalculator.calculateMaximumAbsences(11, 10, 75), 0);
      expect(AttendanceCalculator.calculateRequiredRecoveryClasses(5, 10, 101), 0);
    });

    test('projected attendance supports multiple future classes', () {
      expect(
        AttendanceCalculator.calculateProjectedAttendance(
          8,
          10,
          futurePresent: 2,
        ),
        closeTo(83.3333333333, 1e-9),
      );
      expect(
        AttendanceCalculator.calculateProjectedAttendance(
          8,
          10,
          futureAbsent: 2,
        ),
        closeTo(66.6666666667, 1e-9),
      );
      expect(
        AttendanceCalculator.calculateProjectedAttendance(8, 10, futurePresent: -1),
        isNull,
      );
    });
  });
}
