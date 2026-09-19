import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import SupportModal from './SupportModal';
import { NavLink } from 'react-router-dom';
export default function DrawerMenu({ data, onClose, canInstall, onInstall }) {
  const { theme, toggleTheme } = useApp();

  const handleExportCSV = () => {
    if (!data || !data.records) {
      alert("No data available to export.");
      onClose();
      return;
    }
    
    const records = data.records;
    const dates = Object.keys(records).sort();
    
    let csv = "Date,Classes Held,Classes Attended\n";
    dates.forEach(date => {
      const r = records[date];
      csv += `${date},${r.held},${r.attended}\n`;
    });
    
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `attendance_export_${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    
    onClose();
  };

  const handleShare = () => {
    if (navigator.share) {
      navigator.share({
        title: 'College Attendance Tracker',
        text: 'I am tracking my college attendance easily with this app!',
        url: window.location.origin
      }).catch(err => console.log('Share failed:', err));
    } else {
      navigator.clipboard.writeText(window.location.origin);
      alert("Link copied to clipboard!");
    }
    onClose();
  };

  const handleWhatsNew = () => {
    alert("What's New in v2.0:\n\n👑 All New Admin Dashboard\n📅 Global Holidays & Exam Days\n🔔 Smart Push Reminders (Auto-skip on holidays)\n💬 Broadcast Announcements\n📊 CSV Export & Analytics\n✨ Bug fixes & UI improvements");
    onClose();
  };

  const [showSupport, setShowSupport] = useState(false);

  if (showSupport) {
    return <SupportModal onClose={() => setShowSupport(false)} />;
  }

  return (
    <>
      <div className="drawer-overlay" onClick={onClose}></div>
      <div className="drawer-menu">
        <div className="drawer-header">
          <h3>Menu</h3>
          <button className="icon-btn" onClick={onClose}>
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
          </button>
        </div>
        <div className="drawer-content" style={{ padding: '8px 0' }}>
          <div style={{ fontSize: '12px', fontWeight: 'bold', color: 'var(--muted)', textTransform: 'uppercase', padding: '12px 16px 4px', letterSpacing: '1px' }}>Additional Features</div>
          <NavLink to="/notes" className="drawer-item" onClick={onClose} style={{ textDecoration: 'none' }}>
            <span>📝</span> Sticky Notes
          </NavLink>
          <button className="drawer-item" onClick={handleExportCSV}>
            <span>📊</span> Export Data (CSV)
          </button>

          <div className="drawer-divider" style={{ margin: '8px 0' }}></div>
          <div style={{ fontSize: '12px', fontWeight: 'bold', color: 'var(--muted)', textTransform: 'uppercase', padding: '12px 16px 4px', letterSpacing: '1px' }}>App & Settings</div>
          
          {canInstall && (
            <button className="drawer-item" onClick={onInstall} style={{ color: 'var(--amber)' }}>
              <span>📲</span> Install App
            </button>
          )}
          <button className="drawer-item" onClick={toggleTheme}>
            <span>{theme === 'dark' ? '☀️' : '🌙'}</span> {theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
          </button>
          <button className="drawer-item" onClick={handleWhatsNew}>
            <span>✨</span> What's New
          </button>
          <button className="drawer-item" onClick={handleShare}>
            <span>🔗</span> Share App
          </button>

          <div className="drawer-divider" style={{ margin: '8px 0' }}></div>
          <div style={{ fontSize: '12px', fontWeight: 'bold', color: 'var(--muted)', textTransform: 'uppercase', padding: '12px 16px 4px', letterSpacing: '1px' }}>Support</div>

          <button className="drawer-item" onClick={() => setShowSupport(true)}>
            <span>☕</span> Support Developer
          </button>
          <a href="mailto:codecraftdigital.in@gmail.com?subject=Attendance App Feedback" className="drawer-item" onClick={onClose} style={{ textDecoration: 'none' }}>
            <span>✉️</span> Send Feedback
          </a>
        </div>
      </div>
    </>
  );
}
