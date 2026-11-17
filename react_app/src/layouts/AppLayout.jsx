import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { useInstallPrompt } from '../hooks/useInstallPrompt';
import { useMediaQuery } from '../hooks/useMediaQuery';
import { todayStr, isClassDay } from '../utils/date';
import { DAILY_SUBJECT_ID } from '../utils/dataModel';
import Auth from '../components/Auth';
import DrawerMenu from '../components/DrawerMenu';
import StreakPopup from '../components/StreakPopup';
import InstallPopup from '../components/InstallPopup';
import DashboardPage from '../pages/DashboardPage';
import RegisterPage from '../pages/RegisterPage';
import SettingsPage from '../pages/SettingsPage';
import OnboardingPage from '../pages/OnboardingPage';
import NotesPage from '../pages/NotesPage';
import LeaderboardPage from '../pages/LeaderboardPage';
import DesktopLayout from './DesktopLayout';

import MobileLayout from './MobileLayout';

const AdminDashboard = React.lazy(() => import('../components/AdminDashboard'));

export default function AppLayout() {
  const {
    authLoading, user, isAdmin, loading, data,
    showAdmin, setShowAdmin,
    errorMsg, streak, globalSettings,
    theme, toggleTheme,
    showStreakPopup, setShowStreakPopup,
    showDrawer, setShowDrawer,
    guestMode, setGuestMode,
    saveSettings, notification,
  } = useApp();

  const { showInstallPopup, deferredPrompt, handleInstall, handleDismiss } = useInstallPrompt();
  
  // Check if desktop
  const isDesktop = useMediaQuery('(min-width: 1024px)');

  // Loading states
  if (authLoading) {
    return (
      <div className="app-root">
        <div className="loading">Authenticating…</div>
      </div>
    );
  }

  if (!user && !guestMode) {
    return <Auth />;
  }

  if (showAdmin && isAdmin) {
    return (
      <React.Suspense fallback={<div className="loading">Loading...</div>}>
        <AdminDashboard onBack={() => setShowAdmin(false)} />
      </React.Suspense>
    );
  }

  if (loading) {
    return (
      <div className="app-root">
        <div className="loading">Syncing from cloud…</div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="app-root">
        <OnboardingPage />
      </div>
    );
  }

  // Reminder logic
  const today = todayStr();
  const reminderTime = data.reminderTime || '18:00';
  const [rh, rm] = reminderTime.split(':').map(Number);
  const now = new Date();
  const nowMinutes = now.getHours() * 60 + now.getMinutes();
  const reminderMinutes = (rh || 0) * 60 + (rm || 0);
  const todaySessions = [];
  const todayRecords = data.attendanceRecords?.filter((record) => !record.deletedAt && record.date === today) || [];
  const markedSessionIds = new Set(todayRecords
    .filter((record) => ['PRESENT', 'ABSENT', 'CANCELLED'].includes(record.status))
    .map((record) => record.sessionId));
  const dailyLegacy = data.legacyAttendance?.find((record) => !record.deletedAt && record.date === today);
  const dailyMarked = Boolean(dailyLegacy) || todayRecords.some((record) => record.subjectId === DAILY_SUBJECT_ID && ['PRESENT', 'ABSENT', 'CANCELLED'].includes(record.status));
  const pendingToday = todaySessions.length > 0
    ? todaySessions.filter((session) => !markedSessionIds.has(session.id))
    : (data.startDate && today >= data.startDate && isClassDay(today, data.classDays) && !dailyMarked ? [{ id: `daily-${today}` }] : []);
  const showReminder = pendingToday.length > 0 && !globalSettings.holidays?.[today] && nowMinutes >= reminderMinutes;

  const ActiveLayout = isDesktop ? DesktopLayout : MobileLayout;

  return (
    <div className="app-root">
      <ActiveLayout>
        {/* Header */}
        <div className="header">
          <div className="header-left">
            {!isDesktop && (
              <button className="hamburger-btn" onClick={() => setShowDrawer(true)} aria-label="Menu" title="Menu">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <line x1="3" y1="12" x2="21" y2="12"></line>
                  <line x1="3" y1="6" x2="21" y2="6"></line>
                  <line x1="3" y1="18" x2="21" y2="18"></line>
                </svg>
              </button>
            )}
            <div>
              <div className="eyebrow">
                {data.programName || 'Attendance Register'}
                {data.courseName && ` • ${data.courseName}`}
              </div>
              <div className="course-name">My Attendance</div>
            </div>
          </div>
          <div className="header-right" style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            {isDesktop && (
              <button className="icon-btn" style={{ width: '40px', height: '40px', fontSize: '18px' }} onClick={toggleTheme} title="Toggle Theme">
                {theme === 'dark' ? '☀️' : '🌙'}
              </button>
            )}
            {streak > 0 && (
              <button className="streak-badge-btn" onClick={() => setShowStreakPopup(true)}>
                <span className="streak-fire">🔥</span>
                <span className="streak-num">{streak}</span>
              </button>
            )}
          </div>
        </div>

        {/* Reminder */}
        {showReminder && (
          <div className="reminder-banner">
            ⏰ Today&apos;s attendance is not marked — {pendingToday.length} scheduled session{pendingToday.length === 1 ? '' : 's'} pending.
          </div>
        )}

        {/* Guest Banner */}
        {!user && guestMode && (
          <div className="reminder-banner" style={{ backgroundColor: 'var(--amber)', color: '#000', cursor: 'pointer' }} onClick={() => {
            localStorage.removeItem('guestMode');
            setGuestMode(false);
          }}>
            ⚠️ Data not backed up! <b>Tap here to Sign in</b> and save your attendance in the cloud.
          </div>
        )}

        {/* Modals */}
        {showInstallPopup && deferredPrompt && (
          <InstallPopup onInstall={handleInstall} onDismiss={handleDismiss} />
        )}

        {showStreakPopup && (
          <StreakPopup streak={streak} onClose={() => setShowStreakPopup(false)} />
        )}

        {data?.adminRequestedPush && notification.permission !== 'granted' && (
          <div className="modal-overlay" style={{ zIndex: 99999 }}>
            <div className="modal-content" style={{ textAlign: 'center', maxWidth: '320px' }}>
              <div style={{ fontSize: '48px', marginBottom: '16px', animation: 'fireBurn 2s infinite' }}>🔔</div>
              <h3 style={{ margin: '0 0 12px 0', fontSize: '20px', fontWeight: 800, color: 'var(--paper)' }}>Stay on Track!</h3>
              <p style={{ color: 'var(--muted)', fontSize: '15px', marginBottom: '24px', lineHeight: 1.5 }}>
                Enable push notifications to get timely updates and auto-reminders of your attendance, especially when your days become busy!
              </p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <button 
                  className="btn-present"
                  style={{ width: '100%' }}
                  onClick={() => {
                    notification.requestPermission();
                    saveSettings({ adminRequestedPush: false, pushNotificationsEnabled: true });
                  }}
                >
                  Enable Notifications
                </button>
                <button 
                  className="btn-ghost" 
                  style={{ width: '100%' }}
                  onClick={() => saveSettings({ adminRequestedPush: false })}
                >
                  Maybe Later
                </button>
              </div>
            </div>
          </div>
        )}

        {showDrawer && !isDesktop && (
          <DrawerMenu 
            data={data} 
            onClose={() => setShowDrawer(false)} 
            canInstall={!!deferredPrompt}
            onInstall={() => { setShowDrawer(false); handleInstall(); }}
          />
        )}

        {/* Pages (Routes) */}
        <Routes>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/settings" element={<SettingsPage />} />
          <Route path="/notes" element={<NotesPage />} />
          <Route path="/leaderboard" element={<LeaderboardPage />} />
        </Routes>
      </ActiveLayout>

      {errorMsg && <div className="toast">{errorMsg}</div>}
    </div>
  );
}
