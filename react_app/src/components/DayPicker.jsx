import React from 'react';
import { DAY_LABELS } from '../constants';

export default function DayPicker({ value, onChange }) {
  const toggle = (i) => {
    const next = value.includes(i) ? value.filter((d) => d !== i) : [...value, i].sort();
    onChange(next);
  };
  return (
    <div className="day-picker">
      {DAY_LABELS.map((label, i) => (
        <button
          key={i}
          type="button"
          className={`day-chip ${value.includes(i) ? 'day-chip-on' : ''}`}
          onClick={() => toggle(i)}
        >
          {label}
        </button>
      ))}
    </div>
  );
}
