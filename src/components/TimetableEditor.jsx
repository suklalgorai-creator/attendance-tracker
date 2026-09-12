import React from 'react';

export default function TimetableEditor({ classDays, timetable, onChangeDay }) {
  const dayName = (i) => ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][i];
  return (
    <div className="timetable-editor">
      {classDays.slice().sort().map((d) => (
        <div key={d} className="timetable-row">
          <span className="timetable-day">{dayName(d)}</span>
          <input
            defaultValue={(timetable[d] || []).join(', ')}
            placeholder="e.g. Maths, Physics, Chem"
            onBlur={(e) => {
              const names = e.target.value.split(',').map((s) => s.trim()).filter(Boolean);
              onChangeDay(d, names);
            }}
          />
        </div>
      ))}
    </div>
  );
}
