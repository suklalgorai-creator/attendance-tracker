import React from 'react';

export default function SupportModal({ onClose }) {
  // Safe alternative setup


  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="card modal-content" style={{ textAlign: 'center', padding: '24px 20px', maxWidth: '300px', width: '90%' }} onClick={e => e.stopPropagation()}>
        
        <h2 style={{ fontSize: '18px', fontWeight: '800', margin: '0 0 4px 0' }}>Support the Developer</h2>
        <p style={{ color: 'var(--muted)', fontSize: '13px', marginBottom: '24px', lineHeight: '1.4' }}>
          Thank you for using this app! If this app helps you, please support us by sharing it with your friends.
        </p>

        <button className="btn-ghost btn-wide" onClick={onClose} style={{ fontWeight: '600', padding: '10px' }}>
          Close
        </button>
      </div>
    </div>
  );
}
