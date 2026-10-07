import React, { useEffect, useState } from 'react';
import { db } from '../firebase';
import { collection, getDocs } from 'firebase/firestore';
import { useApp } from '../context/AppContext';
import { todayStr } from '../utils/date';

export default function LeaderboardPage() {
  const { user, data } = useApp();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [todayMarkedCount, setTodayMarkedCount] = useState(0);

  useEffect(() => {
    const fetchLeaderboard = async () => {
      try {
        const querySnapshot = await getDocs(collection(db, 'users'));
        const userList = [];
        const today = todayStr();
        let markedToday = 0;

        querySnapshot.forEach((docSnap) => {
          const d = docSnap.data();
          const points = d.consistencyPoints || 0;
          const name = d.displayName || d.name || d.email?.split('@')[0] || 'Anonymous';

          if (d.records && d.records[today]) {
            markedToday++;
          }

          if (points > 0) {
            userList.push({
              id: docSnap.id,
              name,
              points,
            });
          }
        });

        userList.sort((a, b) => b.points - a.points);
        setUsers(userList);
        setTodayMarkedCount(markedToday);
      } catch (err) {
        console.error('Leaderboard fetch error:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchLeaderboard();
  }, []);

  const myPoints = data?.consistencyPoints || 0;
  const myRank = users.findIndex((u) => u.id === user?.uid) + 1;

  return (
    <div className="dashboard-settings">
      {/* Today's Activity Banner */}
      <div className="card" style={{ padding: '16px 20px', animation: 'fadeIn 0.3s', background: 'linear-gradient(135deg, rgba(255,170,0,0.08), rgba(0,200,120,0.08))' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: '13px', color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.5px', fontWeight: 700 }}>Today's Activity</div>
            <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--paper)', marginTop: '4px' }}>
              🔥 {todayMarkedCount} student{todayMarkedCount !== 1 ? 's' : ''} marked today
            </div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: '28px', fontWeight: 800, color: 'var(--amber)' }}>{myPoints}</div>
            <div style={{ fontSize: '11px', color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Your Points</div>
          </div>
        </div>
      </div>

      {/* My Rank Card */}
      {myRank > 0 && (
        <div className="card" style={{ padding: '14px 20px', animation: 'fadeIn 0.4s', border: '1px solid var(--amber)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ fontSize: '28px' }}>
              {myRank === 1 ? '🥇' : myRank === 2 ? '🥈' : myRank === 3 ? '🥉' : '🏅'}
            </div>
            <div>
              <div style={{ color: 'var(--paper)', fontWeight: 700, fontSize: '16px' }}>Your Rank: #{myRank}</div>
              <div style={{ color: 'var(--muted)', fontSize: '13px' }}>
                {myRank === 1 ? 'You are the champion! 👑' : myRank <= 3 ? 'Almost at the top! Keep going!' : `${myRank - 1} student${myRank - 1 !== 1 ? 's' : ''} ahead of you`}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Leaderboard */}
      <div className="card" style={{ padding: '20px', animation: 'fadeIn 0.5s' }}>
        <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
          <span>🏆 Consistency Leaderboard</span>
        </div>
        <p className="hint" style={{ marginBottom: '20px' }}>
          Earn 10 points every day you mark attendance on the same day. Past dates don't count!
        </p>

        {loading ? (
          <div className="loading">Loading Leaderboard...</div>
        ) : users.length === 0 ? (
          <div style={{ textAlign: 'center', color: 'var(--muted)', padding: '40px 20px' }}>
            <div style={{ fontSize: '48px', marginBottom: '12px' }}>🏆</div>
            <div style={{ fontSize: '16px', fontWeight: 600 }}>No one on the board yet!</div>
            <div style={{ fontSize: '14px', marginTop: '8px' }}>Be the first — mark today's attendance to earn points.</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {users.map((u, idx) => {
              const isMe = u.id === user?.uid;
              return (
                <div
                  key={u.id}
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '12px 16px',
                    background: isMe ? 'rgba(255,170,0,0.08)' : 'transparent',
                    border: isMe ? '1px solid var(--amber)' : '1px solid var(--rule-bright)',
                    borderRadius: '12px',
                    transition: 'all 0.2s ease',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ fontSize: '18px', width: '32px', textAlign: 'center', fontWeight: 700 }}>
                      {idx === 0 ? '🥇' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : <span style={{ color: 'var(--muted)', fontSize: '14px' }}>{idx + 1}</span>}
                    </div>
                    <div>
                      <div style={{ color: 'var(--paper)', fontWeight: 600, textTransform: 'capitalize', fontSize: '15px' }}>
                        {u.name}
                        {isMe && <span style={{ color: 'var(--amber)', fontSize: '12px', marginLeft: '6px', fontWeight: 800 }}>(You)</span>}
                      </div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
                    <span style={{ color: idx < 3 ? 'var(--ink-green)' : 'var(--paper)', fontWeight: 800, fontSize: '16px' }}>{u.points}</span>
                    <span style={{ color: 'var(--muted)', fontSize: '10px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>pts</span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
