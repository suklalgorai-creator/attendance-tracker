import { todayStr, addDays, isClassDay, classDayRangeDesc, getPeriodsForDate } from './date';

export function computeStats(records, minPercent, startDate, classDays = [1,2,3,4,5], timetable = {}) {
  const today = todayStr();
  let totalHeld = 0;
  let totalAttended = 0;
  let unmarkedPastDays = 0;
  
  const expectedDates = classDayRangeDesc(startDate, today, classDays);
  
  expectedDates.forEach(date => {
    const r = records[date];
    if (r) {
      totalHeld += r.held;
      totalAttended += r.attended;
    } else {
      const periods = getPeriodsForDate(date, timetable);
      totalHeld += (periods ? periods.length : 1);
      if (date < today) {
        unmarkedPastDays++;
      }
    }
  });
  const currentPercent = totalHeld === 0 ? null : (totalAttended / totalHeld) * 100;
  let status = 'none';
  let value = 0;
  let impossible = false;

  if (totalHeld > 0) {
    if (currentPercent >= minPercent) {
      status = 'safe';
      value = Math.max(0, Math.floor((totalAttended * 100) / minPercent - totalHeld));
    } else {
      status = 'danger';
      if (minPercent >= 100) {
        impossible = true;
      } else {
        value = Math.ceil((minPercent * totalHeld - 100 * totalAttended) / (100 - minPercent));
      }
    }
  }
  return { totalHeld, totalAttended, currentPercent, status, value, impossible, unmarkedPastDays };
}

export function computeStreak(records, classDays) {
  let streak = 0;
  let cursor = todayStr();
  if (!records[cursor] && isClassDay(cursor, classDays)) cursor = addDays(cursor, -1);
  while (true) {
    if (!isClassDay(cursor, classDays)) {
      cursor = addDays(cursor, -1);
      continue;
    }
    if (!records[cursor]) break;
    streak += 1;
    cursor = addDays(cursor, -1);
  }
  return streak;
}
