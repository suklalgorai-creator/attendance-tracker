import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { STORAGE_KEY, DEFAULT_MIN, DEFAULT_CLASS_DAYS, BADGES, STREAK_BADGES } from './constants';
import { todayStr, classDayRangeDesc, getPeriodsForDate, isClassDay, formatDateFull, getCurrentWeekRangeStr, getCurrentMonthRangeStr } from './utils/date';
import { computeStats, computeStreak } from './utils/stats';
import Ring from './components/Ring';
import DayPicker from './components/DayPicker';
import TimetableEditor from './components/TimetableEditor';
import Heatmap from './components/Heatmap';
import DayRow from './components/DayRow';
import Auth from './components/Auth';
import AdminDashboard from './components/AdminDashboard';
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
  const [viewMode, setViewMode] = useState('week'); // 'week' | 'month' | 'all'
  const [showAdmin, setShowAdmin] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [theme, setTheme] = useState('light');
  
  const [deferredPrompt, setDeferredPrompt] = useState(null);
  const [showInstallPopup, setShowInstallPopup] = useState(false);
  
  const syncTimeoutRef = useRef(null);

  // Get admin email from .env to hide it from public source code
  const ADMIN_EMAIL = import.meta.env.VITE_ADMIN_EMAIL || '';

  const [formProgram, setFormProgram] = useState('');
  const [formCourse, setFormCourse] = useState('');
  const [formStart, setFormStart] = useState(todayStr());
  const [formMin, setFormMin] = useState(DEFAULT_MIN);
  const [formClassDays, setFormClassDays] = useState(DEFAULT_CLASS_DAYS);

  useEffect(() => {
    document.body.setAttribute('data-theme', theme);
  }, [theme]);

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

  useEffect(() => {
    const handleBeforeInstallPrompt = (e) => {
      e.preventDefault();
      setDeferredPrompt(e);
      if (!localStorage.getItem('hideInstallPopup')) {
        setShowInstallPopup(true);
      }
    };
    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    return () => window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
  }, []);

  const handleInstallApp = async () => {
    if (!deferredPrompt) return;
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === 'accepted') {
      setShowInstallPopup(false);
    }
    setDeferredPrompt(null);
  };

  const handleDismissInstall = () => {
    setShowInstallPopup(false);
    localStorage.setItem('hideInstallPopup', 'true');
  };

  const persist = useCallback(async (next) => {
    setData(next);
    
    try {
      if (window.storage) await window.storage.set(STORAGE_KEY, JSON.stringify(next), false);
    } catch (e) {}

    if (user) {
      if (syncTimeoutRef.current) {
        clearTimeout(syncTimeoutRef.current);
      }
      syncTimeoutRef.current = setTimeout(async () => {
        try {
          await setDoc(doc(db, 'users', user.uid), { ...next, email: user.email });
        } catch (e) {
          setErrorMsg('Cloud sync failed. Data saved locally.');
          setTimeout(() => setErrorMsg(''), 3000);
        }
      }, 5000);
    }
  }, [user]);

  const stats = useMemo(() => {
    if (!data) return null;
    return computeStats(data.records, data.minPercent, data.startDate, data.classDays || DEFAULT_CLASS_DAYS, data.timetable || {});
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
    const s = computeStats(nextRecords, data.minPercent, data.startDate, data.classDays || DEFAULT_CLASS_DAYS, data.timetable || {});
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

  if (showAdmin) {
    return <AdminDashboard onBack={() => setShowAdmin(false)} />;
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
  const fullHistoryRows = classDayRangeDesc(data.startDate, todayStr(), data.classDays);
  const currentWeek = getCurrentWeekRangeStr();
  const weekStart = data.startDate > currentWeek.start ? data.startDate : currentWeek.start;
  const currentWeekRows = classDayRangeDesc(weekStart, currentWeek.end, data.classDays);
  
  const currentMonth = getCurrentMonthRangeStr();
  const monthStart = data.startDate > currentMonth.start ? data.startDate : currentMonth.start;
  const currentMonthRows = classDayRangeDesc(monthStart, currentMonth.end, data.classDays);
  
  const rows = fullHistoryRows; // For stats
  let visibleRows = currentWeekRows;
  if (viewMode === 'month') visibleRows = currentMonthRows;
  if (viewMode === 'all') visibleRows = fullHistoryRows;

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
          <button className="icon-btn" onClick={() => setTheme(t => t === 'dark' ? 'light' : 'dark')} aria-label="Toggle Theme" title="Toggle Light/Dark Mode">
            {theme === 'dark' ? '☀️' : '🌙'}
          </button>

          <button className="profile-btn" onClick={() => setShowSettings((s) => !s)} aria-label="settings" title="Settings & Profile">
            {user.photoURL ? (
              <img src={user.photoURL} alt="Profile" className="profile-pic" referrerPolicy="no-referrer" />
            ) : (
              <div className="profile-fallback">{user.email ? user.email.charAt(0).toUpperCase() : 'U'}</div>
            )}
          </button>
        </div>
      </div>

      {showReminder && (
        <div className="reminder-banner">
          ⏰ Aaj ki attendance abhi tak mark nahi ki{todayPeriods ? ` — ${todayPeriods.length} period${todayPeriods.length === 1 ? '' : 's'} pending` : ''}.
        </div>
      )}

      {showInstallPopup && deferredPrompt && (
        <div className="modal-overlay">
          <div className="card modal-content" style={{ maxWidth: '400px', textAlign: 'center' }}>
            <div className="card-title">Install App</div>
            <p style={{ color: 'var(--paper)', fontSize: '15px', marginBottom: '24px', lineHeight: '1.5' }}>
              Install College Attendance Tracker on your device for a faster, offline experience!
            </p>
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
              <button className="btn-ghost" onClick={handleDismissInstall} style={{ flex: 1 }}>Not Now</button>
              <button className="btn-present" onClick={handleInstallApp} style={{ flex: 1 }}>Install</button>
            </div>
          </div>
        </div>
      )}

      <div className="top-dashboard">
        <div className="card activity-card">
          <div className="card-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span>Activity</span>
            {streak > 0 && <div className="streak" style={{ margin: 0, textTransform: 'none', letterSpacing: 'normal' }}>🔥 {streak} Day Streak</div>}
          </div>
          <Heatmap records={data.records} />
        </div>

        <div className="card badges-card">
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

      <div className="dashboard-grid">
        <div className="dashboard-left">
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

        </div>

        <div className="dashboard-right">
          <div className="card" style={{ display: 'flex', flexDirection: 'column', height: '100%', marginBottom: 0 }}>
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
      </div>

      {showSettings && (
        <div className="modal-overlay" onClick={() => setShowSettings(false)}>
          <div className="card modal-content" onClick={(e) => e.stopPropagation()}>
            <button className="modal-close" onClick={() => setShowSettings(false)}>✕</button>
            <div className="card-title">Profile</div>
            
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: '32px', paddingBottom: '32px', borderBottom: '1px solid var(--rule-bright)' }}>
              <div style={{ width: '88px', height: '88px', borderRadius: '50%', overflow: 'hidden', border: '2px solid var(--glass-border)', marginBottom: '16px', boxShadow: '0 8px 24px rgba(0,0,0,0.1)' }}>
                {user.photoURL ? (
                  <img src={user.photoURL} alt="Profile" style={{ width: '100%', height: '100%', objectFit: 'cover' }} referrerPolicy="no-referrer" />
                ) : (
                  <div style={{ width: '100%', height: '100%', background: 'var(--rule)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '36px', fontWeight: '800', color: 'var(--paper)' }}>
                    {user.email ? user.email.charAt(0).toUpperCase() : 'U'}
                  </div>
                )}
              </div>
              <div style={{ fontSize: '22px', fontWeight: '800', color: 'var(--paper)' }}>{user.displayName || 'Student'}</div>
              <div style={{ fontSize: '15px', color: 'var(--muted)', marginTop: '4px', fontWeight: '500' }}>{user.email}</div>
              
              <div style={{ display: 'flex', gap: '12px', marginTop: '24px', width: '100%' }}>
                <button className="btn-ghost" onClick={handleLogout} style={{ flex: 1 }}>Log Out</button>
                {user.email === ADMIN_EMAIL && (
                  <button className="btn-present" onClick={() => setShowAdmin(true)} style={{ flex: 1 }}>
                    Admin Dashboard
                  </button>
                )}
              </div>
            </div>

            <div className="card-title">App Settings</div>

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
        </div>
      )}

      {errorMsg && <div className="toast">{errorMsg}</div>}
    </div>
  );
}
