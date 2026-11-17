import React from 'react';
import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Ring from '../components/Ring';
import { todayStr } from '../utils/date';

const CalendarView = React.lazy(() => import('../components/CalendarView'));

export default function DashboardPage() {
  const { data, stats, streak, globalSettings, syncStatus } = useApp();
  const today = todayStr();
  const holiday = Boolean(globalSettings.holidays?.[today]);
  const statusColor = stats.status === 'safe' ? 'var(--ink-green)' : stats.status === 'danger' ? 'var(--pen-red)' : 'var(--rule)';

  return (
    <div className="dashboard-container">
      {stats.unmarkedPastSessions > 0 && (
        <div className="banner banner-danger" style={{ gridColumn: '1 / -1', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div><strong>Pending attendance</strong><div style={{ fontSize: '13px', marginTop: '4px' }}>{stats.unmarkedPastSessions} scheduled past session{stats.unmarkedPastSessions === 1 ? '' : 's'} still need marking. They are not counted as absences.</div></div>
          <Link to="/register" className="btn-present" style={{ textDecoration: 'none', padding: '8px 16px', fontSize: '13px' }}>Review</Link>
        </div>
      )}

      <div className="card" style={{ gridColumn: '1 / -1', padding: '12px 20px', display: 'flex', justifyContent: 'space-between', gap: '12px', alignItems: 'center' }}>
        <span className="hint" style={{ margin: 0 }}>Sync: {syncStatus === 'synced' ? '✓ Synced' : syncStatus === 'syncing' ? '↻ Syncing…' : syncStatus === 'pending' ? '↻ Changes waiting to sync' : syncStatus === 'error' ? '⚠ Sync failed — stored locally' : 'Local only'}</span>
        <div className="quick-actions" style={{ margin: 0 }}>
          {streak > 0 && <span className="streak">🔥 {streak} present-day streak</span>}
          <Link to="/leaderboard" className="btn-ghost" style={{ textDecoration: 'none', padding: '8px 12px' }}>Leaderboard</Link>
        </div>
      </div>

      {false && (
        <div className="card" style={{ gridColumn: '1 / -1', padding: '16px 20px' }}>
          <div className="card-title" style={{ marginBottom: '12px' }}>Mark Today’s Scheduled Sessions</div>
          <div className="quick-actions">
            <button type="button" className="btn-present" onClick={() => markToday(ATTENDANCE_STATUS.PRESENT)}>Mark all present</button>
            <button type="button" className="btn-absent" onClick={() => markToday(ATTENDANCE_STATUS.ABSENT)}>Mark all absent</button>
            <Link to="/register" className="btn-ghost" style={{ textDecoration: 'none', textAlign: 'center' }}>Review individually</Link>
          </div>
        </div>
      )}
      {holiday && <div className="reminder-banner">Today is marked as a holiday. It does not affect attendance.</div>}

      <div className="dashboard-hero">
        <div className={`card hero-card ${stats.status}`}>
          <Ring percent={stats.attendance} minPercent={data.minPercent} statusColor={statusColor} />
          <div className="hero-stats-list">
            <div className="stat-row"><span className="stat-label">Conducted</span><span className="stat-value">{stats.conducted}</span></div>
            <div className="stat-row"><span className="stat-label">Present</span><span className="stat-value">{stats.present}</span></div>
            <div className="stat-row"><span className="stat-label">Status</span><span className={`stat-value status-text ${stats.status}`}>
              {stats.status === 'none' && 'No attendance recorded'}
              {stats.status === 'safe' && (stats.canMiss === 0 ? 'At the target' : `Can miss ${stats.canMiss} classes`)}
              {stats.status === 'danger' && (stats.impossible ? '100% target is unreachable' : `Need ${stats.needToAttend} attended classes`)}
            </span></div>
          </div>
        </div>
      </div>

      <div className="dashboard-stats">
        <div className="card activity-card">
          <div className="card-title">Activity</div>
          <React.Suspense fallback={<div className="loading">Loading…</div>}>
            <CalendarView attendanceRecords={data.attendanceRecords} legacyAttendance={data.legacyAttendance} globalSettings={globalSettings} />
          </React.Suspense>
        </div>
      </div>
    </div>
  );
}
