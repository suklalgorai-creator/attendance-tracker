import { calculateOverallAttendance, calculatePendingScheduledSessions } from './attendance';
import { ATTENDANCE_STATUS } from './dataModel';
import { addDays, isClassDay, todayStr } from './date';

/** Backward-compatible dashboard adapter backed by the single calculation module. */
export function computeStats(data, holidays = {}) {
  const overall = calculateOverallAttendance({
    attendanceRecords: data?.attendanceRecords,
    legacyAttendance: data?.legacyAttendance,
    minPercent: data?.minPercent,
    holidays,
  });
  const unmarkedPastSessions = calculatePendingScheduledSessions({
    attendanceRecords: data?.attendanceRecords,
    timetable: {},
    classDays: data?.classDays,
    startDate: data?.startDate,
    endDate: addDays(todayStr(), -1),
    holidays,
  });
  return { ...overall, unmarkedPastSessions };
}

/** A streak means consecutive class days with at least one explicitly present session. */
export function computeStreak(attendanceRecords = [], classDays = [], holidays = {}, legacyAttendance = []) {
  if (!classDays.length) return 0;
  const presentDates = new Set(attendanceRecords
    .filter((record) => record && !record.deletedAt && record.status === ATTENDANCE_STATUS.PRESENT && !holidays[record.date])
    .map((record) => record.date));
  legacyAttendance.filter((record) => record && !record.deletedAt && record.held > 0 && record.attended === record.held && !holidays[record.date])
    .forEach((record) => presentDates.add(record.date));
  let cursor = todayStr();
  if (!presentDates.has(cursor) && isClassDay(cursor, classDays)) cursor = addDays(cursor, -1);
  let streak = 0;
  let safety = 0;
  while (cursor && safety < 3000) {
    safety += 1;
    if (holidays[cursor] || !isClassDay(cursor, classDays)) {
      cursor = addDays(cursor, -1);
      continue;
    }
    if (!presentDates.has(cursor)) break;
    streak += 1;
    cursor = addDays(cursor, -1);
  }
  return streak;
}
