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
  let safety = 0;
  while (cur >= startStr && safety < 3000) { // Limit to ~8 years to prevent freeze
    out.push(cur);
    const d = new Date(cur + 'T00:00:00');
    if (isNaN(d)) break;
    d.setDate(d.getDate() - 1);
    cur = d.toLocaleDateString('en-CA');
    safety++;
  }
  return out;
}

export function getCurrentWeekRangeStr() {
  const d = new Date();
  const day = d.getDay();
  const diffToMonday = d.getDate() - day + (day === 0 ? -6 : 1);
  
  const monday = new Date(d.getTime());
  monday.setDate(diffToMonday);
  
  const sunday = new Date(monday.getTime());
  sunday.setDate(sunday.getDate() + 6);
  
  return {
    start: monday.toLocaleDateString('en-CA'),
    end: sunday.toLocaleDateString('en-CA')
  };
}

export function getCurrentMonthRangeStr() {
  const d = new Date();
  const firstDay = new Date(d.getFullYear(), d.getMonth(), 1);
  const lastDay = new Date(d.getFullYear(), d.getMonth() + 1, 0);
  
  return {
    start: firstDay.toLocaleDateString('en-CA'),
    end: lastDay.toLocaleDateString('en-CA')
  };
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
