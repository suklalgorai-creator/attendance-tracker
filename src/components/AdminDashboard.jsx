import React, { useEffect, useState } from 'react';
import { db } from '../firebase';
import { collection, getDocs } from 'firebase/firestore';


export default function AdminDashboard({ onBack }) {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

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
        </div>
      </div>

      {error && <div className="reminder-banner">{error}</div>}

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
                <div className="admin-user-stats">
                  {u.records ? Object.keys(u.records).length : 0} days tracked
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
