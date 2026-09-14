import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { useInstallPrompt } from '../hooks/useInstallPrompt';
import { useReminders } from '../hooks/useReminders';
import { useMediaQuery } from '../hooks/useMediaQuery';
import { todayStr, getPeriodsForDate, isClassDay } from '../utils/date';
import { DEFAULT_CLASS_DAYS } from '../constants';
import Auth from '../components/Auth';
import DrawerMenu from '../components/DrawerMenu';
import StreakPopup from '../components/StreakPopup';
import InstallPopup from '../components/InstallPopup';
import DashboardPage from '../pages/DashboardPage';
import RegisterPage from '../pages/RegisterPage';
import SettingsPage from '../pages/SettingsPage';
import OnboardingPage from '../pages/OnboardingPage';
import DesktopLayout from './DesktopLayout';
import MobileLayout from './MobileLayout';

const AdminDashboard = React.lazy(() => import('../components/AdminDashboard'));

export default function AppLayout() {
  const {
    authLoading, user, loading, data, stats,
    showAdmin, setShowAdmin,
    errorMsg, streak,
    showStreakPopup, setShowStreakPopup,
    showDrawer, setShowDrawer,
  } = useApp();

  const { showInstallPopup, deferredPrompt, handleInstall, handleDismiss } = useInstallPrompt();
  
  // Activate reminders
  useReminders(data);

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

  if (!user) {
    return <Auth />;
  }

  if (showAdmin) {
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
  const classDays = data.classDays || DEFAULT_CLASS_DAYS;
  const timetable = data.timetable || {};
  const today = todayStr();
  const reminderTime = data.reminderTime || '18:00';
  const [rh, rm] = reminderTime.split(':').map(Number);
  const now = new Date();
  const nowMinutes = now.getHours() * 60 + now.getMinutes();
  const reminderMinutes = (rh || 0) * 60 + (rm || 0);
  const todayPeriods = getPeriodsForDate(today, timetable);
  const showReminder = isClassDay(today, classDays) && !data.records[today] && nowMinutes >= reminderMinutes;

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
          <div className="header-right">
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
            ⏰ Aaj ki attendance abhi tak mark nahi ki{todayPeriods ? ` — ${todayPeriods.length} period${todayPeriods.length === 1 ? '' : 's'} pending` : ''}.
          </div>
        )}

        {/* Modals */}
        {showInstallPopup && deferredPrompt && (
          <InstallPopup onInstall={handleInstall} onDismiss={handleDismiss} />
        )}

        {showStreakPopup && (
          <StreakPopup streak={streak} onClose={() => setShowStreakPopup(false)} />
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
        </Routes>
      </ActiveLayout>

      {errorMsg && <div className="toast">{errorMsg}</div>}
    </div>
  );
}
