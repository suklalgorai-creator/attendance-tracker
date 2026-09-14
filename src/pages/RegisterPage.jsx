import React from 'react';
import { useApp } from '../context/AppContext';
import DayRow from '../components/DayRow';
import { DEFAULT_CLASS_DAYS } from '../constants';
import { todayStr, classDayRangeDesc, getPeriodsForDate, getCurrentWeekRangeStr, getCurrentMonthRangeStr } from '../utils/date';

export default function RegisterPage() {
  const { data, viewMode, setViewMode, markDay, clearDay } = useApp();

  const timetable = data.timetable || {};
  const fullHistoryRows = classDayRangeDesc(data.startDate, todayStr(), data.classDays);
  const currentWeek = getCurrentWeekRangeStr();
  const weekStart = data.startDate > currentWeek.start ? data.startDate : currentWeek.start;
  const currentWeekRows = classDayRangeDesc(weekStart, currentWeek.end, data.classDays);

  const currentMonth = getCurrentMonthRangeStr();
  const monthStart = data.startDate > currentMonth.start ? data.startDate : currentMonth.start;
  const currentMonthRows = classDayRangeDesc(monthStart, currentMonth.end, data.classDays);

  let visibleRows = currentWeekRows;
  if (viewMode === 'month') visibleRows = currentMonthRows;
  if (viewMode === 'all') visibleRows = fullHistoryRows;

  // Reorder so that Today and past days are at the top, and future days are at the bottom.
  const today = todayStr();
  const pastAndToday = visibleRows.filter(d => d <= today);
  const future = visibleRows.filter(d => d > today).reverse();
  visibleRows = [...pastAndToday, ...future];

  return (
    <div className="dashboard-register">
      <div className="card register-card" style={{ display: 'flex', flexDirection: 'column', height: '100%', marginBottom: 0 }}>
        <div className="card-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>Register</span>
          <div className="view-toggles">
            <button className={viewMode === 'week' ? 'active' : ''} onClick={() => setViewMode('week')}>Week</button>
            <button className={viewMode === 'month' ? 'active' : ''} onClick={() => setViewMode('month')}>Month</button>
            <button className={viewMode === 'all' ? 'active' : ''} onClick={() => setViewMode('all')}>All</button>
          </div>
        </div>
        <div className="register-list" style={{ flex: 1 }}>
          {visibleRows.map((d) => (
            <DayRow
              key={d}
              dateStr={d}
              record={data.records[d]}
              isToday={d === todayStr()}
              isMainCard={d === todayStr()}
              periods={getPeriodsForDate(d, timetable)}
              onSave={markDay}
              onClear={clearDay}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
