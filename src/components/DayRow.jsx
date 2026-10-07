import React, { useState, useEffect } from 'react';
import { formatDateLabel } from '../utils/date';
import Stepper from './Stepper';

export default function DayRow({ dateStr, record, isToday, isMainCard, periods, onSave, onClear }) {
  const [expanded, setExpanded] = useState(isMainCard && !record); // Auto-expand main card only if unmarked
  const [held, setHeld] = useState(record ? record.held : 1);
  const [attended, setAttended] = useState(record ? record.attended : 1);
  
  const hasPeriods = periods && periods.length > 0;

  const [periodChecks, setPeriodChecks] = useState(() => {
    if (!hasPeriods) return [];
    if (record) return periods.map((_, i) => i < record.attended);
    return periods.map(() => true);
  });

  useEffect(() => {
    setHeld(record ? record.held : (periods ? periods.length : 1));
    setAttended(record ? record.attended : (periods ? periods.length : 1));
    if (hasPeriods) {
      if (record) {
        setPeriodChecks(periods.map((_, i) => i < record.attended));
      } else {
        setPeriodChecks(periods.map(() => true));
      }
    }
  }, [record, expanded, periods, hasPeriods]);

  const todayStr = new Date().toLocaleDateString('en-CA');
  const isFuture = dateStr > todayStr;

  const openEditor = () => {
    if (isFuture) return;
    setExpanded((e) => !e);
  };

  let rowClass = 'day-row';
  let statusLabel = 'Not marked';
  let statusColor = 'var(--muted)';
  if (isFuture) {
    statusLabel = 'Upcoming';
    statusColor = 'var(--muted)';
  } else if (record) {
    if (record.held === 0) {
      statusLabel = 'Holiday / No class';
      statusColor = 'var(--muted)';
    } else if (record.attended === record.held) {
      statusLabel = record.held > 1 ? `Present · ${record.attended}/${record.held}` : 'Present';
      statusColor = 'var(--ink-green)';
    } else if (record.attended === 0) {
      statusLabel = record.held > 1 ? `Absent · 0/${record.held}` : 'Absent';
      statusColor = 'var(--pen-red)';
    } else {
      statusLabel = `Partial · ${record.attended}/${record.held}`;
      statusColor = 'var(--amber)';
    }
  }

  return (
    <div className={`${rowClass} ${isMainCard ? 'main-card-row' : ''} ${isFuture ? 'future-row' : ''}`}>
      <div className="day-row-main" onClick={openEditor} style={{ cursor: isFuture ? 'default' : 'pointer', opacity: isFuture ? 0.5 : 1 }}>
        <div className="day-date">
          {formatDateLabel(dateStr)}
          {isToday && <span className="today-tag">today</span>}
        </div>
        <div className="day-status" style={{ color: statusColor }}>{statusLabel}</div>
      </div>
      {expanded && (
        <div className="day-editor">
          {hasPeriods && (
            <div className="periods-checklist">
              {periods.map((name, i) => (
                <button
                  key={i}
                  className={`period-chip ${periodChecks[i] ? 'period-chip-present' : 'period-chip-absent'}`}
                  onClick={() => setPeriodChecks((pc) => pc.map((v, idx) => (idx === i ? !v : v)))}
                >
                  {name}
                </button>
              ))}
              <div className="custom-actions">
                <button className="btn-ghost" onClick={() => { onSave(dateStr, 0, 0); setExpanded(false); }}>Holiday</button>
                {record && <button className="btn-clear" onClick={() => { onClear(dateStr); setExpanded(false); }}>Clear</button>}
                <button
                  className="btn-present"
                  onClick={() => {
                    onSave(dateStr, periods.length, periodChecks.filter(Boolean).length);
                    setExpanded(false);
                  }}
                >
                  Save
                </button>
              </div>
            </div>
          )}
          {!hasPeriods && (
            <div className="quick-actions">
              <button className="btn-present" onClick={() => { onSave(dateStr, 1, 1); setExpanded(false); }}>Present</button>
              <button className="btn-absent" onClick={() => { onSave(dateStr, 1, 0); setExpanded(false); }}>Absent</button>
              <button className="btn-ghost" onClick={() => { onSave(dateStr, 0, 0); setExpanded(false); }}>Holiday</button>
              {record && <button className="btn-clear" onClick={() => { onClear(dateStr); setExpanded(false); }}>Clear</button>}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
