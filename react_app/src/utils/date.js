/** Date-only helpers. Attendance dates are always YYYY-MM-DD in local calendar time. */
export function formatDateKey(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

export function parseDateOnly(dateStr) {
  if (typeof dateStr !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return null;
  const [year, month, day] = dateStr.split('-').map(Number);
  const date = new Date(year, month - 1, day);
  if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) return null;
  return date;
}

export function isDateOnly(dateStr) {
  return parseDateOnly(dateStr) !== null;
}

export function todayStr() {
  return formatDateKey(new Date());
}

export function addDays(dateStr, n) {
  const date = parseDateOnly(dateStr);
  if (!date || !Number.isInteger(n)) return null;
  date.setDate(date.getDate() + n);
  return formatDateKey(date);
}

export function isClassDay(dateStr, classDays) {
  const date = parseDateOnly(dateStr);
  return Boolean(date && Array.isArray(classDays) && classDays.includes(date.getDay()));
}

export function dateRangeDesc(startStr, endStr) {
  if (!isDateOnly(startStr) || !isDateOnly(endStr) || startStr > endStr) return [];
  const out = [];
  let cursor = endStr;
  let safety = 0;
  while (cursor >= startStr && safety < 3000) {
    out.push(cursor);
    cursor = addDays(cursor, -1);
    safety += 1;
  }
  return out;
}

export function getCurrentWeekRangeStr() {
  const monday = new Date();
  const day = monday.getDay();
  monday.setDate(monday.getDate() - (day === 0 ? 6 : day - 1));
  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);
  return { start: formatDateKey(monday), end: formatDateKey(sunday) };
}

export function getCurrentMonthRangeStr() {
  const current = new Date();
  const firstDay = new Date(current.getFullYear(), current.getMonth(), 1);
  const lastDay = new Date(current.getFullYear(), current.getMonth() + 1, 0);
  return { start: formatDateKey(firstDay), end: formatDateKey(lastDay) };
}

export function classDayRangeDesc(startStr, endStr, classDays) {
  return dateRangeDesc(startStr, endStr).filter((date) => isClassDay(date, classDays));
}

export function getPeriodsForDate(dateStr, timetable) {
  const date = parseDateOnly(dateStr);
  if (!date || !timetable) return [];
  const sessions = timetable[date.getDay()];
  return Array.isArray(sessions) ? sessions : [];
}

export function formatDateLabel(dateStr) {
  const date = parseDateOnly(dateStr);
  return date ? date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }) : dateStr;
}

export function formatDateFull(dateStr) {
  const date = parseDateOnly(dateStr);
  return date ? date.toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' }) : dateStr;
}
