import React from 'react';

export function polarToCartesian(cx, cy, r, angleDeg) {
  const a = (angleDeg * Math.PI) / 180;
  return { x: cx + r * Math.cos(a), y: cy + r * Math.sin(a) };
}

export default function Ring({ percent, minPercent, statusColor }) {
  const cx = 100, cy = 100, r = 82, sw = 14;
  const circumference = 2 * Math.PI * r;
  const pct = percent === null ? 0 : Math.max(0, Math.min(100, percent));
  const dashoffset = circumference * (1 - pct / 100);
  const thresholdAngle = -90 + (minPercent / 100) * 360;
  const inner = polarToCartesian(cx, cy, r - 11, thresholdAngle);
  const outer = polarToCartesian(cx, cy, r + 11, thresholdAngle);

  return (
    <svg viewBox="0 0 200 200" width="220" height="220">
      <circle cx={cx} cy={cy} r={r} fill="none" stroke="var(--rule)" strokeWidth={sw} />
      <circle
        cx={cx} cy={cy} r={r} fill="none"
        stroke={statusColor} strokeWidth={sw} strokeLinecap="round"
        strokeDasharray={circumference} strokeDashoffset={dashoffset}
        transform={`rotate(-90 ${cx} ${cy})`}
        style={{ transition: 'stroke-dashoffset 700ms cubic-bezier(.4,0,.2,1), stroke 400ms ease' }}
      />
      <line x1={inner.x} y1={inner.y} x2={outer.x} y2={outer.y} stroke="var(--amber)" strokeWidth={3} strokeLinecap="round" />
      <text x={cx} y={cy - 6} textAnchor="middle" fontSize="40" fontFamily="'Outfit', sans-serif" fontWeight="700" fill="var(--paper)">
        {percent === null ? '—' : Math.round(percent * 10) / 10}
        {percent !== null && <tspan fontSize="20">%</tspan>}
      </text>
      <text x={cx} y={cy + 22} textAnchor="middle" fontSize="12" fill="var(--muted)" letterSpacing="0.5" fontFamily="'Outfit', sans-serif">
        target {minPercent}%
      </text>
    </svg>
  );
}
