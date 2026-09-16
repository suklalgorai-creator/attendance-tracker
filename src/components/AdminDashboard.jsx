import React, { useEffect, useState, useMemo } from 'react';
import { db } from '../firebase';
import { collection, getDocs } from 'firebase/firestore';
import { useApp } from '../context/AppContext';

export default function AdminDashboard({ onBack }) {
  const { user } = useApp();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [activeTab, setActiveTab] = useState('overview'); // overview, users, broadcast, holidays
  
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState('all'); // all, danger, safe, inactive

  // Notification state
  const [notifUid, setNotifUid] = useState(null);
  const [notifName, setNotifName] = useState('');
  const [notifTitle, setNotifTitle] = useState('Attendance Reminder ⏰');
  const [notifBody, setNotifBody] = useState('');
  const [notifStatus, setNotifStatus] = useState('');
  const [sending, setSending] = useState(false);
  const [showNotifModal, setShowNotifModal] = useState(false);

  // Holidays state
  const { globalSettings } = useApp();
  const [holidays, setHolidays] = useState(globalSettings?.holidays || {});
  const [holidayDate, setHolidayDate] = useState('');
  const [holidayName, setHolidayName] = useState('');

  const [notifyStudents, setNotifyStudents] = useState(true);

  const saveHoliday = async () => {
    if (!holidayDate) return;
    const newHolidays = { ...holidays, [holidayDate]: holidayName || 'Holiday' };
    try {
      const { doc, setDoc } = await import('firebase/firestore');
      await setDoc(doc(db, 'settings', 'global'), { holidays: newHolidays }, { merge: true });
      setHolidays(newHolidays);
      
      // Auto-notify logic
      if (notifyStudents) {
        const idToken = await user.getIdToken();
        const usersWithTokens = users.filter(u => u.fcmToken);
        for (const u of usersWithTokens) {
          try {
            await fetch('/api/send-notification', {
              method: 'POST',
              headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${idToken}`
              },
              body: JSON.stringify({
                uid: u.id,
                title: `🌴 Holiday Declared: ${holidayName || 'Holiday'}`,
                body: "Today is a holiday. Don't worry about your attendance, the tracker is auto-updated!"
              }),
            });
          } catch(e) {}
        }
        alert('Holiday saved and students notified!');
      } else {
        alert('Holiday saved!');
      }

      setHolidayDate('');
      setHolidayName('');
    } catch (e) {
      alert('Failed to save holiday: ' + e.message);
    }
  };

  const removeHoliday = async (dateStr) => {
    const newHolidays = { ...holidays };
    delete newHolidays[dateStr];
    try {
      const { doc, setDoc } = await import('firebase/firestore');
      await setDoc(doc(db, 'settings', 'global'), { holidays: newHolidays }, { merge: true });
      setHolidays(newHolidays);
    } catch (e) {
      alert('Failed to remove holiday');
    }
  };

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const querySnapshot = await getDocs(collection(db, 'users'));
        const userList = [];
        querySnapshot.forEach((doc) => {
          const data = doc.data();
          
          // Calculate stats
          let totalHeld = 0;
          let totalAttended = 0;
          let lastActive = null;
          
          if (data.records) {
            const keys = Object.keys(data.records).sort();
            if (keys.length > 0) lastActive = keys[keys.length - 1];
            
            Object.values(data.records).forEach(r => {
              totalHeld += Number(r.held || 0);
              totalAttended += Number(r.attended || 0);
            });
          }
          
          const currentPercent = totalHeld > 0 ? Math.round((totalAttended / totalHeld) * 100) : null;
          const minPercent = data.minPercent || 75;
          let health = 'neutral';
          if (currentPercent !== null) {
            health = currentPercent >= minPercent ? 'safe' : 'danger';
          }
          
          userList.push({
            id: doc.id,
            ...data,
            totalHeld,
            totalAttended,
            currentPercent,
            health,
            lastActive
          });
        });
        
        // Sort by last active (most recent first)
        userList.sort((a, b) => {
          if (!a.lastActive) return 1;
          if (!b.lastActive) return -1;
          return b.lastActive.localeCompare(a.lastActive);
        });
        
        setUsers(userList);
      } catch (err) {
        console.error(err);
        setError('Failed to fetch users.');
      } finally {
        setLoading(false);
      }
    };

    fetchUsers();
  }, []);

  // Aggregate Stats
  const stats = useMemo(() => {
    const total = users.length;
    const withPush = users.filter(u => u.fcmToken).length;
    
    // Active in last 7 days
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const activeRecent = users.filter(u => u.lastActive && new Date(u.lastActive) >= sevenDaysAgo).length;
    
    // Avg Attendance
    const validUsers = users.filter(u => u.currentPercent !== null);
    const avgAttendance = validUsers.length > 0 
      ? Math.round(validUsers.reduce((sum, u) => sum + u.currentPercent, 0) / validUsers.length)
      : 0;

    return { total, withPush, activeRecent, avgAttendance };
  }, [users]);

  // Filtered Users
  const filteredUsers = useMemo(() => {
    return users.filter(u => {
      const q = searchQuery.toLowerCase();
      const matchesSearch = 
        (u.email || '').toLowerCase().includes(q) || 
        (u.displayName || u.name || '').toLowerCase().includes(q) ||
        (u.programName || '').toLowerCase().includes(q);
        
      if (!matchesSearch) return false;
      
      if (filterStatus === 'danger') return u.health === 'danger';
      if (filterStatus === 'safe') return u.health === 'safe';
      if (filterStatus === 'inactive') return !u.lastActive;
      
      return true;
    });
  }, [users, searchQuery, filterStatus]);

  const sendNotification = async (isBroadcast = false) => {
    const targetUid = isBroadcast ? null : notifUid;
    if (!isBroadcast && !targetUid) return;
    if (!notifBody.trim()) {
      setNotifStatus('⚠️ Please enter a message.');
      return;
    }

    setSending(true);
    setNotifStatus('Sending...');

    try {
      const idToken = await user.getIdToken();

      if (isBroadcast) {
        const usersWithTokens = users.filter(u => u.fcmToken);
        let successCount = 0, failCount = 0;

        for (const u of usersWithTokens) {
          try {
            const res = await fetch('/api/send-notification', {
              method: 'POST',
              headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${idToken}`
              },
              body: JSON.stringify({
                uid: u.id,
                title: notifTitle || 'Attendance Reminder ⏰',
                body: notifBody
              }),
            });
            if (res.ok) successCount++; else failCount++;
          } catch { failCount++; }
        }
        setNotifStatus(`✅ Broadcast: ${successCount} sent, ${failCount} failed`);
      } else {
        const res = await fetch('/api/send-notification', {
          method: 'POST',
          headers: { 
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${idToken}`
          },
          body: JSON.stringify({
            uid: targetUid,
            title: notifTitle || 'Attendance Reminder ⏰',
            body: notifBody
          }),
        });
        const data = await res.json();
        if (res.ok) {
          setNotifStatus('✅ Sent successfully!');
          setTimeout(() => setShowNotifModal(false), 2000);
        } else {
          setNotifStatus(`❌ Error: ${data.error}`);
        }
      }
    } catch (err) {
      setNotifStatus(`❌ Network error: ${err.message}`);
    } finally {
      setSending(false);
      setTimeout(() => setNotifStatus(''), 5000);
    }
  };

  const openPushModal = (u) => {
    setNotifUid(u.id);
    setNotifName(u.displayName || u.name || u.email?.split('@')[0] || 'Student');
    setNotifBody(`Hi ${u.displayName?.split(' ')[0] || u.name?.split(' ')[0] || u.email?.split('@')[0] || 'there'}, `);
    setNotifStatus('');
    setShowNotifModal(true);
  };

  return (
    <div className="app-root">
      {/* Header */}
      <div className="header">
        <div>
          <div className="eyebrow">Admin Workspace</div>
          <div className="course-name">Dashboard</div>
        </div>
        <div className="header-right">
          <button className="icon-btn" onClick={onBack} title="Close">✕</button>
        </div>
      </div>

      {error && <div className="reminder-banner">{error}</div>}

      {/* Tabs Navigation */}
      <div className="admin-tabs">
        <button className={`admin-tab-btn ${activeTab === 'overview' ? 'active' : ''}`} onClick={() => setActiveTab('overview')}>Overview</button>
        <button className={`admin-tab-btn ${activeTab === 'users' ? 'active' : ''}`} onClick={() => setActiveTab('users')}>Users Management ({users.length})</button>
        <button className={`admin-tab-btn ${activeTab === 'holidays' ? 'active' : ''}`} onClick={() => setActiveTab('holidays')}>College Calendar</button>
        <button className={`admin-tab-btn ${activeTab === 'broadcast' ? 'active' : ''}`} onClick={() => setActiveTab('broadcast')}>Mass Broadcast</button>
      </div>

      {/* Overview Tab */}
      {activeTab === 'overview' && (
        <div className="card" style={{ animation: 'fadeIn 0.3s' }}>
          <div className="card-title">System Health</div>
          <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap' }}>
            <div className="admin-stat-box">
              <div className="stat-value">{loading ? '...' : stats.total}</div>
              <div className="stat-label">Registered Users</div>
            </div>
            <div className="admin-stat-box">
              <div className="stat-value">{loading ? '...' : stats.activeRecent}</div>
              <div className="stat-label">Active (7 Days)</div>
            </div>
            <div className="admin-stat-box">
              <div className="stat-value" style={{ color: 'var(--amber)' }}>{loading ? '...' : `${stats.avgAttendance}%`}</div>
              <div className="stat-label">Global Attendance</div>
            </div>
            <div className="admin-stat-box">
              <div className="stat-value" style={{ color: 'var(--ink-green)' }}>{loading ? '...' : stats.withPush}</div>
              <div className="stat-label">Push Reachable</div>
            </div>
          </div>
        </div>
      )}

      {/* Users Tab */}
      {activeTab === 'users' && (
        <div style={{ animation: 'fadeIn 0.3s' }}>
          <div className="admin-search-bar">
            <input 
              type="text" 
              placeholder="🔍 Search by name, email, or course..." 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            <select value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}>
              <option value="all">All Statuses</option>
              <option value="danger">Danger (Below Target)</option>
              <option value="safe">Safe (On Track)</option>
              <option value="inactive">No Records</option>
            </select>
          </div>

          {loading ? (
            <div className="loading">Loading users...</div>
          ) : filteredUsers.length === 0 ? (
            <div className="card" style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--muted)' }}>
              No users found matching your criteria.
            </div>
          ) : (
            <div className="admin-grid">
              {filteredUsers.map(u => (
                <div key={u.id} className="admin-user-card">
                  <div className="user-card-header">
                    <div>
                      <h3 style={{ textTransform: 'capitalize' }}>{u.displayName || u.name || 'Unnamed User'}</h3>
                      <p>{u.email || 'No Email'}</p>
                      <p style={{ fontSize: '11px', marginTop: '4px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                        {u.programName ? `${u.programName} ` : ''}{u.courseName ? `• ${u.courseName}` : ''}
                      </p>
                    </div>
                    <div className={`status-badge status-${u.health}`}>
                      {u.currentPercent !== null ? `${u.currentPercent}%` : 'N/A'}
                    </div>
                  </div>

                  <div className="user-card-stats">
                    <div className="user-card-stat">
                      <span className="user-card-stat-val">{u.totalAttended}/{u.totalHeld}</span>
                      <span className="user-card-stat-lbl">Classes</span>
                    </div>
                    <div className="user-card-stat">
                      <span className="user-card-stat-val">{u.lastActive ? new Date(u.lastActive).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : '-'}</span>
                      <span className="user-card-stat-lbl">Last Active</span>
                    </div>
                  </div>

                  <div className="user-card-actions">
                    {u.fcmToken ? (
                      <button className="btn-present" onClick={() => openPushModal(u)}>
                        📩 Send Push
                      </button>
                    ) : (
                      <button 
                        className="btn-clear" 
                        onClick={async () => {
                          try {
                            const { doc, updateDoc } = await import('firebase/firestore');
                            await updateDoc(doc(db, 'users', u.id), { adminRequestedPush: true });
                            alert(`Requested ${u.displayName || u.email} to enable push notifications! They will see a prompt next time they open the app.`);
                          } catch (e) {
                            alert('Failed to send request: ' + e.message);
                          }
                        }}
                        style={{ border: '1px solid var(--amber)', color: 'var(--amber)' }}
                      >
                        🔔 Request Push
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Holidays Tab */}
      {activeTab === 'holidays' && (
        <div className="card" style={{ animation: 'fadeIn 0.3s' }}>
          <div className="card-title">📅 Global Calendar</div>
          <p className="hint" style={{ marginBottom: '20px' }}>
            Declare Global Holidays or Exam Days. Students will see this on their calendar and will NOT receive attendance reminders on these days.
          </p>
          
          <div className="custom-row" style={{ gap: '8px', alignItems: 'flex-end', marginBottom: '12px', flexWrap: 'wrap' }}>
            <label className="field" style={{ marginBottom: 0, flex: 1, minWidth: '140px' }}>
              <span>Date</span>
              <input type="date" value={holidayDate} onChange={e => setHolidayDate(e.target.value)} />
            </label>
            <label className="field" style={{ marginBottom: 0, flex: 2, minWidth: '200px' }}>
              <span>Reason (e.g. Diwali, Mid-Sem)</span>
              <input type="text" placeholder="Holiday" value={holidayName} onChange={e => setHolidayName(e.target.value)} />
            </label>
            <button className="btn-present" style={{ height: '54px', padding: '0 24px' }} onClick={saveHoliday} disabled={!holidayDate || sending}>
              Add Holiday
            </button>
          </div>
          
          <label style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '24px', cursor: 'pointer', fontSize: '13px', color: 'var(--muted)' }}>
            <input type="checkbox" checked={notifyStudents} onChange={(e) => setNotifyStudents(e.target.checked)} style={{ width: '16px', height: '16px', accentColor: 'var(--amber)' }} />
            Notify all students that today is a holiday (auto-updates tracker)
          </label>

          <h4 style={{ color: 'var(--paper)', fontSize: '15px', fontWeight: 800, marginBottom: '12px' }}>Current Holidays</h4>
          {Object.keys(holidays).length === 0 ? (
            <div style={{ color: 'var(--muted)', fontSize: '14px', fontStyle: 'italic' }}>No global holidays declared yet.</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {Object.entries(holidays).sort((a,b) => a[0].localeCompare(b[0])).map(([date, reason]) => (
                <div key={date} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'var(--input-bg)', padding: '12px 16px', borderRadius: '12px', border: '1px solid var(--rule-bright)' }}>
                  <div>
                    <div style={{ color: 'var(--paper)', fontWeight: 700, fontSize: '15px' }}>{new Date(date).toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })}</div>
                    <div style={{ color: 'var(--amber)', fontSize: '12px', marginTop: '2px', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px' }}>{reason}</div>
                  </div>
                  <button className="icon-btn" style={{ color: 'var(--pen-red)' }} onClick={() => removeHoliday(date)}>✕</button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Broadcast Tab */}
      {activeTab === 'broadcast' && (
        <div className="card" style={{ animation: 'fadeIn 0.3s' }}>
          <div className="card-title">📢 Mass Broadcast</div>
          <p className="hint" style={{ marginBottom: '20px' }}>
            Send a notification to all {stats.withPush} users who have push notifications enabled.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <label className="field" style={{ marginBottom: 0 }}>
              <span>Notification Title</span>
              <input type="text" value={notifTitle} onChange={e => setNotifTitle(e.target.value)} />
            </label>
            <label className="field" style={{ marginBottom: 0 }}>
              <span>Message Body</span>
              <textarea 
                rows="4" 
                value={notifBody} 
                onChange={e => setNotifBody(e.target.value)} 
                style={{
                  background: 'var(--input-bg)', border: '1px solid var(--rule-bright)', borderRadius: '16px',
                  padding: '18px 20px', color: 'var(--paper)', fontSize: '16px', fontFamily: 'inherit', resize: 'vertical'
                }}
              />
            </label>

            <button 
              className="btn-present" 
              onClick={() => sendNotification(true)}
              disabled={sending || !notifBody.trim()}
              style={{ marginTop: '8px' }}
            >
              {sending ? '⏳ Broadcasting...' : `📢 Send to ${stats.withPush} Users`}
            </button>

            {notifStatus && (
              <div className={`reminder-banner ${notifStatus.includes('✅') ? 'banner-safe' : 'banner-danger'}`} style={{ marginTop: 0 }}>
                {notifStatus}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Direct Push Modal */}
      {showNotifModal && (
        <div className="modal-overlay" onClick={() => setShowNotifModal(false)}>
          <div className="modal-content custom-editor" onClick={e => e.stopPropagation()}>
            <div className="custom-row" style={{ marginBottom: '16px' }}>
              <span>Send to {notifName}</span>
              <button className="modal-close" onClick={() => setShowNotifModal(false)}>✕</button>
            </div>
            
            <label className="field" style={{ marginBottom: 0 }}>
              <span>Title</span>
              <input type="text" value={notifTitle} onChange={e => setNotifTitle(e.target.value)} />
            </label>
            <label className="field" style={{ marginBottom: 0 }}>
              <span>Message</span>
              <textarea 
                rows="4" 
                value={notifBody} 
                onChange={e => setNotifBody(e.target.value)} 
                style={{
                  background: 'var(--surface-solid)', border: '1px solid var(--rule-bright)', borderRadius: '16px',
                  padding: '18px 20px', color: 'var(--paper)', fontSize: '15px', fontFamily: 'inherit', resize: 'vertical'
                }}
              />
            </label>

            {notifStatus && <div style={{ fontSize: '14px', color: notifStatus.includes('✅') ? 'var(--ink-green)' : 'var(--pen-red)' }}>{notifStatus}</div>}

            <div className="custom-actions">
              <button className="btn-ghost" onClick={() => setShowNotifModal(false)}>Cancel</button>
              <button className="btn-present" onClick={() => sendNotification(false)} disabled={sending}>
                {sending ? 'Sending...' : 'Send Message'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
