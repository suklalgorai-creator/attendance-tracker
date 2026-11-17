import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import NoteModal from '../components/NoteModal';
import ReactMarkdown from 'react-markdown';

export default function NotesPage() {
  const { data, saveSettings } = useApp();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingNote, setEditingNote] = useState(null);

  const notes = data?.notes || [];

  const handleSave = (noteData) => {
    let nextNotes;
    if (editingNote) {
      nextNotes = notes.map((n) => (n.id === editingNote.id ? { ...noteData, id: n.id, createdAt: n.createdAt } : n));
    } else {
      const newId = typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : Date.now().toString();
      nextNotes = [...notes, { ...noteData, id: newId, createdAt: new Date().toISOString() }];
    }
    saveSettings({ notes: nextNotes });
    setIsModalOpen(false);
    setEditingNote(null);
  };

  const handleDelete = (id) => {
    const nextNotes = notes.filter((n) => n.id !== id);
    saveSettings({ notes: nextNotes });
  };

  const openNewNote = () => {
    setEditingNote(null);
    setIsModalOpen(true);
  };

  const openEditNote = (note) => {
    setEditingNote(note);
    setIsModalOpen(true);
  };

  const formatDate = (isoString) => {
    if (!isoString) return '';
    const d = new Date(isoString);
    return d.toLocaleString([], { dateStyle: 'short', timeStyle: 'short' });
  };

  return (
    <div className="notes-container" style={{ paddingBottom: '80px', position: 'relative', minHeight: '100%' }}>
      <div className="dashboard-hero" style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '28px', fontWeight: 800, margin: '0 0 8px 0', color: 'var(--paper)' }}>Sticky Notes</h1>
        <p style={{ color: 'var(--muted)', margin: 0, fontSize: '15px' }}>Quickly jot down important college updates, assignment deadlines, or reminders.</p>
      </div>

      {notes.length === 0 ? (
        <div className="card" style={{ textAlign: 'center', padding: '40px 20px', borderStyle: 'dashed' }}>
          <div style={{ fontSize: '40px', marginBottom: '16px' }}>📝</div>
          <h3 style={{ margin: '0 0 8px 0', color: 'var(--paper)', fontSize: '18px' }}>No Notes Yet</h3>
          <p style={{ color: 'var(--muted)', fontSize: '14px', margin: 0 }}>Tap the + button to create your first sticky note.</p>
        </div>
      ) : (
        <div className="notes-masonry">
          {notes.map((note) => (
            <div 
              key={note.id} 
              className="sticky-note" 
              style={{ backgroundColor: note.color || 'var(--input-bg)' }}
              onClick={() => openEditNote(note)}
            >
              <div className="note-content markdown-body">
                <ReactMarkdown>{note.content}</ReactMarkdown>
              </div>
              
              <div className="note-footer">
                <div className="note-meta">
                  {note.reminderDate && (
                    <span className="note-reminder-badge" title="Reminder set">
                      ⏰ {formatDate(note.reminderDate)}
                    </span>
                  )}
                </div>
                <button 
                  className="note-delete-btn" 
                  onClick={(e) => {
                    e.stopPropagation();
                    if (window.confirm('Delete this note?')) {
                      handleDelete(note.id);
                    }
                  }}
                  title="Delete Note"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      <button className="fab-btn" onClick={openNewNote}>
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
      </button>

      {isModalOpen && (
        <NoteModal 
          initialData={editingNote} 
          onSave={handleSave} 
          onClose={() => setIsModalOpen(false)} 
        />
      )}
    </div>
  );
}
