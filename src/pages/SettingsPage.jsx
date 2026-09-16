import React from 'react';
import { useApp } from '../context/AppContext';
import { useReminders } from '../hooks/useReminders';
import DayPicker from '../components/DayPicker';
import { DEFAULT_MIN, DEFAULT_CLASS_DAYS } from '../constants';
import { todayStr } from '../utils/date';

export default function SettingsPage() {
  const { user, data, theme, toggleTheme, saveSettings, resetAll, handleLogout, setShowAdmin, ADMIN_EMAIL, toTitleCase } = useApp();
  const { permission, requestPermission } = useReminders(data);

  return (
    <div className="settings-page-wrapper">
      
      {/* Profile Section */}
      <div className="card settings-card profile-card" style={{ marginBottom: 0 }}>
        <div className="card-title">Profile</div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ width: '88px', height: '88px', borderRadius: '50%', overflow: 'hidden', border: '2px solid var(--glass-border)', marginBottom: '16px', boxShadow: '0 8px 24px rgba(0,0,0,0.1)' }}>
            {user?.photoURL ? (
              <img src={user.photoURL} alt="Profile" style={{ width: '100%', height: '100%', objectFit: 'cover' }} referrerPolicy="no-referrer" />
            ) : (
              <div style={{ width: '100%', height: '100%', background: 'var(--rule)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '36px', fontWeight: '800', color: 'var(--paper)' }}>
                {user?.email ? user.email.charAt(0).toUpperCase() : 'G'}
              </div>
            )}
          </div>
          <div style={{ fontSize: '22px', fontWeight: '800', color: 'var(--paper)' }}>{data.name || user?.displayName || 'Guest User'}</div>
          <div style={{ fontSize: '15px', color: 'var(--muted)', marginTop: '4px', fontWeight: '500' }}>{user?.email || 'Not logged in (Local Data Only)'}</div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '24px', width: '100%' }}>
            {user ? (
              <button className="btn-ghost" onClick={handleLogout} style={{ flex: 1 }}>Log Out</button>
            ) : (
              <button className="btn-present" onClick={handleLogout} style={{ flex: 1, boxShadow: '0 4px 12px rgba(16, 185, 129, 0.4)' }}>
                Sign In to Backup Data
              </button>
            )}
            {user?.email === ADMIN_EMAIL && (
              <button className="btn-present" onClick={() => setShowAdmin(true)} style={{ flex: 1 }}>
                Admin Dashboard
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Personalization Section */}
      <div className="card settings-card" style={{ marginBottom: 0 }}>
        <div className="card-title">Personalization</div>
        <label className="field">
          <span>Theme</span>
          <button className="btn-ghost" onClick={toggleTheme} style={{ border: '1px solid var(--rule)', padding: '12px', width: '100%', fontWeight: '700' }}>
            {theme === 'dark' ? '☀️ Switch to Light Mode' : '🌙 Switch to Dark Mode'}
          </button>
        </label>
        <label className="field">
          <span>Your Name</span>
          <input type="text" value={data.name || ''} placeholder={user?.displayName || 'Enter your name'} onChange={(e) => saveSettings({ name: e.target.value })} />
        </label>
        <label className="field">
          <span>Degree / Program name</span>
          <input list="program-options" value={data.programName || ''} onChange={(e) => saveSettings({ programName: e.target.value })} onBlur={(e) => saveSettings({ programName: toTitleCase(e.target.value) })} />
          <datalist id="program-options">
            <option value="B.Tech CSE" /><option value="B.Tech IT" /><option value="B.Tech ECE" /><option value="B.Tech Mechanical" /><option value="B.Tech Civil" />
            <option value="BCA" /><option value="MCA" /><option value="BBA" /><option value="MBA" />
            <option value="B.Sc" /><option value="B.Com" /><option value="BA" />
          </datalist>
        </label>
        <label className="field">
          <span>Semester name</span>
          <input list="semester-options" value={data.courseName || ''} onChange={(e) => saveSettings({ courseName: e.target.value })} onBlur={(e) => saveSettings({ courseName: toTitleCase(e.target.value) })} />
          <datalist id="semester-options">
            <option value="Semester 1" /><option value="Semester 2" /><option value="Semester 3" /><option value="Semester 4" />
            <option value="Semester 5" /><option value="Semester 6" /><option value="Semester 7" /><option value="Semester 8" />
          </datalist>
        </label>
      </div>

      {/* Attendance Rules Section */}
      <div className="card settings-card" style={{ marginBottom: 0 }}>
        <div className="card-title">Attendance Rules</div>
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
          <DayPicker value={data.classDays || DEFAULT_CLASS_DAYS} onChange={(v) => saveSettings({ classDays: v.length ? v : DEFAULT_CLASS_DAYS })} />
        </label>
      </div>

      {/* Reminders & Notifications Section */}
      <div className="card settings-card" style={{ marginBottom: 0 }}>
        <div className="card-title">Notifications</div>
        <label className="field">
          <span>Remind me if not marked by</span>
          <input type="time" value={data.reminderTime || '18:00'} onChange={(e) => saveSettings({ reminderTime: e.target.value })} />
          <span className="hint">Shows a banner when you open the app after this time.</span>
        </label>
        <label className="field">
          <span>Push Notifications</span>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: 'var(--input-bg)', border: '1px solid var(--rule-bright)', borderRadius: '16px', padding: '16px 20px' }}>
            <span style={{ margin: 0, fontWeight: 700, color: 'var(--paper)' }}>
              {permission === 'granted' ? '✅ Enabled' : permission === 'denied' ? '❌ Blocked' : 'Not setup'}
            </span>
            {permission !== 'granted' && permission !== 'denied' && (
              <button className="btn-present" style={{ padding: '8px 16px', fontSize: '13px' }} onClick={requestPermission}>Enable</button>
            )}
          </div>
          {permission === 'denied' ? (
            <span className="hint" style={{ color: 'var(--amber)' }}>Notifications are blocked. Please allow them in your browser's site settings.</span>
          ) : (
            <span className="hint">Receive a native notification at the reminder time.</span>
          )}
        </label>
      </div>

      {/* Danger Zone */}
      <div className="card settings-card" style={{ marginBottom: 0 }}>
        <div className="card-title" style={{ color: '#ef4444' }}>Danger Zone</div>
        <button className="btn-clear btn-wide" onClick={resetAll} style={{ borderColor: 'rgba(239, 68, 68, 0.3)', color: '#f87171' }}>Reset all data</button>
        <span className="hint" style={{ display: 'block', textAlign: 'center', marginTop: '12px' }}>This action cannot be undone.</span>
      </div>

    </div>
  );
}
