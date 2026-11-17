import React, { useEffect, useState } from 'react';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../firebase';
import { useApp } from '../context/AppContext';

export default function LeaderboardPage() {
  const { user } = useApp();
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState('');

  useEffect(() => {
    let active = true;
    const load = async () => {
      try {
        if (user) {
          const token = await user.getIdToken();
          await fetch('/api/leaderboard', { method: 'POST', headers: { Authorization: `Bearer ${token}` } });
        }
        const snapshot = await getDocs(collection(db, 'leaderboard'));
        if (!active) return;
        const list = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
          .filter((item) => typeof item.attendancePercent === 'number')
          .sort((a, b) => b.attendancePercent - a.attendancePercent || a.displayName.localeCompare(b.displayName));
        setEntries(list);
      } catch {
        if (active) setMessage('Leaderboard is temporarily unavailable.');
      } finally {
        if (active) setLoading(false);
      }
    };
    load();
    return () => { active = false; };
  }, [data, user]);

  const myRank = entries.findIndex((entry) => entry.id === user?.uid) + 1;
  return (
    <div className="dashboard-settings">
      <div className="card">
        <div className="card-title">Attendance Leaderboard</div>
        <p className="hint">Display names and calculated attendance percentages are shown.</p>
        {message && <div className="reminder-banner">{message}</div>}
        {myRank > 0 && <div className="stat-row"><span className="stat-label">Your rank</span><span className="stat-value">#{myRank}</span></div>}
      </div>
      <div className="card">
        {loading ? <div className="loading">Loading leaderboard...</div> : entries.length === 0 ? <div className="hint">No students have opted in yet.</div> : entries.map((entry, index) => (
          <div className="stat-row" key={entry.id}>
            <span className="stat-label">#{index + 1} {entry.displayName}{entry.id === user?.uid ? ' (You)' : ''}</span>
            <span className="stat-value">{entry.attendancePercent.toFixed(1)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}
