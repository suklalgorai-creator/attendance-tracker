import test from 'node:test';
import assert from 'node:assert/strict';
import {
  calculateAttendance,
  calculateMaximumAbsences,
  calculateRequiredRecoveryClasses,
  calculateOverallAttendance,
} from '../src/utils/attendance.js';
import { ATTENDANCE_STATUS, migrateUserData } from '../src/utils/dataModel.js';
import { mergeUserData } from '../src/utils/sync.js';
import { createBackup, parseBackup } from '../src/utils/backup.js';

test('attendance percentage handles zero conducted classes consistently', () => {
  assert.equal(calculateAttendance(0, 0), null);
  assert.equal(calculateAttendance(5, 10), 50);
  assert.equal(calculateAttendance(0, 10), 0);
});

test('safe-to-skip uses precise threshold math', () => {
  assert.equal(calculateMaximumAbsences(10, 10, 75), 3);
  assert.equal(calculateMaximumAbsences(75, 100, 75), 0);
  assert.equal(calculateMaximumAbsences(76, 100, 75), 1);
  assert.equal(calculateMaximumAbsences(746, 1000, 75), 0);
});

test('recovery recommendations use the minimum integer solution', () => {
  assert.equal(calculateRequiredRecoveryClasses(60, 100, 75), 60);
  assert.equal(calculateRequiredRecoveryClasses(70, 100, 75), 20);
  assert.equal(calculateRequiredRecoveryClasses(74, 100, 75), 4);
  assert.equal(calculateRequiredRecoveryClasses(75, 100, 75), 0);
});

test('unmarked, cancelled and holidays do not reduce official attendance', () => {
  const subjects = [{ id: 'math', name: 'Maths' }];
  const records = [
    { id: 'p', date: '2026-10-01', subjectId: 'math', sessionId: 's1', status: ATTENDANCE_STATUS.PRESENT },
    { id: 'a', date: '2026-10-02', subjectId: 'math', sessionId: 's2', status: ATTENDANCE_STATUS.ABSENT },
    { id: 'u', date: '2026-10-03', subjectId: 'math', sessionId: 's3', status: ATTENDANCE_STATUS.UNMARKED },
    { id: 'c', date: '2026-10-04', subjectId: 'math', sessionId: 's4', status: ATTENDANCE_STATUS.CANCELLED },
    { id: 'h', date: '2026-10-05', subjectId: 'math', sessionId: 's5', status: ATTENDANCE_STATUS.ABSENT },
  ];
  const normalized = migrateUserData({ schemaVersion: 2, subjects, attendanceRecords: records }).data;
  const result = calculateOverallAttendance({
    attendanceRecords: normalized.attendanceRecords,
    minPercent: 75,
    holidays: { '2026-10-05': 'Holiday' },
  });
  assert.deepEqual({ present: result.present, absent: result.absent, conducted: result.conducted }, { present: 1, absent: 1, conducted: 2 });
  assert.equal(result.attendance, 50);
});

test('invalid records are quarantined and valid records survive migration', () => {
  const result = migrateUserData({
    schemaVersion: 2,
    subjects: [{ id: 'math', name: 'Maths' }],
    attendanceRecords: [
      { id: 'valid', date: '2026-10-01', subjectId: 'math', sessionId: 's1', status: 'PRESENT' },
      { id: 'bad-status', date: '2026-10-01', subjectId: 'math', sessionId: 's2', status: 'UNKNOWN' },
      { id: 'bad-date', date: 'not-a-date', subjectId: 'math', sessionId: 's3', status: 'ABSENT' },
      { id: 'bad-subject', date: '2026-10-01', subjectId: 'missing', sessionId: 's4', status: 'ABSENT' },
    ],
  });
  assert.equal(result.data.attendanceRecords.length, 1);
  assert.equal(result.quarantineCount, 3);
});

test('multiple classes on one date coexist independently', () => {
  const result = migrateUserData({
    schemaVersion: 2,
    subjects: [{ id: 'math', name: 'Maths' }, { id: 'physics', name: 'Physics' }],
    attendanceRecords: [
      { id: 'one', date: '2026-10-01', subjectId: 'math', sessionId: 'math-1', status: 'PRESENT' },
      { id: 'two', date: '2026-10-01', subjectId: 'physics', sessionId: 'physics-1', status: 'ABSENT' },
    ],
  }).data;
  assert.equal(result.attendanceRecords.length, 2);
  assert.deepEqual(result.attendanceRecords.map((record) => record.subjectId).sort(), ['math', 'physics']);
});

test('daily attendance works without a subject', () => {
  const data = migrateUserData({
    schemaVersion: 2,
    attendanceRecords: [
      { id: 'daily-1', date: '2026-10-01', sessionId: 'daily-2026-10-01', status: 'PRESENT' },
      { id: 'daily-2', date: '2026-10-02', sessionId: 'daily-2026-10-02', status: 'ABSENT' },
    ],
  }).data;
  assert.equal(data.attendanceRecords[0].subjectId, '__daily__');
  const result = calculateOverallAttendance({ attendanceRecords: data.attendanceRecords, minPercent: 75 });
  assert.deepEqual({ present: result.present, absent: result.absent, conducted: result.conducted }, { present: 1, absent: 1, conducted: 2 });
});

test('sync keeps the newest entity and preserves deletions', () => {
  const base = { schemaVersion: 2, subjects: [{ id: 'math', name: 'Maths' }] };
  const local = {
    ...base,
    updatedAt: '2026-10-07T10:05:00.000Z',
    attendanceRecords: [{ id: 'r1', date: '2026-10-01', subjectId: 'math', sessionId: 's1', status: 'PRESENT', updatedAt: '2026-10-05T10:05:00.000Z' }],
  };
  const cloud = {
    ...base,
    updatedAt: '2026-10-07T10:03:00.000Z',
    attendanceRecords: [{ id: 'r1', date: '2026-10-01', subjectId: 'math', sessionId: 's1', status: 'ABSENT', updatedAt: '2026-10-05T10:03:00.000Z' }],
  };
  assert.equal(mergeUserData(local, cloud).attendanceRecords[0].status, 'PRESENT');
  const deleted = { ...local, attendanceRecords: [{ ...local.attendanceRecords[0], deletedAt: '2026-10-06T10:00:00.000Z', updatedAt: '2026-10-06T10:00:00.000Z' }] };
  assert.equal(mergeUserData(deleted, cloud).attendanceRecords[0].deletedAt, '2026-10-06T10:00:00.000Z');
});

test('backup round-trip validates data before restore', () => {
  const backup = createBackup({ schemaVersion: 2, subjects: [{ id: 'math', name: 'Maths' }] });
  const parsed = parseBackup(JSON.stringify(backup));
  assert.equal(parsed.summary.subjects, 1);
  assert.throws(() => parseBackup('{"format":"wrong","data":{}}'), /not a College Attendance Tracker backup/);
  assert.throws(() => parseBackup(JSON.stringify({ ...backup, schemaVersion: 999 })), /newer app version/);
});
