import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { auth } from '../firebase';
import { DEFAULT_CLASS_DAYS } from '../constants';
import { computeStats, computeStreak } from '../utils/stats';
import { todayStr } from '../utils/date';
import { ATTENDANCE_STATUS, DAILY_SUBJECT_ID, createId, migrateUserData, nowIso } from '../utils/dataModel';
import { flushToCloud, getGlobalSettings, loadUserData, saveLocal, savePreRestoreBackup } from '../services/cloudSync';
import { useReminders } from '../hooks/useReminders';

const AppContext = createContext(null);

export function useApp() {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within AppProvider');
  return context;
}

const toTitleCase = (value) => safeText(value).split(' ').filter(Boolean).map((word) => word[0]?.toUpperCase() + word.slice(1)).join(' ');
const safeText = (value) => typeof value === 'string' ? value.trim() : '';

export function AppProvider({ children }) {
  const [authLoading, setAuthLoading] = useState(true);
  const [user, setUser] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);
  const [globalSettings, setGlobalSettings] = useState({ holidays: {} });
  const [viewMode, setViewMode] = useState('week');
  const [showAdmin, setShowAdmin] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [syncStatus, setSyncStatus] = useState('idle');
  const [theme, setTheme] = useState(() => localStorage.getItem('theme') || 'dark');
  const [showStreakPopup, setShowStreakPopup] = useState(false);
  const [showDrawer, setShowDrawer] = useState(false);
  const [guestMode, setGuestMode] = useState(() => localStorage.getItem('guestMode') === 'true');

  const latestDataRef = useRef(null);
  const isDirtyRef = useRef(false);
  const syncTimerRef = useRef(null);
  const retryCountRef = useRef(0);
  const errorTimerRef = useRef(null);

  const showError = useCallback((message) => {
    setErrorMsg(message);
    if (errorTimerRef.current) clearTimeout(errorTimerRef.current);
    errorTimerRef.current = setTimeout(() => setErrorMsg(''), 5000);
  }, []);

  useEffect(() => {
    document.body.setAttribute('data-theme', theme);
    try {
      localStorage.setItem('theme', theme);
    } catch {
      // Theme preference is non-critical; attendance data has separate error handling.
    }
  }, [theme]);

  const flushNow = useCallback(async () => {
    const snapshot = latestDataRef.current;
    if (!isDirtyRef.current || !user || !snapshot) return true;
    setSyncStatus('syncing');
    try {
      const merged = await flushToCloud(user, snapshot);
      retryCountRef.current = 0;
      if (latestDataRef.current === snapshot) {
        latestDataRef.current = merged;
        setData(merged);
        isDirtyRef.current = false;
      }
      setSyncStatus('synced');
      return true;
    } catch (error) {
      setSyncStatus('error');
      showError('Cloud sync failed. Your latest changes remain on this device.');
      if (retryCountRef.current < 3) {
        const retryDelay = 2000 * (2 ** retryCountRef.current);
        retryCountRef.current += 1;
        if (syncTimerRef.current) clearTimeout(syncTimerRef.current);
        syncTimerRef.current = setTimeout(() => { flushNow(); }, retryDelay);
      }
      return false;
    }
  }, [showError, user]);

  const scheduleSync = useCallback((delay = 1000) => {
    if (!user || !isDirtyRef.current) return;
    if (syncTimerRef.current) clearTimeout(syncTimerRef.current);
    syncTimerRef.current = setTimeout(() => { flushNow(); }, delay);
  }, [flushNow, user]);

  const commitData = useCallback((nextRaw, { settingsChanged = false } = {}) => {
    const current = latestDataRef.current;
    const candidate = typeof nextRaw === 'function' ? nextRaw(current) : nextRaw;
    if (!candidate) return { ok: false, error: 'No attendance data is available.' };
    const timestamp = nowIso();
    const next = migrateUserData({
      ...candidate,
      updatedAt: timestamp,
      ...(settingsChanged ? { settingsUpdatedAt: timestamp } : {}),
    }).data;
    latestDataRef.current = next;
    setData(next);
    isDirtyRef.current = true;
    const uid = user ? user.uid : (guestMode ? 'guest' : null);
    if (!uid) return { ok: false, error: 'No local storage identity is available.' };
    const localResult = saveLocal(uid, next);
    if (!localResult.ok) {
      setSyncStatus('error');
      showError('Device storage failed. Export a backup before continuing.');
      return localResult;
    }
    setSyncStatus(user ? 'pending' : 'local');
    scheduleSync();
    return { ok: true, data: next };
  }, [guestMode, scheduleSync, showError, user]);

  const persist = useCallback((next) => commitData(next, { settingsChanged: true }), [commitData]);
  const saveSettings = useCallback((patch) => commitData((current) => ({ ...current, ...patch }), { settingsChanged: true }), [commitData]);

  const markAttendance = useCallback(({ date, subjectId = DAILY_SUBJECT_ID, sessionId, status, source = 'manual' }) => {
    if (!Object.values(ATTENDANCE_STATUS).includes(status)) return { ok: false, error: 'Invalid attendance status.' };
    return commitData((current) => {
      const timestamp = nowIso();
      const stableSessionId = sessionId || (subjectId === DAILY_SUBJECT_ID ? `daily-${date}` : createId('manual-session'));
      const records = [...(current.attendanceRecords || [])];
      const existingIndex = records.findIndex((record) => (
        !record.deletedAt && record.date === date && record.subjectId === subjectId && record.sessionId === stableSessionId
      ));
      const record = {
        id: existingIndex >= 0 ? records[existingIndex].id : createId('attendance'),
        date,
        subjectId,
        sessionId: stableSessionId,
        status,
        source,
        createdAt: existingIndex >= 0 ? records[existingIndex].createdAt : timestamp,
        updatedAt: timestamp,
        deletedAt: null,
      };
      if (existingIndex >= 0) records[existingIndex] = record;
      else records.push(record);
      return { ...current, attendanceRecords: records };
    });
  }, [commitData]);

  const deleteAttendanceRecord = useCallback((id) => commitData((current) => ({
    ...current,
    attendanceRecords: current.attendanceRecords.map((record) => record.id === id
      ? { ...record, deletedAt: nowIso(), updatedAt: nowIso() }
      : record),
  })), [commitData]);

  const addManualAttendance = useCallback(({ date, subjectId = DAILY_SUBJECT_ID, status }) => markAttendance({
    date,
    subjectId,
    sessionId: subjectId === DAILY_SUBJECT_ID ? `daily-${date}` : createId('manual-session'),
    status,
    source: 'manual',
  }), [markAttendance]);

  const saveDailyAttendance = useCallback(({ date, held, attended }) => {
    const totalHeld = Number(held);
    const totalAttended = Number(attended);
    if (!date || !Number.isInteger(totalHeld) || !Number.isInteger(totalAttended) || totalHeld < 0 || totalAttended < 0 || totalAttended > totalHeld) return { ok: false, error: 'Enter valid daily class totals.' };
    return commitData((current) => {
      const timestamp = nowIso();
      const existingIndex = current.legacyAttendance.findIndex((record) => !record.deletedAt && record.date === date);
      const existing = existingIndex >= 0 ? current.legacyAttendance[existingIndex] : null;
      const record = { id: existing?.id || `daily-${date}`, date, held: totalHeld, attended: totalAttended, createdAt: existing?.createdAt || timestamp, updatedAt: timestamp, deletedAt: null, note: 'Daily attendance' };
      const legacyAttendance = [...current.legacyAttendance];
      if (existingIndex >= 0) legacyAttendance[existingIndex] = record;
      else legacyAttendance.push(record);
      return { ...current, legacyAttendance };
    });
  }, [commitData]);

  const deleteDailyAttendance = useCallback((id) => commitData((current) => ({
    ...current,
    legacyAttendance: current.legacyAttendance.map((record) => record.id === id ? { ...record, deletedAt: nowIso(), updatedAt: nowIso() } : record),
  })), [commitData]);

  const addSubject = useCallback((name) => {
    const subjectName = safeText(name);
    if (!subjectName) return { ok: false, error: 'A subject name is required.' };
    return commitData((current) => ({
      ...current,
      subjects: [...current.subjects, {
        id: createId('subject'), name: subjectName.slice(0, 120), color: '#10B981', active: true,
        createdAt: nowIso(), updatedAt: nowIso(), deletedAt: null,
      }],
    }), { settingsChanged: true });
  }, [commitData]);

  const updateSubject = useCallback((id, patch) => commitData((current) => ({
    ...current,
    subjects: current.subjects.map((subject) => subject.id === id ? {
      ...subject,
      ...patch,
      name: patch.name ? safeText(patch.name).slice(0, 120) : subject.name,
      updatedAt: nowIso(),
    } : subject),
  }), { settingsChanged: true }), [commitData]);

  const addTimetableSession = useCallback((day, subjectId) => commitData((current) => {
    const timestamp = nowIso();
    const subject = current.subjects.find((item) => item.id === subjectId && item.active !== false);
    if (!subject || !Number.isInteger(day) || day < 0 || day > 6) return current;
    const sessions = [...(current.timetable[day] || []), {
      id: createId('schedule'), subjectId, label: subject.name, active: true,
      createdAt: timestamp, updatedAt: timestamp, deletedAt: null,
    }];
    return { ...current, timetable: { ...current.timetable, [day]: sessions } };
  }, { settingsChanged: true }), [commitData]);

  const removeTimetableSession = useCallback((day, id) => commitData((current) => ({
    ...current,
    timetable: {
      ...current.timetable,
      [day]: (current.timetable[day] || []).map((session) => session.id === id
        ? { ...session, active: false, deletedAt: nowIso(), updatedAt: nowIso() }
        : session),
    },
  }), { settingsChanged: true }), [commitData]);

  const resetAll = useCallback(() => commitData((current) => ({
    ...current,
    attendanceRecords: current.attendanceRecords.map((record) => ({ ...record, deletedAt: nowIso(), updatedAt: nowIso() })),
    legacyAttendance: current.legacyAttendance.map((record) => ({ ...record, deletedAt: nowIso(), updatedAt: nowIso() })),
    notes: [],
  }), { settingsChanged: true }), [commitData]);

  const restoreBackup = useCallback((backupData) => {
    const uid = user ? user.uid : (guestMode ? 'guest' : null);
    if (!uid || !latestDataRef.current) return { ok: false, error: 'No active data is available to restore.' };
    const safeguard = savePreRestoreBackup(uid, latestDataRef.current);
    if (!safeguard.ok) return safeguard;
    return commitData(migrateUserData(backupData).data, { settingsChanged: true });
  }, [commitData, guestMode, user]);

  const toggleTheme = useCallback(() => {
    const nextTheme = theme === 'dark' ? 'light' : 'dark';
    setTheme(nextTheme);
    if (latestDataRef.current) saveSettings({ theme: nextTheme });
  }, [saveSettings, theme]);

  // Notifications have one lifecycle inside the provider, avoiding duplicate
  // timers when users visit Settings.
  const notification = useReminders(data, saveSettings, globalSettings);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      setIsAdmin(false);
      if (currentUser) {
        try {
          const token = await currentUser.getIdTokenResult();
          setIsAdmin(token.claims.admin === true);
        } catch {
          setIsAdmin(false);
        }
      }
      setAuthLoading(false);
      if (!currentUser && localStorage.getItem('guestMode') !== 'true') {
        setData(null);
        latestDataRef.current = null;
      }
    });
    return unsubscribe;
  }, []);

  useEffect(() => {
    if (!user && !guestMode) return undefined;
    const uid = user ? user.uid : 'guest';
    let mounted = true;
    (async () => {
      setLoading(true);
      try {
        const result = await loadUserData(uid);
        if (!mounted) return;
        setData(result.data);
        latestDataRef.current = result.data;
        if (result.data?.theme) setTheme(result.data.theme);
        if (result.warnings?.length) showError(result.warnings[0]);
        if (user && result.needsSync && result.data) {
          isDirtyRef.current = true;
          setSyncStatus('pending');
          scheduleSync(0);
        } else {
          setSyncStatus(user ? 'synced' : 'local');
        }
      } catch (error) {
        if (mounted) showError('Unable to load attendance data. Your stored data was left unchanged.');
      } finally {
        if (mounted) setLoading(false);
      }
      try {
        const settings = await getGlobalSettings();
        if (mounted) setGlobalSettings(settings || { holidays: {} });
      } catch {
        // Public holiday data is optional when offline.
      }
    })();
    return () => { mounted = false; };
  }, [guestMode, scheduleSync, showError, user]);

  useEffect(() => {
    const onVisibilityChange = () => {
      if (document.visibilityState === 'hidden') flushNow();
    };
    document.addEventListener('visibilitychange', onVisibilityChange);
    return () => {
      document.removeEventListener('visibilitychange', onVisibilityChange);
      if (syncTimerRef.current) clearTimeout(syncTimerRef.current);
      if (errorTimerRef.current) clearTimeout(errorTimerRef.current);
    };
  }, [flushNow]);

  const stats = useMemo(() => data ? computeStats(data, globalSettings.holidays || {}) : null, [data, globalSettings.holidays]);
  const streak = useMemo(() => data ? computeStreak(data.attendanceRecords, data.classDays || DEFAULT_CLASS_DAYS, globalSettings.holidays || {}, data.legacyAttendance) : 0, [data, globalSettings.holidays]);

  const handleLogout = useCallback(async () => {
    if (user && isDirtyRef.current) {
      const synced = await flushNow();
      if (!synced) {
        showError('Latest changes could not be synced. Please retry before logging out.');
        return false;
      }
    }
    setData(null);
    latestDataRef.current = null;
    isDirtyRef.current = false;
    localStorage.removeItem('guestMode');
    setGuestMode(false);
    if (user) await signOut(auth);
    return true;
  }, [flushNow, showError, user]);

  const value = {
    authLoading, user, isAdmin,
    loading, data, stats, streak, globalSettings, syncStatus,
    viewMode, setViewMode, showAdmin, setShowAdmin, errorMsg, setErrorMsg,
    theme, toggleTheme, showStreakPopup, setShowStreakPopup, showDrawer, setShowDrawer,
    guestMode, setGuestMode, notification,
    persist, saveSettings, markAttendance, deleteAttendanceRecord, addManualAttendance,
    addSubject, updateSubject, addTimetableSession, removeTimetableSession,
    saveDailyAttendance, deleteDailyAttendance,
    resetAll, restoreBackup, handleLogout, flushNow,
    toTitleCase, todayStr,
  };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}
