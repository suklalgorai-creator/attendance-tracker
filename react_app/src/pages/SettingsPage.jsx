import React, { useRef, useState } from 'react';
import { useApp } from '../context/AppContext';
import DayPicker from '../components/DayPicker';
import { DEFAULT_CLASS_DAYS, DEFAULT_MIN } from '../constants';
import { downloadJsonBackup, parseBackup } from '../utils/backup';
import { todayStr } from '../utils/date';

export default function SettingsPage() {
  const {
    user, isAdmin, data, theme, toggleTheme, saveSettings, resetAll, handleLogout,
    setShowAdmin, toTitleCase, globalSettings, restoreBackup, notification,
  } = useApp();
  const [pendingRestore, setPendingRestore] = useState(null);
  const [backupError, setBackupError] = useState('');
  const fileInputRef = useRef(null);
  const defaultPrograms = ['B.Tech CSE', 'B.Tech IT', 'B.Tech ECE', 'B.Tech Mechanical', 'B.Tech Civil', 'BCA', 'MCA', 'BBA', 'MBA', 'B.Sc', 'B.Com', 'BA'];
  const defaultSemesters = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'];
  const programOptions = globalSettings?.programs?.length ? globalSettings.programs : defaultPrograms;
  const semesterOptions = globalSettings?.semesters?.length ? globalSettings.semesters : defaultSemesters;

  const chooseBackup = async (event) => {
    const file = event.target.files?.[0];
    setBackupError('');
    setPendingRestore(null);
    if (!file) return;
    try {
      setPendingRestore(parseBackup(await file.text()));
    } catch (error) {
      setBackupError(error instanceof Error ? error.message : 'Unable to read backup.');
    }
  };

  const confirmRestore = () => {
    if (!pendingRestore) return;
    const result = restoreBackup(pendingRestore.data);
    if (result.ok) {
      setPendingRestore(null);
      if (fileInputRef.current) fileInputRef.current.value = '';
    } else setBackupError(result.error || 'Restore failed; existing data was not changed.');
  };

  return (
    <div className="settings-page-wrapper">
      <div className="card settings-card profile-card" style={{ marginBottom: 0 }}>
        <div className="card-title">Profile</div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ width: '88px', height: '88px', borderRadius: '50%', overflow: 'hidden', border: '2px solid var(--glass-border)', marginBottom: '16px' }}>
            {user?.photoURL ? <img src={user.photoURL} alt="Profile" style={{ width: '100%', height: '100%', objectFit: 'cover' }} referrerPolicy="no-referrer" /> : <div style={{ width: '100%', height: '100%', background: 'var(--rule)', display: 'grid', placeItems: 'center', fontSize: '36px', fontWeight: 800 }}>{user?.email?.charAt(0).toUpperCase() || 'G'}</div>}
          </div>
          <div style={{ fontSize: '22px', fontWeight: 800 }}>{data.name || user?.displayName || 'Guest User'}</div>
          <div className="hint">{user?.email || 'Not logged in — stored on this device only'}</div>
          <div style={{ display: 'flex', gap: '12px', marginTop: '24px', width: '100%' }}>
            <button type="button" className={user ? 'btn-ghost' : 'btn-present'} onClick={() => { handleLogout(); }} style={{ flex: 1 }}>{user ? 'Log Out' : 'Sign In to Sync'}</button>
            {isAdmin && <button type="button" className="btn-present" onClick={() => setShowAdmin(true)} style={{ flex: 1 }}>Admin Dashboard</button>}
          </div>
        </div>
      </div>

      <div className="card settings-card" style={{ marginBottom: 0 }}>
        <div className="card-title">Personalization</div>
        <label className="field"><span>Theme</span><button type="button" className="btn-ghost" onClick={toggleTheme}>{theme === 'dark' ? '☀️ Switch to Light Mode' : '🌙 Switch to Dark Mode'}</button></label>
        <label className="field"><span>Your Name</span><input type="text" maxLength="120" value={data.name || ''} placeholder={user?.displayName || 'Enter your name'} onChange={(event) => saveSettings({ name: event.target.value })} /></label>
        <label className="field"><span>Degree / Program name</span><input list="program-options" maxLength="120" value={data.programName || ''} onChange={(event) => saveSettings({ programName: event.target.value })} onBlur={(event) => saveSettings({ programName: toTitleCase(event.target.value) })} /><datalist id="program-options">{programOptions.map((program) => <option key={program} value={program} />)}</datalist></label>
        <label className="field"><span>Semester name</span><input list="semester-options" maxLength="120" value={data.courseName || ''} onChange={(event) => saveSettings({ courseName: event.target.value })} onBlur={(event) => saveSettings({ courseName: toTitleCase(event.target.value) })} /><datalist id="semester-options">{semesterOptions.map((semester) => <option key={semester} value={semester} />)}</datalist></label>
      </div>

      <div className="card settings-card" style={{ marginBottom: 0 }}>
        <div className="card-title">Attendance Rules</div>
        <label className="field"><span>Classes started on</span><input type="date" value={data.startDate} max={todayStr()} onChange={(event) => saveSettings({ startDate: event.target.value })} /></label>
        <label className="field"><span>Minimum attendance required</span><div className="min-row"><input type="number" min="1" max="100" step="0.1" value={data.minPercent} onChange={(event) => saveSettings({ minPercent: Math.max(1, Math.min(100, Number(event.target.value) || DEFAULT_MIN)) })} /><span>%</span></div></label>
        <label className="field"><span>Which days do you have class?</span><DayPicker value={data.classDays || DEFAULT_CLASS_DAYS} onChange={(value) => saveSettings({ classDays: value.length ? value : DEFAULT_CLASS_DAYS })} /></label>
      </div>

      <div className="card settings-card" style={{ marginBottom: 0 }}>
        <div className="card-title">Notifications</div>
        <label className="field"><span>Remind me if not marked by</span><input type="time" value={data.reminderTime || '18:00'} onChange={(event) => saveSettings({ reminderTime: event.target.value })} /></label>
        <div className="custom-row"><span>{notification.permission === 'granted' && data.pushNotificationsEnabled ? '✅ Enabled' : notification.permission === 'denied' ? '❌ Blocked by browser' : 'Disabled'}</span>{data.pushNotificationsEnabled ? <button type="button" className="btn-ghost" onClick={notification.revokePermission}>Disable in app</button> : <button type="button" className="btn-present" onClick={notification.requestPermission} disabled={notification.permission === 'denied'}>Enable</button>}</div>
        <span className="hint">Disabling removes this app’s token; browser permission can be changed in browser settings.</span>
      </div>

      <div className="card settings-card" style={{ marginBottom: 0 }}>
        <div className="card-title">Backup & Restore</div>
        <p className="hint">JSON backup includes daily attendance, settings, holidays, and notes. CSV exports are not complete backups.</p>
        <div className="quick-actions"><button type="button" className="btn-present" onClick={() => downloadJsonBackup(data)}>Export full backup</button><button type="button" className="btn-ghost" onClick={() => fileInputRef.current?.click()}>Choose backup to restore</button></div>
        <input ref={fileInputRef} type="file" accept="application/json,.json" onChange={chooseBackup} style={{ display: 'none' }} />
        {backupError && <div className="banner banner-danger" style={{ marginTop: '12px' }}>{backupError}</div>}
        {pendingRestore && <div className="banner" style={{ marginTop: '12px' }}><strong>Restore preview</strong><div>{pendingRestore.summary.legacyRecords} daily totals will be restored</div>{pendingRestore.summary.quarantined > 0 && <div>{pendingRestore.summary.quarantined} invalid item(s) will remain quarantined.</div>}<div className="quick-actions" style={{ marginTop: '10px' }}><button type="button" className="btn-present" onClick={confirmRestore}>Confirm restore</button><button type="button" className="btn-clear" onClick={() => setPendingRestore(null)}>Cancel</button></div></div>}
      </div>

      <div className="card settings-card" style={{ marginBottom: 0 }}>
        <div className="card-title" style={{ color: '#ef4444' }}>Danger Zone</div>
        <button type="button" className="btn-clear btn-wide" onClick={() => { if (window.confirm('Clear all attendance records and notes? A local safety backup is recommended first.')) resetAll(); }}>Clear attendance history</button>
        <span className="hint">This action can be undone only by restoring a backup.</span>
      </div>
    </div>
  );
}
