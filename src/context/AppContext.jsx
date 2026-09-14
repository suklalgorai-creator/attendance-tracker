import React, { createContext, useContext, useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { auth } from '../firebase';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { STORAGE_KEY, DEFAULT_MIN, DEFAULT_CLASS_DAYS } from '../constants';
import { computeStats, computeStreak } from '../utils/stats';
import { todayStr } from '../utils/date';
import { loadUserData, saveLocal, flushToCloud } from '../services/cloudSync';

const AppContext = createContext(null);

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}

const toTitleCase = (str) => {
  if (!str) return '';
  return str.split(' ').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ');
};

export function AppProvider({ children }) {
  const [authLoading, setAuthLoading] = useState(true);
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);
  const [viewMode, setViewMode] = useState('week');
  const [showAdmin, setShowAdmin] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [theme, setTheme] = useState(() => {
    return localStorage.getItem('theme') || 'dark';
  });
  const [showStreakPopup, setShowStreakPopup] = useState(false);
  const [showDrawer, setShowDrawer] = useState(false);

  const syncTimeoutRef = useRef(null);
  const isDirtyRef = useRef(false);
  const latestDataRef = useRef(null);

  const ADMIN_EMAIL = import.meta.env.VITE_ADMIN_EMAIL || '';

  // Theme
  useEffect(() => {
    document.body.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  // Auth listener
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
      setAuthLoading(false);
      if (!currentUser) setData(null);
    });
    return unsubscribe;
  }, []);

  // Load data
  useEffect(() => {
    if (!user) return;
    let isMounted = true;
    (async () => {
      setLoading(true);
      try {
        const result = await loadUserData(user.uid);
        if (isMounted) {
          setData(result);
          latestDataRef.current = result;
          if (result && result.theme) setTheme(result.theme);
        }
      } catch (err) {
        console.error("Failed to load user data:", err);
        if (isMounted) setErrorMsg("Data load error. Retrying...");
      } finally {
        if (isMounted) setLoading(false);
      }
    })();
    return () => { isMounted = false; };
  }, [user]);

  // Flush to cloud
  const doFlush = useCallback(async () => {
    if (!isDirtyRef.current || !user || !latestDataRef.current) return;
    isDirtyRef.current = false;
    try {
      await flushToCloud(user.uid, user.email, latestDataRef.current);
    } catch (e) {
      isDirtyRef.current = true;
      setErrorMsg('Cloud sync failed. Data saved locally.');
      setTimeout(() => setErrorMsg(''), 3000);
    }
  }, [user]);

  // Auto-sync on tab hide / close
  useEffect(() => {
    const onHide = () => { if (document.visibilityState === 'hidden') doFlush(); };
    const onUnload = () => doFlush();
    document.addEventListener('visibilitychange', onHide);
    window.addEventListener('beforeunload', onUnload);
    return () => {
      document.removeEventListener('visibilitychange', onHide);
      window.removeEventListener('beforeunload', onUnload);
    };
  }, [doFlush]);

  // Persist (write local + schedule cloud sync)
  const persist = useCallback((next) => {
    setData(next);
    latestDataRef.current = next;
    isDirtyRef.current = true;
    
    if (user) {
      saveLocal(user.uid, next);
      if (syncTimeoutRef.current) clearTimeout(syncTimeoutRef.current);
      syncTimeoutRef.current = setTimeout(() => doFlush(), 30000);
    }
  }, [user, doFlush]);

  // Computed values
  const stats = useMemo(() => {
    if (!data) return null;
    return computeStats(data.records, data.minPercent, data.startDate, data.classDays || DEFAULT_CLASS_DAYS, data.timetable || {});
  }, [data]);

  const streak = useMemo(
    () => (data ? computeStreak(data.records, data.classDays || DEFAULT_CLASS_DAYS) : 0),
    [data]
  );

  // Actions
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

  const toggleTheme = () => {
    const next = theme === 'dark' ? 'light' : 'dark';
    setTheme(next);
    if (data) {
      persist({ ...data, theme: next });
    }
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
      theme: theme,
    });
  };

  const handleLogout = () => {
    setData(null);
    latestDataRef.current = null;
    isDirtyRef.current = false;
    signOut(auth);
  };

  const value = {
    // Auth
    authLoading, user, ADMIN_EMAIL,
    // Data
    loading, data, stats, streak,
    // UI State
    viewMode, setViewMode,
    showAdmin, setShowAdmin,
    errorMsg, setErrorMsg,
    theme, toggleTheme,
    showStreakPopup, setShowStreakPopup,
    showDrawer, setShowDrawer,
    // Actions
    persist, markDay, clearDay, saveSettings, resetAll, handleLogout,
    // Helpers
    toTitleCase,
  };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}
