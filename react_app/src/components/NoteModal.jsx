import React, { useState, useEffect } from 'react';

const COLORS = [
  { id: 'yellow', value: '#fef3c7' }, // Amber soft
  { id: 'green', value: '#d1fae5' },  // Emerald soft
  { id: 'blue', value: '#dbeafe' },   // Blue soft
  { id: 'pink', value: '#fce7f3' },   // Pink soft
  { id: 'gray', value: '#f3f4f6' },   // Gray soft
  { id: 'dark', value: 'var(--input-bg)' } // Default dark
];

export default function NoteModal({ initialData, onSave, onClose }) {
  const [content, setContent] = useState('');
  const [color, setColor] = useState('var(--input-bg)');
  const [reminderDate, setReminderDate] = useState('');

  useEffect(() => {
    if (initialData) {
      setContent(initialData.content || '');
      setColor(initialData.color || 'var(--input-bg)');
      
      if (initialData.reminderDate) {
        // format ISO string to datetime-local format (YYYY-MM-DDThh:mm)
        const dateObj = new Date(initialData.reminderDate);
        // Add local timezone offset
        const tzoffset = (new Date()).getTimezoneOffset() * 60000;
        const localISOTime = (new Date(dateObj - tzoffset)).toISOString().slice(0, -1);
        setReminderDate(localISOTime.substring(0, 16));
      }
    }
  }, [initialData]);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!content.trim()) {
      alert("Note content cannot be empty.");
      return;
    }

    let parsedReminder = null;
    if (reminderDate) {
      parsedReminder = new Date(reminderDate).toISOString();
    }

    onSave({
      content,
      color,
      reminderDate: parsedReminder
    });
  };

  return (
    <div className="modal-overlay" onClick={onClose} style={{ zIndex: 9999 }}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ backgroundColor: 'var(--surface)', border: `2px solid ${color !== 'var(--input-bg)' ? color : 'var(--rule-bright)'}` }}>
        <button className="modal-close" onClick={onClose}>×</button>
        
        <h2 style={{ fontSize: '20px', fontWeight: 800, marginTop: 0, marginBottom: '20px', color: 'var(--paper)' }}>
          {initialData ? 'Edit Note' : 'New Note'}
        </h2>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          
          <div className="field" style={{ marginBottom: 0 }}>
            <span>Note Content</span>
            <textarea 
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="Jot something down..."
              rows={5}
              style={{
                background: 'var(--input-bg)',
                border: '1px solid var(--rule-bright)',
                borderRadius: '16px',
                padding: '16px',
                color: 'var(--paper)',
                fontSize: '15px',
                fontFamily: 'inherit',
                resize: 'vertical',
                width: '100%'
              }}
              autoFocus
            />
          </div>

          <div className="field" style={{ marginBottom: 0 }}>
            <span>Color</span>
            <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
              {COLORS.map((c) => (
                <div 
                  key={c.id}
                  onClick={() => setColor(c.value)}
                  style={{
                    width: '36px',
                    height: '36px',
                    borderRadius: '50%',
                    backgroundColor: c.value,
                    border: color === c.value ? '2px solid var(--paper)' : '1px solid var(--glass-border)',
                    cursor: 'pointer',
                    transform: color === c.value ? 'scale(1.1)' : 'scale(1)',
                    transition: 'all 0.2s'
                  }}
                  title={c.id}
                />
              ))}
            </div>
          </div>

          <div className="field" style={{ marginBottom: '8px' }}>
            <span>Reminder (Optional)</span>
            <input 
              type="datetime-local" 
              value={reminderDate}
              onChange={(e) => setReminderDate(e.target.value)}
              style={{ colorScheme: 'dark' }} // to make icon visible in dark mode
            />
            <div className="hint">We'll send you a push notification at this time.</div>
          </div>

          <button type="submit" className="btn-present" style={{ padding: '16px', marginTop: '8px' }}>
            {initialData ? 'Update Note' : 'Save Note'}
          </button>
        </form>
      </div>
    </div>
  );
}
