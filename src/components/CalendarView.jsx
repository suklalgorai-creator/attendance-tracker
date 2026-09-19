import React, { useState } from 'react';

function formatDateKey(year, month, day) {
  return `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

function CalendarView({ records = {}, globalSettings = {} }) {
  const globalHolidays = globalSettings?.holidays || {};
  const [currentDate, setCurrentDate] = useState(new Date());
  
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();
  
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  
  const handlePrev = () => setCurrentDate(new Date(year, month - 1, 1));
  const handleNext = () => setCurrentDate(new Date(year, month + 1, 1));
  
  const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  
  const days = [];
  // padding
  for (let i = 0; i < firstDay; i++) {
    days.push(null);
  }
  for (let i = 1; i <= daysInMonth; i++) {
    days.push(i);
  }
  
  const today = new Date();
  const todayStr = formatDateKey(today.getFullYear(), today.getMonth(), today.getDate());

  const getColorClass = (dateStr) => {
    if (globalHolidays[dateStr]) return 'cal-holiday';
    const r = records[dateStr];
    if (!r) return 'cal-empty';
    if (r.held === 0) return 'cal-holiday';
    if (r.attended === r.held) return 'cal-present';
    if (r.attended === 0) return 'cal-absent';
    return 'cal-partial';
  };

  let monthHeld = 0;
  let monthAttended = 0;
  let monthHolidays = 0;
  
  for (let i = 1; i <= daysInMonth; i++) {
    const dateStr = formatDateKey(year, month, i);
    if (globalHolidays[dateStr]) {
      monthHolidays++;
    } else {
      const r = records[dateStr];
      if (r) {
        if (r.held === 0) {
          monthHolidays++;
        } else {
          monthHeld += r.held;
          monthAttended += r.attended;
        }
      }
    }
  }

  return (
    <div className="calendar-view">
      <div className="calendar-header">
        <button className="icon-btn" onClick={handlePrev}>
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"></polyline></svg>
        </button>
        <span className="calendar-title">{monthNames[month]} {year}</span>
        <button className="icon-btn" onClick={handleNext}>
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 18 15 12 9 6"></polyline></svg>
        </button>
      </div>
      <div className="calendar-grid">
        <div className="cal-day-name">Su</div>
        <div className="cal-day-name">Mo</div>
        <div className="cal-day-name">Tu</div>
        <div className="cal-day-name">We</div>
        <div className="cal-day-name">Th</div>
        <div className="cal-day-name">Fr</div>
        <div className="cal-day-name">Sa</div>
        
        {days.map((d, i) => {
          if (!d) return <div key={i} className="cal-cell empty"></div>;
          const dateStr = formatDateKey(year, month, d);
          const colorClass = getColorClass(dateStr);
          const isToday = dateStr === todayStr;
          
          return (
            <div key={i} className={`cal-cell ${colorClass} ${isToday ? 'today' : ''}`} title={dateStr}>
              {d}
            </div>
          );
        })}
      </div>
      
      <div className="calendar-summary" style={{ display: 'flex', justifyContent: 'space-between', marginTop: '16px', borderTop: '1px dashed var(--rule-bright)', paddingTop: '16px' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '11px', color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '1px', fontWeight: 700, marginBottom: '4px' }}>Held</div>
          <div style={{ fontSize: '20px', fontWeight: 800, color: 'var(--paper)' }}>{monthHeld}</div>
        </div>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '11px', color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '1px', fontWeight: 700, marginBottom: '4px' }}>Attended</div>
          <div style={{ fontSize: '20px', fontWeight: 800, color: 'var(--amber)' }}>{monthAttended}</div>
        </div>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '11px', color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '1px', fontWeight: 700, marginBottom: '4px' }}>Holidays</div>
          <div style={{ fontSize: '20px', fontWeight: 800, color: '#3b82f6' }}>{monthHolidays}</div>
        </div>
      </div>
    </div>
  );
}

export default React.memo(CalendarView);
