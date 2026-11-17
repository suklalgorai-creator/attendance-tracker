import React, { useMemo, useState } from 'react';
import { ATTENDANCE_STATUS } from '../utils/dataModel';
import { formatDateKey } from '../utils/date';

function CalendarView({ attendanceRecords = [], legacyAttendance = [], globalSettings = {} }) {
  const [currentDate, setCurrentDate] = useState(new Date());
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();
  const holidays = globalSettings.holidays || {};
  const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const today = formatDateKey(new Date());
  const byDate = useMemo(() => attendanceRecords.filter((record) => !record.deletedAt).reduce((map, record) => {
    (map[record.date] ||= []).push(record);
    return map;
  }, {}), [attendanceRecords]);
  const legacyByDate = useMemo(() => new Map(legacyAttendance.filter((record) => !record.deletedAt).map((record) => [record.date, record])), [legacyAttendance]);

  const daySummary = (date) => {
    if (holidays[date]) return { type: 'holiday', held: 0, attended: 0 };
    const records = byDate[date] || [];
    const held = records.filter((record) => record.status === ATTENDANCE_STATUS.PRESENT || record.status === ATTENDANCE_STATUS.ABSENT);
    const attended = held.filter((record) => record.status === ATTENDANCE_STATUS.PRESENT).length;
    const legacy = legacyByDate.get(date);
    const totalHeld = held.length + (legacy?.held || 0);
    const totalAttended = attended + (legacy?.attended || 0);
    if (records.some((record) => record.status === ATTENDANCE_STATUS.CANCELLED) && totalHeld === 0) return { type: 'holiday', held: 0, attended: 0 };
    if (totalHeld === 0) return { type: 'empty', held: 0, attended: 0 };
    if (totalAttended === totalHeld) return { type: 'present', held: totalHeld, attended: totalAttended };
    if (totalAttended === 0) return { type: 'absent', held: totalHeld, attended: 0 };
    return { type: 'partial', held: totalHeld, attended: totalAttended };
  };

  const summary = Array.from({ length: daysInMonth }, (_, index) => daySummary(formatDateKey(new Date(year, month, index + 1))))
    .reduce((total, day) => ({
      held: total.held + day.held,
      attended: total.attended + day.attended,
      holidays: total.holidays + (day.type === 'holiday' ? 1 : 0),
    }), { held: 0, attended: 0, holidays: 0 });

  return (
    <div className="calendar-view">
      <div className="calendar-header">
        <button type="button" className="icon-btn" aria-label="Previous month" onClick={() => setCurrentDate(new Date(year, month - 1, 1))}>‹</button>
        <span className="calendar-title">{monthNames[month]} {year}</span>
        <button type="button" className="icon-btn" aria-label="Next month" onClick={() => setCurrentDate(new Date(year, month + 1, 1))}>›</button>
      </div>
      <div className="calendar-grid">
        {['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((day) => <div key={day} className="cal-day-name">{day}</div>)}
        {Array.from({ length: firstDay }, (_, index) => <div key={`pad-${index}`} className="cal-cell empty" />)}
        {Array.from({ length: daysInMonth }, (_, index) => {
          const day = index + 1;
          const date = formatDateKey(new Date(year, month, day));
          const current = daySummary(date);
          return <div key={date} className={`cal-cell cal-${current.type} ${date === today ? 'today' : ''}`} title={`${date}: ${current.type === 'empty' ? 'No attendance recorded' : `${current.attended}/${current.held} attended`}`}>{day}</div>;
        })}
      </div>
      <div className="calendar-summary" style={{ display: 'flex', justifyContent: 'space-between', marginTop: '16px', borderTop: '1px dashed var(--rule-bright)', paddingTop: '16px' }}>
        <div style={{ textAlign: 'center' }}><div className="stat-label">Conducted</div><div className="stat-value">{summary.held}</div></div>
        <div style={{ textAlign: 'center' }}><div className="stat-label">Present</div><div className="stat-value">{summary.attended}</div></div>
        <div style={{ textAlign: 'center' }}><div className="stat-label">Holidays</div><div className="stat-value">{summary.holidays}</div></div>
      </div>
    </div>
  );
}

export default React.memo(CalendarView);
