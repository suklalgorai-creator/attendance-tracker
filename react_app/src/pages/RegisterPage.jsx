import React, { useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import DayRow from '../components/DayRow';
import { DEFAULT_CLASS_DAYS } from '../constants';
import { todayStr, classDayRangeDesc, getCurrentMonthRangeStr, getCurrentWeekRangeStr } from '../utils/date';

export default function RegisterPage() {
  const {
    data, viewMode, setViewMode, globalSettings, saveDailyAttendance, deleteDailyAttendance,
  } = useApp();
  const today = todayStr();
  const classDays = data.classDays || DEFAULT_CLASS_DAYS;
  const knownDates = useMemo(() => new Set([
    ...(data.attendanceRecords || []).filter((record) => !record.deletedAt).map((record) => record.date),
    ...(data.legacyAttendance || []).filter((record) => !record.deletedAt).map((record) => record.date),
  ]), [data.attendanceRecords, data.legacyAttendance]);
  const fullHistoryRows = [...new Set([...classDayRangeDesc(data.startDate, today, classDays), ...knownDates])].sort().reverse();
  const week = getCurrentWeekRangeStr();
  const month = getCurrentMonthRangeStr();
  const visibleRows = (viewMode === 'all' ? fullHistoryRows : fullHistoryRows.filter((date) => {
    const range = viewMode === 'month' ? month : week;
    return date >= range.start && date <= range.end;
  }));
  const legacyByDate = useMemo(() => new Map((data.legacyAttendance || []).filter((record) => !record.deletedAt).map((record) => [record.date, record])), [data.legacyAttendance]);

  return (
    <div className="dashboard-register">
      <div className="card register-card" style={{ display: 'flex', flexDirection: 'column', height: '100%', marginBottom: 0 }}>
        <div className="card-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>Session Register</span>
          <div className="quick-actions" style={{ margin: 0 }}>
            <Link to="/leaderboard" className="btn-ghost" style={{ textDecoration: 'none', padding: '8px 10px' }}>Leaderboard</Link>
            <div className="view-toggles" aria-label="Register range">
            <button type="button" className={viewMode === 'week' ? 'active' : ''} onClick={() => setViewMode('week')}>Week</button>
            <button type="button" className={viewMode === 'month' ? 'active' : ''} onClick={() => setViewMode('month')}>Month</button>
            <button type="button" className={viewMode === 'all' ? 'active' : ''} onClick={() => setViewMode('all')}>All</button>
            </div>
          </div>
        </div>
        <div className="register-list" style={{ flex: 1 }}>
          {visibleRows.map((date) => (
            <DayRow
              key={date}
              dateStr={date}
              legacyRecord={legacyByDate.get(date)}
              isToday={date === today}
              isHoliday={Boolean(globalSettings.holidays?.[date])}
              onSaveDaily={saveDailyAttendance}
              onDeleteDaily={deleteDailyAttendance}
            />
          ))}
          {visibleRows.length === 0 && <div className="hint">No class dates are available for this range.</div>}
        </div>
      </div>
    </div>
  );
}
