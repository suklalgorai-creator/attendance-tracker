import { ATTENDANCE_STATUS } from './dataModel.js';
import { classDayRangeDesc, todayStr } from './date.js';
import { getSessionsForDate } from './dataModel.js';

export function isValidThreshold(value) {
  return Number.isFinite(value) && value > 0 && value <= 100;
}

export function calculateAttendance(present, conducted) {
  if (!Number.isFinite(present) || !Number.isFinite(conducted) || conducted <= 0 || present < 0 || present > conducted) return null;
  return (present / conducted) * 100;
}

export function calculateMaximumAbsences(present, conducted, threshold) {
  if (!isValidThreshold(threshold) || !Number.isFinite(present) || !Number.isFinite(conducted) || conducted <= 0) return null;
  const attendance = calculateAttendance(present, conducted);
  if (attendance === null || attendance < threshold) return 0;
  return Math.max(0, Math.floor((present * 100) / threshold - conducted + 1e-10));
}

export function calculateRequiredRecoveryClasses(present, conducted, threshold) {
  if (!isValidThreshold(threshold) || !Number.isFinite(present) || !Number.isFinite(conducted) || conducted <= 0) return null;
  const attendance = calculateAttendance(present, conducted);
  if (attendance === null || attendance >= threshold) return 0;
  if (threshold >= 100) return Infinity;
  return Math.max(0, Math.ceil(((threshold * conducted) - (100 * present)) / (100 - threshold) - 1e-10));
}

export function calculateProjectedAttendance(present, conducted, futurePresent = 0, futureAbsent = 0) {
  if (![present, conducted, futurePresent, futureAbsent].every(Number.isFinite)) return null;
  return calculateAttendance(present + futurePresent, conducted + futurePresent + futureAbsent);
}

function isConductedStatus(status) {
  return status === ATTENDANCE_STATUS.PRESENT || status === ATTENDANCE_STATUS.ABSENT;
}

export function summarizeAttendanceRecords(records = [], { subjectId, holidays = {} } = {}) {
  return records.reduce((summary, record) => {
    if (!record || record.deletedAt || (subjectId && record.subjectId !== subjectId) || holidays[record.date]) return summary;
    if (record.status === ATTENDANCE_STATUS.PRESENT) {
      summary.present += 1;
      summary.conducted += 1;
    } else if (record.status === ATTENDANCE_STATUS.ABSENT) {
      summary.absent += 1;
      summary.conducted += 1;
    } else if (record.status === ATTENDANCE_STATUS.CANCELLED) {
      summary.cancelled += 1;
    } else if (record.status === ATTENDANCE_STATUS.UNMARKED) {
      summary.unmarked += 1;
    }
    return summary;
  }, { present: 0, absent: 0, conducted: 0, cancelled: 0, unmarked: 0 });
}

export function summarizeLegacyAttendance(records = [], holidays = {}) {
  return records.reduce((summary, record) => {
    if (!record || record.deletedAt || holidays[record.date]) return summary;
    summary.present += record.attended;
    summary.absent += record.held - record.attended;
    summary.conducted += record.held;
    return summary;
  }, { present: 0, absent: 0, conducted: 0, cancelled: 0, unmarked: 0 });
}

export function calculateOverallAttendance({ attendanceRecords = [], legacyAttendance = [], minPercent, holidays = {} } = {}) {
  const current = summarizeAttendanceRecords(attendanceRecords, { holidays });
  const legacy = summarizeLegacyAttendance(legacyAttendance, holidays);
  const present = current.present + legacy.present;
  const absent = current.absent + legacy.absent;
  const conducted = current.conducted + legacy.conducted;
  const attendance = calculateAttendance(present, conducted);
  const safe = attendance !== null && attendance >= minPercent;
  return {
    present,
    absent,
    conducted,
    cancelled: current.cancelled,
    unmarked: current.unmarked,
    attendance,
    status: attendance === null ? 'none' : safe ? 'safe' : 'danger',
    canMiss: safe ? calculateMaximumAbsences(present, conducted, minPercent) : 0,
    needToAttend: safe ? 0 : calculateRequiredRecoveryClasses(present, conducted, minPercent),
    impossible: !safe && minPercent >= 100,
  };
}

export function calculateSubjectAttendance(subjectId, options = {}) {
  const summary = summarizeAttendanceRecords(options.attendanceRecords || [], { subjectId, holidays: options.holidays || {} });
  const attendance = calculateAttendance(summary.present, summary.conducted);
  const safe = attendance !== null && attendance >= options.minPercent;
  return {
    ...summary,
    attendance,
    status: attendance === null ? 'none' : safe ? 'safe' : 'danger',
    canMiss: safe ? calculateMaximumAbsences(summary.present, summary.conducted, options.minPercent) : 0,
    needToAttend: safe ? 0 : calculateRequiredRecoveryClasses(summary.present, summary.conducted, options.minPercent),
    impossible: !safe && options.minPercent >= 100,
  };
}

export function calculatePendingScheduledSessions({ attendanceRecords = [], timetable = {}, classDays = [], startDate, endDate = todayStr(), holidays = {} } = {}) {
  if (!startDate) return 0;
  const recordByDateAndSession = new Map(
    attendanceRecords.filter((record) => record && !record.deletedAt).map((record) => [`${record.date}:${record.sessionId}`, record]),
  );
  return classDayRangeDesc(startDate, endDate, classDays).reduce((pending, date) => {
    if (holidays[date]) return pending;
    return pending + getSessionsForDate(timetable, date).filter((session) => {
      const record = recordByDateAndSession.get(`${date}:${session.id}`);
      return !record || record.status === ATTENDANCE_STATUS.UNMARKED;
    }).length;
  }, 0);
}

export function isConductedAttendanceRecord(record) {
  return Boolean(record && !record.deletedAt && isConductedStatus(record.status));
}
