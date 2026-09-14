import React from 'react';

export default function StreakPopup({ streak, onClose }) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="card streak-popup-content" onClick={e => e.stopPropagation()}>
        <div className="streak-fire-large">🔥</div>
        <div className="streak-popup-title">{streak} Day Streak!</div>
        <p className="streak-popup-desc">You're on fire! Keep attending classes to maintain your streak.</p>
        <button className="btn-present btn-wide" onClick={onClose}>Awesome</button>
      </div>
    </div>
  );
}
