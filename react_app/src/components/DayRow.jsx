import React from 'react';
import { formatDateLabel, todayStr } from '../utils/date';

export default function DayRow({ dateStr, legacyRecord, isToday, isHoliday, onSaveDaily, onDeleteDaily }) {
  const future = dateStr > todayStr();
  const editable = !future && !isHoliday;
  const status = isHoliday ? 'Holiday' : future ? 'Upcoming' : !legacyRecord ? 'Not marked' : legacyRecord.held === 0 ? 'Holiday / No class' : legacyRecord.attended === legacyRecord.held ? 'Present' : legacyRecord.attended === 0 ? 'Absent' : `Partial · ${legacyRecord.attended}/${legacyRecord.held}`;

  return (
    <section className={`day-row ${future ? 'future-row' : ''}`} aria-label={`Attendance for ${formatDateLabel(dateStr)}`}>
      <div className="day-row-main" style={{ cursor: 'default', opacity: future ? 0.65 : 1 }}>
        <div className="day-date">{formatDateLabel(dateStr)}{isToday && <span className="today-tag">today</span>}</div>
        <div className="day-status">{status}</div>
      </div>

      {editable && (
        <div className="custom-editor" style={{ margin: '8px 10px 10px', padding: '12px' }}>
          <div className="card-title" style={{ marginBottom: '12px' }}>Daily attendance</div>
          <div className="quick-actions">
            <button type="button" className="btn-present" onClick={() => onSaveDaily({ date: dateStr, held: 1, attended: 1 })}>Present</button>
            <button type="button" className="btn-absent" onClick={() => onSaveDaily({ date: dateStr, held: 1, attended: 0 })}>Absent</button>
            <button type="button" className="btn-ghost" onClick={() => onSaveDaily({ date: dateStr, held: 0, attended: 0 })}>Holiday / No class</button>
            {legacyRecord && <button type="button" className="btn-clear" onClick={() => onDeleteDaily(legacyRecord.id)}>Clear</button>}
          </div>
        </div>
      )}
    </section>
  );
}
