import React, { useState } from 'react';
import { auth } from '../firebase';
import { createUserWithEmailAndPassword, signInWithEmailAndPassword, GoogleAuthProvider, signInWithPopup } from 'firebase/auth';
import { useApp } from '../context/AppContext';


export default function Auth() {
  const { setGuestMode } = useApp();
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleGuest = () => {
    localStorage.setItem('guestMode', 'true');
    setGuestMode(true);
  };

  const handleGoogle = async () => {
    setError('');
    setLoading(true);
    const provider = new GoogleAuthProvider();
    try {
      await signInWithPopup(auth, provider);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };



  return (
    <div className="app-root auth-root">
      <div className="card auth-card">
        <h1 className="course-name" style={{ textAlign: 'center', marginBottom: '24px' }}>
          Attendance Tracker
        </h1>
        <h2 style={{ fontSize: '18px', marginBottom: '32px', textAlign: 'center', color: 'var(--muted)' }}>
          Sign in to track your attendance
        </h2>
        
        {error && <div className="auth-error" style={{ marginBottom: '24px' }}>{error}</div>}
        
        <button 
          type="button" 
          className="btn-google btn-wide" 
          onClick={handleGoogle} 
          disabled={loading}
          style={{ marginTop: '0', padding: '16px' }}
        >
          {loading ? 'Connecting...' : (
            <>
              <svg viewBox="0 0 24 24" width="20" height="20" xmlns="http://www.w3.org/2000/svg">
                <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
              </svg>
              Continue with Google
            </>
          )}
        </button>

        <button
          type="button"
          className="btn-ghost btn-wide"
          onClick={handleGuest}
          disabled={loading}
          style={{ marginTop: '16px', padding: '16px', color: 'var(--muted)' }}
        >
          Skip for now (Use as Guest)
        </button>
      </div>
    </div>
  );
}
