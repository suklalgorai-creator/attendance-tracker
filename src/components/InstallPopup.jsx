import React from 'react';

export default function InstallPopup({ onInstall, onDismiss }) {
  return (
    <div className="modal-overlay" onClick={onDismiss}>
      <div className="card modal-content" style={{ maxWidth: '400px', textAlign: 'center' }} onClick={e => e.stopPropagation()}>
        <div style={{ fontSize: '48px', marginBottom: '16px' }}>📱</div>
        <h3 style={{ margin: '0 0 8px 0' }}>Install App</h3>
        <p style={{ color: 'var(--muted)', marginBottom: '24px' }}>Install this app on your home screen for quick and easy access.</p>
        <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
          <button className="btn-ghost" onClick={onDismiss} style={{ flex: 1 }}>Not Now</button>
          <button className="btn-present" onClick={onInstall} style={{ flex: 1 }}>Install</button>
        </div>
      </div>
    </div>
  );
}
