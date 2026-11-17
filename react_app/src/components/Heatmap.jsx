import React, { useMemo } from 'react';

function getDates(startDate, daysToAdd) {
  let dates = [];
  for (let i = 0; i < daysToAdd; i++) {
    const d = new Date(startDate);
    d.setDate(d.getDate() + i);
    dates.push(d);
  }
  return dates;
}

function formatDateKey(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

export default function Heatmap({ records = {} }) {
  const WEEKS_TO_SHOW = 26; // Show last half year (better for top-width)
  const today = new Date();
  
  // Calculate start date to align with Sunday
  const startDay = new Date(today);
  startDay.setDate(today.getDate() - (WEEKS_TO_SHOW * 7 - 1) - today.getDay());
  
  const dates = getDates(startDay, WEEKS_TO_SHOW * 7);

  // Group into columns of weeks
  const weeks = [];
  for (let i = 0; i < dates.length; i += 7) {
    weeks.push(dates.slice(i, i + 7));
  }

  const getColorClass = (dateStr) => {
    const r = records[dateStr];
    if (!r) return 'heat-empty';
    if (r.held === 0) return 'heat-holiday';
    if (r.attended === r.held) return 'heat-present';
    if (r.attended === 0) return 'heat-absent';
    return 'heat-partial';
  };

  const getTooltip = (dateStr) => {
    const r = records[dateStr];
    if (!r) return `${dateStr}: Not marked`;
    if (r.held === 0) return `${dateStr}: Holiday`;
    return `${dateStr}: ${r.attended}/${r.held} classes`;
  };

  return (
    <div className="heatmap-container">
      <div className="heatmap-labels-y">
        <span>Mon</span>
        <span>Wed</span>
        <span>Fri</span>
      </div>
      <div className="heatmap-grid-scroll">
        <div className="heatmap-grid">
          {weeks.map((week, wIdx) => (
            <div key={wIdx} className="heatmap-column">
              {week.map((date, dIdx) => {
                const dateStr = formatDateKey(date);
                const isFuture = date > today;
                return (
                  <div 
                    key={dIdx} 
                    className={`heatmap-cell ${isFuture ? 'heat-future' : getColorClass(dateStr)}`}
                    title={isFuture ? '' : getTooltip(dateStr)}
                  />
                );
              })}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
