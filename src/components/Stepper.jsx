import React from 'react';

export default function Stepper({ value, onChange, min = 0, max = 99 }) {
  return (
    <div className="stepper">
      <button onClick={() => onChange(Math.max(min, value - 1))} aria-label="decrease">−</button>
      <span>{value}</span>
      <button onClick={() => onChange(Math.min(max, value + 1))} aria-label="increase">+</button>
    </div>
  );
}
