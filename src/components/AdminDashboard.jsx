import React, { useEffect, useState } from 'react';
import { db } from '../firebase';
import { collection, getDocs } from 'firebase/firestore';
import { useApp } from '../context/AppContext';

export default function AdminDashboard({ onBack }) {
  const { user } = useApp();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Notification state
  const [notifUid, setNotifUid] = useState('');
  const [notifTitle, setNotifTitle] = useState('Attendance Reminder ⏰');
  const [notifBody, setNotifBody] = useState('');
  const [notifStatus, setNotifStatus] = useState('');
  const [sending, setSending] = useState(false);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const querySnapshot = await getDocs(collection(db, 'users'));
        const userList = [];
        querySnapshot.forEach((doc) => {
          userList.push({ id: doc.id, ...doc.data() });
        });
        setUsers(userList);
      } catch (err) {
        console.error(err);
        setError('Failed to fetch users. Ensure your Firebase Firestore Security Rules allow read access.');
      } finally {
        setLoading(false);
      }
    };

    fetchUsers();
  }, []);

  const sendNotification = async (targetUid) => {
    const uid = targetUid || notifUid;
    if (!uid || !notifBody.trim()) {
      setNotifStatus('⚠️ Please select a user and enter a message.');
      return;
    }

    setSending(true);
    setNotifStatus('Sending...');

    try {
      const res = await fetch('/api/send-notification', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          uid: uid,
          title: notifTitle || 'Attendance Reminder ⏰',
          body: notifBody,
          adminKey: import.meta.env.VITE_ADMIN_SECRET_KEY || '',
        }),
      });

      const data = await res.json();

      if (res.ok) {
        setNotifStatus('✅ Notification sent successfully!');
        setNotifBody('');
      } else {
        setNotifStatus(`❌ Error: ${data.error}`);
      }
    } catch (err) {
      setNotifStatus(`❌ Network error: ${err.message}`);
    } finally {
      setSending(false);
      setTimeout(() => setNotifStatus(''), 5000);
    }
  };

  const broadcastToAll = async () => {
    if (!notifBody.trim()) {
      setNotifStatus('⚠️ Please enter a message to broadcast.');
      return;
    }

    setSending(true);
    setNotifStatus('Broadcasting...');

    const usersWithTokens = users.filter(u => u.fcmToken);
    let successCount = 0;
    let failCount = 0;

    for (const u of usersWithTokens) {
      try {
        const res = await fetch('/api/send-notification', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            uid: u.id,
            title: notifTitle || 'Attendance Reminder ⏰',
            body: notifBody,
            adminKey: import.meta.env.VITE_ADMIN_SECRET_KEY || '',
          }),
        });
        if (res.ok) successCount++;
        else failCount++;
      } catch {
        failCount++;
      }
    }

    setNotifStatus(`✅ Broadcast complete: ${successCount} sent, ${failCount} failed`);
    setNotifBody('');
    setSending(false);
    setTimeout(() => setNotifStatus(''), 5000);
  };

  const usersWithNotif = users.filter(u => u.fcmToken);

  return (
    <div className="app-root">
      <div className="header">
        <div>
          <div className="eyebrow">Admin Panel</div>
          <div className="course-name">Dashboard</div>
        </div>
        <div className="header-right">
          <button className="icon-btn" onClick={onBack} title="Close Admin Dashboard">✕</button>
        </div>
      </div>

      <div className="card">
        <div className="card-title">Overview</div>
        <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap' }}>
          <div className="admin-stat-box">
            <div className="stat-value">{loading ? '...' : users.length}</div>
            <div className="stat-label">Total Users</div>
          </div>
          <div className="admin-stat-box">
            <div className="stat-value">{loading ? '...' : usersWithNotif.length}</div>
            <div className="stat-label">Push Enabled</div>
          </div>
        </div>
      </div>

      {error && <div className="reminder-banner">{error}</div>}

      {/* ===== Notification Center ===== */}
      <div className="card">
        <div className="card-title">📤 Send Notification</div>
        
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <select
            value={notifUid}
            onChange={(e) => setNotifUid(e.target.value)}
            style={{
              padding: '12px',
              borderRadius: '10px',
              border: '1px solid var(--rule-bright)',
              background: 'var(--surface-solid)',
              color: 'var(--paper)',
              fontSize: '14px',
            }}
          >
            <option value="">-- Select User --</option>
            {usersWithNotif.map(u => (
              <option key={u.id} value={u.id}>
                {u.email || u.id} {u.programName ? `(${u.programName})` : ''}
              </option>
            ))}
          </select>

          <input
            type="text"
            placeholder="Title (optional)"
            value={notifTitle}
            onChange={(e) => setNotifTitle(e.target.value)}
            style={{
              padding: '12px',
              borderRadius: '10px',
              border: '1px solid var(--rule-bright)',
              background: 'var(--surface-solid)',
              color: 'var(--paper)',
              fontSize: '14px',
            }}
          />

          <textarea
            placeholder="Type your message here..."
            value={notifBody}
            onChange={(e) => setNotifBody(e.target.value)}
            rows={3}
            style={{
              padding: '12px',
              borderRadius: '10px',
              border: '1px solid var(--rule-bright)',
              background: 'var(--surface-solid)',
              color: 'var(--paper)',
              fontSize: '14px',
              resize: 'vertical',
              fontFamily: 'inherit',
            }}
          />

          <div style={{ display: 'flex', gap: '10px' }}>
            <button
              className="btn-present"
              onClick={() => sendNotification()}
              disabled={sending}
              style={{ flex: 1, padding: '12px', fontSize: '14px', opacity: sending ? 0.6 : 1 }}
            >
              {sending ? '⏳ Sending...' : '📩 Send to User'}
            </button>
            <button
              className="btn-clear"
              onClick={broadcastToAll}
              disabled={sending}
              style={{ flex: 1, padding: '12px', fontSize: '14px', border: '1px solid var(--rule-bright)', opacity: sending ? 0.6 : 1 }}
            >
              {sending ? '⏳ ...' : `📢 Broadcast (${usersWithNotif.length})`}
            </button>
          </div>

          {notifStatus && (
            <div style={{
              padding: '10px 14px',
              borderRadius: '10px',
              background: notifStatus.includes('✅') ? 'rgba(34,197,94,0.1)' : notifStatus.includes('❌') ? 'rgba(244,63,94,0.1)' : 'rgba(255,255,255,0.05)',
              color: notifStatus.includes('✅') ? 'var(--pen-green)' : notifStatus.includes('❌') ? 'var(--pen-red)' : 'var(--muted)',
              fontSize: '13px',
              fontWeight: '600',
            }}>
              {notifStatus}
            </div>
          )}
        </div>
      </div>

      {/* ===== User List ===== */}
      <div className="card">
        <div className="card-title">Registered Users ({users.length})</div>
        {loading ? (
          <div className="loading">Loading user data...</div>
        ) : users.length === 0 && !error ? (
          <div style={{ color: 'var(--muted)', textAlign: 'center', padding: '20px 0' }}>No users found.</div>
        ) : (
          <div className="admin-user-list">
            {users.map(u => (
              <div key={u.id} className="admin-user-row">
                <div className="admin-user-info">
                  <strong>{u.email || 'No email saved (Old user)'}</strong>
                  <span>{u.programName ? `${u.programName} - ` : ''}{u.courseName || 'No Course Name'}</span>
                </div>
                <div className="admin-user-stats" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <span>{u.records ? Object.keys(u.records).length : 0} days</span>
                  {u.fcmToken ? (
                    <button
                      className="btn-present"
                      onClick={() => {
                        setNotifUid(u.id);
                        setNotifBody(`Hi ${u.email?.split('@')[0] || 'there'}! `);
                        window.scrollTo({ top: 0, behavior: 'smooth' });
                      }}
                      style={{ padding: '4px 10px', fontSize: '11px', borderRadius: '8px' }}
                      title="Send notification to this user"
                    >
                      🔔
                    </button>
                  ) : (
                    <span style={{ fontSize: '11px', color: 'var(--muted)' }}>No push</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
