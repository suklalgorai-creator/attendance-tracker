import React, { useState } from 'react';

const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export default function TimetableEditor({ classDays, timetable, subjects, onAddSession, onRemoveSession }) {
  const activeSubjects = subjects.filter((subject) => subject.active !== false);
  const [selected, setSelected] = useState({});
  const subjectById = new Map(subjects.map((subject) => [subject.id, subject]));

  return (
    <div className="timetable-editor">
      {classDays.slice().sort().map((day) => {
        const sessions = (timetable[day] || []).filter((session) => session.active !== false && !session.deletedAt);
        const value = selected[day] || activeSubjects[0]?.id || '';
        return (
          <div key={day} className="timetable-row" style={{ alignItems: 'flex-start' }}>
            <span className="timetable-day">{dayNames[day]}</span>
            <div style={{ flex: 1, display: 'grid', gap: '8px' }}>
              {sessions.map((session) => (
                <div key={session.id} className="custom-row" style={{ background: 'var(--input-bg)', padding: '8px 12px', borderRadius: '10px' }}>
                  <span>{subjectById.get(session.subjectId)?.name || session.label || 'Unknown subject'}</span>
                  <button type="button" className="icon-btn" aria-label={`Remove ${session.label || 'session'}`} onClick={() => onRemoveSession(day, session.id)}>×</button>
                </div>
              ))}
              {activeSubjects.length > 0 ? (
                <div style={{ display: 'flex', gap: '8px' }}>
                  <select value={value} onChange={(event) => setSelected((current) => ({ ...current, [day]: event.target.value }))} style={{ flex: 1 }}>
                    {activeSubjects.map((subject) => <option key={subject.id} value={subject.id}>{subject.name}</option>)}
                  </select>
                  <button type="button" className="btn-present" onClick={() => onAddSession(day, value)}>Add session</button>
                </div>
              ) : <span className="hint">Create a subject first.</span>}
            </div>
          </div>
        );
      })}
    </div>
  );
}
