export function todayStr() {
  return new Date().toLocaleDateString('en-CA');
}

export function addDays(dateStr, n) {
  const d = new Date(dateStr + 'T00:00:00');
  d.setDate(d.getDate() + n);
  return d.toLocaleDateString('en-CA');
}

export function isClassDay(dateStr, classDays) {
  return classDays.includes(new Date(dateStr + 'T00:00:00').getDay());
}

export function dateRangeDesc(startStr, endStr) {
  if (!startStr || !endStr || startStr > endStr) return [];
  const out = [];
  let cur = endStr;
  while (cur >= startStr) {
    out.push(cur);
    cur = addDays(cur, -1);
  }
  return out;
}

export function classDayRangeDesc(startStr, endStr, classDays) {
  return dateRangeDesc(startStr, endStr).filter((d) => isClassDay(d, classDays));
}

export function getPeriodsForDate(dateStr, timetable) {
  if (!timetable) return null;
  const dow = new Date(dateStr + 'T00:00:00').getDay();
  const arr = timetable[dow];
  return arr && arr.length ? arr : null;
}

export function formatDateLabel(dateStr) {
  const d = new Date(dateStr + 'T00:00:00');
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
}

export function formatDateFull(dateStr) {
  const d = new Date(dateStr + 'T00:00:00');
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' });
}
