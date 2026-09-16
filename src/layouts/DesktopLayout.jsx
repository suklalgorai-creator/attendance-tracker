import React, { useState } from 'react';
import { NavLink } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import SupportModal from '../components/SupportModal';

export default function DesktopLayout({ children }) {
  const { data } = useApp();
  const [showSupport, setShowSupport] = useState(false);
  const [isCollapsed, setIsCollapsed] = useState(false);

  const handleExportCSV = () => {
    if (!data || !data.records) return alert("No data available to export.");
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
  };

  const handleShare = () => {
    navigator.clipboard.writeText(window.location.origin);
    alert("App Link copied to clipboard!");
  };

  const handleWhatsNew = () => {
    alert("What's New in v2.0:\n\n👑 All New Admin Dashboard\n📅 Global Holidays & Exam Days\n🔔 Smart Push Reminders (Auto-skip on holidays)\n💬 Broadcast Announcements\n📊 CSV Export & Analytics\n✨ Bug fixes & UI improvements");
  };
  return (
    <div className="layout-wrapper desktop-layout">
      {/* Sidebar */}
      <nav className={`sidebar ${isCollapsed ? 'collapsed' : ''}`}>
        <div className="sidebar-brand" style={{ display: 'flex', justifyContent: 'space-between', width: '100%' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', overflow: 'hidden' }}>
            <span className="brand-logo">🎓</span>
            <span className="brand-name">Attendance</span>
          </div>
          <button className="hamburger-btn" onClick={() => setIsCollapsed(!isCollapsed)} style={{ background: 'transparent', border: 'none', padding: '4px', margin: 0, width: 'auto', height: 'auto', boxShadow: 'none' }}>
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
          </button>
        </div>
        
        <div className="sidebar-links">
          <NavLink to="/" className={({ isActive }) => `nav-btn ${isActive ? 'active' : ''}`} end>
            <span className="nav-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>
            </span>
            <span className="nav-label">Dashboard</span>
          </NavLink>
          
          <NavLink to="/register" className={({ isActive }) => `nav-btn ${isActive ? 'active' : ''}`}>
            <span className="nav-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="4" rx="2" ry="2"></rect><line x1="16" x2="16" y1="2" y2="6"></line><line x1="8" x2="8" y1="2" y2="6"></line><line x1="3" x2="21" y1="10" y2="10"></line></svg>
            </span>
            <span className="nav-label">Register</span>
          </NavLink>

          <NavLink to="/settings" className={({ isActive }) => `nav-btn ${isActive ? 'active' : ''}`}>
            <span className="nav-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>
            </span>
            <span className="nav-label">Settings</span>
          </NavLink>
        </div>

        <div className="sidebar-footer" style={{ marginTop: 'auto', paddingTop: '24px', borderTop: '1px solid var(--rule)', display: 'flex', flexDirection: 'column', gap: '8px' }}>
          <button className="nav-btn" onClick={() => alert("My Resources feature is coming soon!")} style={{ padding: '12px 16px', background: 'transparent', border: 'none', color: 'var(--muted)', textAlign: 'left', display: 'flex', alignItems: 'center', gap: '12px', fontSize: '14px', fontWeight: '600', cursor: 'pointer', borderRadius: '12px' }}>
            <span>📚</span> My Resources
          </button>
          <button className="nav-btn" onClick={handleExportCSV} style={{ padding: '12px 16px', background: 'transparent', border: 'none', color: 'var(--muted)', textAlign: 'left', display: 'flex', alignItems: 'center', gap: '12px', fontSize: '14px', fontWeight: '600', cursor: 'pointer', borderRadius: '12px' }}>
            <span>📊</span> Export Data
          </button>
          <button className="nav-btn" onClick={() => setShowSupport(true)} style={{ padding: '12px 16px', background: 'transparent', border: 'none', color: 'var(--muted)', textAlign: 'left', display: 'flex', alignItems: 'center', gap: '12px', fontSize: '14px', fontWeight: '600', cursor: 'pointer', borderRadius: '12px' }}>
            <span>☕</span> Support Developer
          </button>
          <button className="nav-btn" onClick={handleWhatsNew} style={{ padding: '12px 16px', background: 'transparent', border: 'none', color: 'var(--muted)', textAlign: 'left', display: 'flex', alignItems: 'center', gap: '12px', fontSize: '14px', fontWeight: '600', cursor: 'pointer', borderRadius: '12px' }}>
            <span>✨</span> What's New
          </button>
          <a href="mailto:suklalgorai@gmail.com?subject=Attendance App Feedback" className="nav-btn" style={{ padding: '12px 16px', background: 'transparent', border: 'none', color: 'var(--muted)', textAlign: 'left', display: 'flex', alignItems: 'center', gap: '12px', fontSize: '14px', fontWeight: '600', cursor: 'pointer', borderRadius: '12px', textDecoration: 'none' }}>
            <span>✉️</span> Send Feedback
          </a>
          <button className="nav-btn" onClick={handleShare} style={{ padding: '12px 16px', background: 'transparent', border: 'none', color: 'var(--muted)', textAlign: 'left', display: 'flex', alignItems: 'center', gap: '12px', fontSize: '14px', fontWeight: '600', cursor: 'pointer', borderRadius: '12px' }}>
            <span>🔗</span> Share App
          </button>
        </div>
      </nav>

      {showSupport && <SupportModal onClose={() => setShowSupport(false)} />}

      {/* Main Content Area */}
      <main className="main-content">
        <div className="content-inner">
          {children}
        </div>
      </main>
    </div>
  );
}
