import React from 'react';
import { useApp } from '../context/AppContext';
import Ring from '../components/Ring';
import { BADGES, STREAK_BADGES } from '../constants';
import { Link } from 'react-router-dom';

import { todayStr, isClassDay } from '../utils/date';

const CalendarView = React.lazy(() => import('../components/CalendarView'));

export default function DashboardPage() {
  const { data, stats, streak, markDay } = useApp();

  const statusColor = stats.status === 'safe' ? 'var(--ink-green)' : stats.status === 'danger' ? 'var(--pen-red)' : 'var(--rule)';
  const today = todayStr();
  const isTodayClassDay = isClassDay(today, data.classDays || [1,2,3,4,5]);
  const todayRecord = data.records[today];

  return (
    <div className="dashboard-container">
      {stats.unmarkedPastDays > 0 && (
        <div className="banner banner-danger" style={{ gridColumn: '1 / -1', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <strong>Missing Attendance</strong>
            <div style={{ fontSize: '13px', marginTop: '4px' }}>You have {stats.unmarkedPastDays} past class days that haven't been marked.</div>
          </div>
          <Link to="/register" className="btn-present" style={{ textDecoration: 'none', padding: '8px 16px', fontSize: '13px' }}>Update Now</Link>
        </div>
      )}

      {isTodayClassDay && !todayRecord && (
        <div className="card" style={{ gridColumn: '1 / -1', padding: '16px 20px' }}>
          <div className="card-title" style={{ marginBottom: '12px' }}>Mark Today's Attendance</div>
          <div className="quick-actions">
            <button className="btn-present" onClick={() => markDay(today, 1, 1)}>Present</button>
            <button className="btn-absent" onClick={() => markDay(today, 1, 0)}>Absent</button>
            <button className="btn-ghost" onClick={() => markDay(today, 0, 0)}>Holiday</button>
          </div>
        </div>
      )}

      <div className="dashboard-hero">
        <div className={`card hero-card ${stats.status}`}>
          <Ring percent={stats.currentPercent} minPercent={data.minPercent} statusColor={statusColor} />
          <div className="hero-stats-list">
            <div className="stat-row">
              <span className="stat-label">Classes Held</span>
              <span className="stat-value">{stats.totalHeld}</span>
            </div>
            <div className="stat-row">
              <span className="stat-label">Attended</span>
              <span className="stat-value">{stats.totalAttended}</span>
            </div>
            <div className="stat-row">
              <span className="stat-label">Status</span>
              <span className={`stat-value status-text ${stats.status}`}>
                {stats.status === 'none' && 'No data yet'}
                {stats.status === 'safe' && (stats.value === 0 ? 'Right at the edge' : `Safe to skip ${stats.value} classes`)}
                {stats.status === 'danger' && (stats.impossible ? 'Target unreachable' : `Need ${stats.value} more classes`)}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div className="dashboard-stats">
        <div className="card activity-card">
          <div className="card-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span>Activity</span>
          </div>
          <React.Suspense fallback={<div className="loading">Loading...</div>}>
            <CalendarView records={data.records} />
          </React.Suspense>
        </div>

        <div className="card badges-card" style={{ display: 'none' }}>
          <div className="card-title">Badges</div>
          <div className="badges-row">
            {BADGES.map((b) => {
              const unlocked = (data.bestPercent || 0) >= b.min;
              return (
                <div key={b.id} className="badge" style={{ opacity: unlocked ? 1 : 0.35 }}>
                  <div className="badge-dot" style={{ background: unlocked ? b.color : 'var(--rule)' }} />
                  <span>{b.label}</span>
                </div>
              );
            })}
            {STREAK_BADGES.map((b) => {
              const unlocked = streak >= b.min;
              return (
                <div key={b.id} className="badge" style={{ opacity: unlocked ? 1 : 0.35 }}>
                  <div className="badge-dot" style={{ background: unlocked ? 'var(--amber)' : 'var(--rule)' }} />
                  <span>{b.label}</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
