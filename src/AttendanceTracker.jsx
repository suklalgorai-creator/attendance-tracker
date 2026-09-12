import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { STORAGE_KEY, DEFAULT_MIN, DEFAULT_CLASS_DAYS, BADGES, STREAK_BADGES } from './constants';
import { todayStr, classDayRangeDesc, getPeriodsForDate, isClassDay, formatDateFull } from './utils/date';
import { computeStats, computeStreak } from './utils/stats';
import Ring from './components/Ring';
import DayPicker from './components/DayPicker';
import TimetableEditor from './components/TimetableEditor';
import DayRow from './components/DayRow';
import Auth from './components/Auth';
import { CSS } from './styles';

import { auth, db } from './firebase';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';

export default function AttendanceTracker() {
  const [authLoading, setAuthLoading] = useState(true);
  const [user, setUser] = useState(null);

  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);
  const [showSettings, setShowSettings] = useState(false);
  const [showAllHistory, setShowAllHistory] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const [formProgram, setFormProgram] = useState('');
  const [formCourse, setFormCourse] = useState('');
  const [formStart, setFormStart] = useState(todayStr());
  const [formMin, setFormMin] = useState(DEFAULT_MIN);
  const [formClassDays, setFormClassDays] = useState(DEFAULT_CLASS_DAYS);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
      setAuthLoading(false);
      if (!currentUser) {
        setData(null);
      }
    });
    return unsubscribe;
  }, []);

  useEffect(() => {
    if (!user) return;
    
    let isMounted = true;
    (async () => {
      setLoading(true);
      try {
        const docRef = doc(db, 'users', user.uid);
        const docSnap = await getDoc(docRef);
        
        if (docSnap.exists() && isMounted) {
          setData(docSnap.data());
        } else {
          // fallback / migration
          const res = window.storage ? await window.storage.get(STORAGE_KEY, false) : null;
          if (res && res.value && isMounted) {
            setData(JSON.parse(res.value));
          } else if (isMounted) {
            setData(null);
          }
        }
      } catch (e) {
        try {
          const res = window.storage ? await window.storage.get(STORAGE_KEY, false) : null;
          if (res && res.value && isMounted) setData(JSON.parse(res.value));
        } catch(err) {}
      } finally {
        if (isMounted) setLoading(false);
      }
    })();
    return () => { isMounted = false; };
  }, [user]);

  const persist = useCallback(async (next) => {
    setData(next);
    
    try {
      if (window.storage) await window.storage.set(STORAGE_KEY, JSON.stringify(next), false);
    } catch (e) {}

    if (user) {
      try {
        await setDoc(doc(db, 'users', user.uid), next);
      } catch (e) {
        setErrorMsg('Cloud sync failed. Data saved locally.');
        setTimeout(() => setErrorMsg(''), 3000);
      }
    }
  }, [user]);

  const stats = useMemo(() => {
    if (!data) return null;
    return computeStats(data.records, data.minPercent, data.startDate);
  }, [data]);

  const streak = useMemo(
    () => (data ? computeStreak(data.records, data.classDays || DEFAULT_CLASS_DAYS) : 0),
    [data]
  );

  const handleOnboard = () => {
    const next = {
      programName: formProgram.trim(),
      courseName: formCourse.trim(),
      startDate: formStart,
      minPercent: Math.max(1, Math.min(100, Number(formMin) || DEFAULT_MIN)),
      classDays: formClassDays.length ? formClassDays : DEFAULT_CLASS_DAYS,
      records: {},
      bestPercent: 0,
    };
    persist(next);
  };

  const markDay = (dateStr, held, attended) => {
    const nextRecords = { ...data.records, [dateStr]: { held, attended } };
    const s = computeStats(nextRecords, data.minPercent, data.startDate);
    let bestPercent = data.bestPercent || 0;
    if (s.currentPercent !== null && s.totalHeld >= 5 && s.currentPercent > bestPercent) {
      bestPercent = s.currentPercent;
    }
    persist({ ...data, records: nextRecords, bestPercent });
  };

  const clearDay = (dateStr) => {
    const nextRecords = { ...data.records };
    delete nextRecords[dateStr];
    persist({ ...data, records: nextRecords });
  };

  const saveSettings = (patch) => {
    persist({ ...data, ...patch });
  };

  const resetAll = () => {
    persist({
      programName: data.programName,
      courseName: data.courseName,
      startDate: data.startDate,
      minPercent: data.minPercent,
      classDays: data.classDays || DEFAULT_CLASS_DAYS,
      timetable: data.timetable || {},
      reminderTime: data.reminderTime || '18:00',
      records: {},
      bestPercent: 0,
    });
    setShowSettings(false);
  };

  const handleLogout = () => {
    signOut(auth);
    setShowSettings(false);
  };

  if (authLoading) {
    return (
      <div className="app-root">
        <style>{CSS}</style>
        <div className="loading">Authenticating…</div>
      </div>
    );
  }

  if (!user) {
    return <Auth />;
  }

  if (loading) {
    return (
      <div className="app-root">
        <style>{CSS}</style>
        <div className="loading">Syncing from cloud…</div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="app-root">
        <style>{CSS}</style>
        <div className="onboard">
          <h1>Set up your register</h1>
          <p className="onboard-sub">A daily attendance tracker that shows exactly how safe — or how behind — you are.</p>
          <label className="field">
            <span>Degree / Program name (optional)</span>
            <input value={formProgram} onChange={(e) => setFormProgram(e.target.value)} placeholder="e.g. B.Tech CSE" />
          </label>
          <label className="field">
            <span>Semester name (optional)</span>
            <input value={formCourse} onChange={(e) => setFormCourse(e.target.value)} placeholder="e.g. Semester 3" />
          </label>
          <label className="field">
            <span>Classes started on</span>
            <input type="date" value={formStart} onChange={(e) => setFormStart(e.target.value)} max={todayStr()} />
          </label>
          <label className="field">
            <span>Minimum attendance required</span>
            <div className="min-row">
              <input type="number" min="1" max="100" value={formMin} onChange={(e) => setFormMin(e.target.value)} />
              <span>%</span>
            </div>
          </label>
          <label className="field">
            <span>Which days do you have class?</span>
            <DayPicker value={formClassDays} onChange={setFormClassDays} />
          </label>
          <button className="btn-present btn-wide" onClick={handleOnboard}>Start tracking</button>
        </div>
      </div>
    );
  }

  const statusColor = stats.status === 'safe' ? 'var(--ink-green)' : stats.status === 'danger' ? 'var(--pen-red)' : 'var(--rule)';
  const classDays = data.classDays || DEFAULT_CLASS_DAYS;
  const timetable = data.timetable || {};
  const rows = classDayRangeDesc(data.startDate, todayStr(), classDays);
  const visibleRows = showAllHistory ? rows : rows.slice(0, 10);

  const today = todayStr();
  const reminderTime = data.reminderTime || '18:00';
  const [rh, rm] = reminderTime.split(':').map(Number);
  const now = new Date();
  const nowMinutes = now.getHours() * 60 + now.getMinutes();
  const reminderMinutes = (rh || 0) * 60 + (rm || 0);
  const todayPeriods = getPeriodsForDate(today, timetable);
  const showReminder = isClassDay(today, classDays) && !data.records[today] && nowMinutes >= reminderMinutes;

  return (
    <div className="app-root">
      <style>{CSS}</style>

      <div className="header">
        <div>
          <div className="eyebrow">{data.programName || 'Attendance Register'}</div>
          <div className="course-name">{data.courseName || 'My Classes'}</div>
        </div>
        <div className="header-right">
          {streak > 0 && <div className="streak">🔥 {streak}</div>}
          <button className="icon-btn" onClick={() => setShowSettings((s) => !s)} aria-label="settings">⚙</button>
        </div>
      </div>

      {showReminder && (
        <div className="reminder-banner">
          ⏰ Aaj ki attendance abhi tak mark nahi ki{todayPeriods ? ` — ${todayPeriods.length} period${todayPeriods.length === 1 ? '' : 's'} pending` : ''}.
        </div>
      )}

      <div className={`card hero-card ${stats.status}`}>
        <Ring percent={stats.currentPercent} minPercent={data.minPercent} statusColor={statusColor} />
        <div className="hero-sub" style={{ lineHeight: '1.5' }}>
          since {formatDateFull(data.startDate)}<br />
          Attended <strong>{stats.totalAttended}</strong> / <strong>{stats.totalHeld}</strong> classes
        </div>
      </div>

      <div className={`banner banner-${stats.status}`}>
        {stats.status === 'none' && <span>Mark your first class below to see where you stand.</span>}
        {stats.status === 'safe' && (
          stats.value === 0
            ? <span>Right at the edge — one more miss drops you below {data.minPercent}%.</span>
            : <span>Safe. You can miss <strong>{stats.value}</strong> more class{stats.value === 1 ? '' : 'es'} and stay ≥ {data.minPercent}%.</span>
        )}
        {stats.status === 'danger' && (
          stats.impossible
            ? <span>{data.minPercent}% is no longer reachable — you've already missed a class. Consider a lower target.</span>
            : <span>Below target. Attend the next <strong>{stats.value}</strong> class{stats.value === 1 ? '' : 'es'} in a row to reach {data.minPercent}%.</span>
        )}
      </div>

      <div className="card">
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

      <div className="card">
        <div className="card-title">Register</div>
        <div className="register-list">
          {visibleRows.map((d) => (
            <DayRow
              key={d}
              dateStr={d}
              record={data.records[d]}
              isToday={d === todayStr()}
              periods={getPeriodsForDate(d, timetable)}
              onSave={markDay}
              onClear={clearDay}
            />
          ))}
        </div>
        {rows.length > 10 && (
          <button className="btn-ghost btn-wide" onClick={() => setShowAllHistory((v) => !v)}>
            {showAllHistory ? 'Show less' : `Show all ${rows.length} days`}
          </button>
        )}
      </div>

      {showSettings && (
        <div className="card">
          <div className="card-title">Settings</div>
          
          <div style={{ marginBottom: '20px', paddingBottom: '20px', borderBottom: '1px solid var(--rule-bright)' }}>
            <div style={{ fontSize: '13px', color: 'var(--muted)', marginBottom: '8px' }}>Account</div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ fontSize: '15px', fontWeight: '500' }}>{user.email}</div>
              <button className="btn-clear" onClick={handleLogout} style={{ padding: '6px 12px' }}>Log Out</button>
            </div>
          </div>

          <label className="field">
            <span>Degree / Program name</span>
            <input value={data.programName || ''} onChange={(e) => saveSettings({ programName: e.target.value })} />
          </label>
          <label className="field">
            <span>Semester name</span>
            <input value={data.courseName || ''} onChange={(e) => saveSettings({ courseName: e.target.value })} />
          </label>
          <label className="field">
            <span>Classes started on</span>
            <input type="date" value={data.startDate} max={todayStr()} onChange={(e) => saveSettings({ startDate: e.target.value })} />
          </label>
          <label className="field">
            <span>Minimum attendance required</span>
            <div className="min-row">
              <input type="number" min="1" max="100" value={data.minPercent} onChange={(e) => saveSettings({ minPercent: Math.max(1, Math.min(100, Number(e.target.value) || DEFAULT_MIN)) })} />
              <span>%</span>
            </div>
          </label>
          <label className="field">
            <span>Which days do you have class?</span>
            <DayPicker
              value={data.classDays || DEFAULT_CLASS_DAYS}
              onChange={(v) => saveSettings({ classDays: v.length ? v : DEFAULT_CLASS_DAYS })}
            />
          </label>
          <label className="field">
            <span>Weekly timetable (optional — powers the period checklist when marking)</span>
            <TimetableEditor
              classDays={data.classDays || DEFAULT_CLASS_DAYS}
              timetable={data.timetable || {}}
              onChangeDay={(day, names) => saveSettings({ timetable: { ...(data.timetable || {}), [day]: names } })}
            />
          </label>
          <label className="field">
            <span>Remind me if not marked by</span>
            <input type="time" value={data.reminderTime || '18:00'} onChange={(e) => saveSettings({ reminderTime: e.target.value })} />
            <span className="hint">Shows a banner when you open the app after this time — can't send a push notification outside the app.</span>
          </label>
          <button className="btn-clear btn-wide" onClick={resetAll} style={{ marginTop: '24px', borderColor: 'rgba(239, 68, 68, 0.3)', color: '#f87171' }}>Reset all data</button>
        </div>
      )}

      {errorMsg && <div className="toast">{errorMsg}</div>}
    </div>
  );
}
