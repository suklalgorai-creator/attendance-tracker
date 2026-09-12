export const CSS = `
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap');

/* ----- DEFAULT THEME (DARK) ----- */
body {
  --bg-primary: #050505;
  --mesh-1: rgba(16, 185, 129, 0.15); /* Emerald glow */
  --mesh-2: rgba(244, 63, 94, 0.15);  /* Rose glow */
  --mesh-3: rgba(59, 130, 246, 0.15); /* Blue glow */
  
  --surface: rgba(24, 24, 27, 0.65);
  --surface-hover: rgba(39, 39, 42, 0.85);
  --surface-solid: #18181b;
  --glass-border: rgba(255, 255, 255, 0.08);
  --rule: rgba(255, 255, 255, 0.06);
  --rule-bright: rgba(255, 255, 255, 0.12);
  
  --paper: #FFFFFF;
  --muted: #A1A1AA;
  --text-gradient-start: #FFFFFF;
  --text-gradient-end: #A1A1AA;
  
  --ink-green: #10B981;
  --ink-green-soft: rgba(16, 185, 129, 0.15);
  --pen-red: #F43F5E;
  --pen-red-soft: rgba(244, 63, 94, 0.15);
  --amber: #F59E0B;
  --amber-soft: rgba(245, 158, 11, 0.15);
  
  --card-shadow: 0 10px 40px rgba(0, 0, 0, 0.4);
  --card-shadow-hover: 0 16px 50px rgba(0, 0, 0, 0.5);
  --input-bg: rgba(0, 0, 0, 0.4);
}

/* ----- LIGHT THEME ----- */
body[data-theme="light"] {
  --bg-primary: #F8FAFC;
  --mesh-1: rgba(52, 211, 153, 0.4);  /* Vibrant Emerald */
  --mesh-2: rgba(251, 113, 133, 0.3); /* Vibrant Rose */
  --mesh-3: rgba(96, 165, 250, 0.4);  /* Vibrant Blue */
  
  --surface: rgba(255, 255, 255, 0.7);
  --surface-hover: rgba(255, 255, 255, 0.95);
  --surface-solid: #FFFFFF;
  --glass-border: rgba(0, 0, 0, 0.05);
  --rule: rgba(0, 0, 0, 0.06);
  --rule-bright: rgba(0, 0, 0, 0.12);
  
  --paper: #0F172A;
  --muted: #64748B;
  --text-gradient-start: #0F172A;
  --text-gradient-end: #475569;
  
  --card-shadow: 0 10px 40px rgba(0, 0, 0, 0.05);
  --card-shadow-hover: 0 16px 50px rgba(0, 0, 0, 0.08);
  --input-bg: rgba(255, 255, 255, 0.5);
}

body {
  margin: 0;
  padding: 0;
  background-color: var(--bg-primary);
  color: var(--paper);
  font-family: 'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  transition: background-color 0.5s ease;
  position: relative;
  overflow-x: hidden;
}

/* --- ANIMATED MESH BACKGROUND --- */
body::before, body::after, .app-root::before {
  content: "";
  position: fixed;
  border-radius: 50%;
  filter: blur(100px);
  z-index: -1;
  animation: float 20s infinite alternate cubic-bezier(0.45, 0.05, 0.55, 0.95);
  opacity: 0.8;
  transition: all 0.8s ease;
}
body::before {
  top: -10%; left: -10%;
  width: 60vw; height: 60vh;
  background: var(--mesh-1);
}
body::after {
  bottom: -10%; right: -10%;
  width: 50vw; height: 50vh;
  background: var(--mesh-2);
  animation-delay: -5s;
}
.app-root::before {
  top: 40%; left: 30%;
  width: 40vw; height: 40vh;
  background: var(--mesh-3);
  animation-delay: -10s;
}

@keyframes float {
  0% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(10%, 15%) scale(1.1); }
  100% { transform: translate(-5%, -10%) scale(0.9); }
}

.app-root {
  max-width: 480px;
  margin: 0 auto;
  padding: 40px 20px 80px;
  min-height: 100vh;
  box-sizing: border-box;
}
.app-root * { box-sizing: border-box; font-family: 'Outfit', sans-serif; }

.loading { text-align: center; padding: 60px 0; color: var(--muted); font-size: 16px; font-weight: 500; }

.header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; position: relative; z-index: 100; }
.eyebrow { font-size: 13px; color: var(--amber); letter-spacing: 1.5px; margin-bottom: 8px; font-weight: 700; text-transform: uppercase; }
.course-name { 
  font-size: 36px; 
  font-weight: 800; 
  letter-spacing: -0.5px; 
  text-transform: capitalize;
  background: linear-gradient(135deg, var(--text-gradient-start) 0%, var(--text-gradient-end) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  line-height: 1.1;
  transition: all 0.3s;
}
.header-right { display: flex; align-items: center; gap: 12px; }
.streak { background: var(--amber-soft); color: var(--amber); padding: 8px 16px; border-radius: 999px; font-size: 14px; font-weight: 700; border: 1px solid rgba(245, 158, 11, 0.3); }

/* Buttons & Profile */
.icon-btn, .profile-btn { 
  background: var(--surface); 
  border: 1px solid var(--glass-border); 
  color: var(--paper); 
  width: 48px; height: 48px; 
  border-radius: 14px; 
  font-size: 20px; 
  cursor: pointer; 
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); 
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: 0 4px 6px rgba(0,0,0,0.05); 
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  overflow: hidden;
  position: relative;
  z-index: 50;
}
.icon-btn:hover, .profile-btn:hover { 
  background: var(--surface-hover); 
  transform: translateY(-2px); 
  border-color: var(--rule-bright); 
  box-shadow: 0 8px 15px rgba(0,0,0,0.1); 
}
.profile-pic { width: 100%; height: 100%; object-fit: cover; }
.profile-fallback { font-weight: 800; font-size: 22px; color: var(--paper); }

/* Cards (Glassmorphism) */
.card { 
  background: var(--surface);
  border: 1.5px solid;
  border-top-color: rgba(16, 185, 129, 0.4);   /* Emerald */
  border-right-color: rgba(59, 130, 246, 0.4); /* Blue */
  border-bottom-color: rgba(244, 63, 94, 0.4); /* Rose */
  border-left-color: rgba(245, 158, 11, 0.4);  /* Amber */
  border-radius: 16px; 
  padding: 16px; 
  margin-bottom: 16px; 
  box-shadow: var(--card-shadow);
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  transition: all 0.3s ease;
}
.card:hover {
  box-shadow: 0 10px 30px rgba(59, 130, 246, 0.15);
  background: var(--surface-hover);
  border-top-color: rgba(16, 185, 129, 0.8);
  border-right-color: rgba(59, 130, 246, 0.8);
  border-bottom-color: rgba(244, 63, 94, 0.8);
  border-left-color: rgba(245, 158, 11, 0.8);
}
.card-title { font-size: 13px; color: var(--muted); margin-bottom: 16px; letter-spacing: 1.5px; font-weight: 700; text-transform: uppercase; }
.view-toggles { display: flex; gap: 4px; background: var(--rule); padding: 4px; border-radius: 8px; }
.view-toggles button { background: transparent; border: none; color: var(--muted); font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 6px; cursor: pointer; transition: all 0.2s; text-transform: uppercase; letter-spacing: 0.5px; }
.view-toggles button:hover { color: var(--paper); }
.view-toggles button.active { background: var(--surface); color: var(--paper); box-shadow: 0 2px 8px rgba(0,0,0,0.1); }

/* Modal System */
.modal-overlay {
  position: fixed; top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  z-index: 1000;
  display: flex; justify-content: center; align-items: center;
  padding: 20px;
  animation: fadeIn 0.3s ease;
}
.modal-content {
  width: 100%; max-width: 600px; max-height: 90vh;
  overflow-y: auto;
  margin: 0; position: relative;
  animation: slideUp 0.3s ease;
}
.modal-content::-webkit-scrollbar { width: 6px; }
.modal-content::-webkit-scrollbar-thumb { background: var(--rule-bright); border-radius: 6px; }
.modal-close {
  position: absolute; top: 20px; right: 20px;
  background: var(--rule); border: none;
  width: 32px; height: 32px; border-radius: 50%;
  cursor: pointer; display: flex; justify-content: center; align-items: center;
  font-size: 14px; color: var(--paper); z-index: 10;
  transition: all 0.2s;
}
.modal-close:hover { background: var(--glass-border); transform: scale(1.1); }

@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
@keyframes slideUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

.hero-card { display: flex; flex-direction: column; align-items: center; padding: 24px 16px; position: relative; overflow: hidden; }
.hero-card.safe { border: 1.5px solid rgba(16, 185, 129, 0.4); }
.hero-card.danger { border: 1.5px solid rgba(244, 63, 94, 0.4); }
.hero-card.none { border: 1.5px solid rgba(245, 158, 11, 0.4); }

.hero-sub { color: var(--muted); font-size: 14px; margin-top: 16px; text-align: center; line-height: 1.4; }
.hero-sub strong { color: var(--paper); font-weight: 700; font-size: 15px; }

.banner { 
  border-radius: 12px; 
  padding: 12px 16px; 
  font-size: 14px; 
  margin-bottom: 16px; 
  line-height: 1.6; 
  border: 1px solid transparent; 
  font-weight: 500; 
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}
.banner-safe { background: rgba(16, 185, 129, 0.1); color: var(--ink-green); border-color: rgba(16, 185, 129, 0.2); }
.banner-danger { background: rgba(244, 63, 94, 0.1); color: var(--pen-red); border-color: rgba(244, 63, 94, 0.2); }
.banner-none { background: rgba(161, 161, 170, 0.1); color: var(--muted); border-color: var(--rule-bright); }
.banner strong { font-weight: 800; color: var(--paper); }

.badges-row { display: flex; flex-wrap: wrap; gap: 20px; }
.badge { display: flex; flex-direction: column; align-items: center; gap: 10px; font-size: 13px; color: var(--paper); width: 64px; font-weight: 600; transition: transform 0.2s ease; }
.badge:hover { transform: translateY(-4px); }
.badge-dot { width: 44px; height: 44px; border-radius: 50%; box-shadow: inset 0 -4px 8px rgba(0,0,0,0.1), 0 6px 12px rgba(0,0,0,0.1); border: 2px solid var(--glass-border); }

.register-list { display: flex; flex-direction: column; gap: 10px; max-height: 500px; overflow-y: auto; padding-right: 12px; margin-right: -12px; }
.register-list::-webkit-scrollbar { width: 6px; }
.register-list::-webkit-scrollbar-thumb { background: var(--rule-bright); border-radius: 6px; }

.day-row { border-radius: 12px; transition: all 0.2s; border: 1px solid transparent; background: var(--rule); margin-bottom: 6px; }
.day-row:hover:not(.future-row) { background: var(--rule-bright); border-color: var(--glass-border); transform: scale(1.01); }
.main-card-row { border: 2px solid var(--ink-green) !important; box-shadow: 0 4px 12px rgba(16, 185, 129, 0.15); margin: 12px 0; background: var(--surface); }
.future-row { opacity: 0.7; filter: grayscale(50%); }

.day-row-main { display: flex; justify-content: space-between; align-items: center; padding: 12px 14px; cursor: pointer; }
.day-date { font-size: 15px; display: flex; align-items: center; gap: 10px; font-weight: 600; color: var(--paper); }
.today-tag { font-size: 10px; background: var(--ink-green); color: #fff; padding: 3px 8px; border-radius: 999px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px; box-shadow: 0 4px 10px rgba(16,185,129,0.3); }
.day-status { font-size: 14px; font-weight: 800; }

.day-editor { padding: 4px 16px 20px; animation: slideDown 0.2s ease-out forwards; }
@keyframes slideDown { from { opacity: 0; transform: translateY(-5px); } to { opacity: 1; transform: translateY(0); } }

.quick-actions { display: flex; flex-wrap: wrap; gap: 12px; }
.custom-editor { display: flex; flex-direction: column; gap: 16px; background: var(--input-bg); padding: 20px; border-radius: 18px; border: 1px solid var(--rule-bright); }
.custom-row { display: flex; justify-content: space-between; align-items: center; font-size: 15px; font-weight: 600; }
.custom-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 8px; }

button { font-family: inherit; }
.btn-present, .btn-absent, .btn-ghost, .btn-clear {
  border: none; border-radius: 14px; padding: 14px 20px; font-size: 15px; font-weight: 700; cursor: pointer; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
.btn-present { background: var(--ink-green); color: #fff; box-shadow: 0 4px 12px rgba(16, 185, 129, 0.2); }
.btn-present:hover { transform: translateY(-2px); box-shadow: 0 8px 20px rgba(16, 185, 129, 0.4); filter: brightness(1.1); }
.btn-absent { background: var(--pen-red); color: #fff; box-shadow: 0 4px 12px rgba(244, 63, 94, 0.2); }
.btn-absent:hover { transform: translateY(-2px); box-shadow: 0 8px 20px rgba(244, 63, 94, 0.4); filter: brightness(1.1); }
.btn-ghost { background: var(--rule-bright); color: var(--paper); border: 1px solid var(--glass-border); }
.btn-ghost:hover { background: var(--surface-hover); transform: translateY(-2px); border-color: var(--rule-bright); }
.btn-clear { background: transparent; color: var(--muted); border: 1px solid var(--rule); }
.btn-clear:hover { background: var(--pen-red-soft); color: var(--pen-red); border-color: rgba(244, 63, 94, 0.3); }
.btn-wide { width: 100%; margin-top: 16px; padding: 18px; font-size: 16px; }

.stepper { display: flex; align-items: center; gap: 16px; background: var(--input-bg); border-radius: 14px; padding: 6px 12px; border: 1px solid var(--rule-bright); }
.stepper button { background: none; border: none; color: var(--paper); font-size: 22px; width: 40px; height: 40px; cursor: pointer; border-radius: 10px; display: flex; align-items: center; justify-content: center; transition: background 0.2s; }
.stepper button:hover { background: var(--rule-bright); }
.stepper span { min-width: 32px; text-align: center; font-weight: 800; font-size: 18px; }

.onboard { padding: 40px 10px; animation: fadeIn 0.5s ease-out; }
@keyframes fadeIn { from { opacity: 0; transform: scale(0.98); } to { opacity: 1; transform: scale(1); } }
.onboard h1 { font-size: 40px; margin-bottom: 12px; font-weight: 800; letter-spacing: -1px; text-align: center; background: linear-gradient(135deg, var(--text-gradient-start) 0%, var(--text-gradient-end) 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
.onboard-sub { color: var(--muted); font-size: 16px; margin-bottom: 40px; line-height: 1.6; font-weight: 500; text-align: center; }

.field { display: flex; flex-direction: column; gap: 10px; margin-bottom: 24px; font-size: 14px; color: var(--muted); font-weight: 600; }
.field span { margin-left: 4px; }
.field input {
  background: var(--input-bg); border: 1px solid var(--rule-bright); border-radius: 16px; padding: 18px 20px;
  color: var(--paper); font-size: 16px; font-family: inherit; transition: all 0.3s; font-weight: 500;
}
.field input:focus { outline: none; border-color: var(--amber); box-shadow: 0 0 0 4px var(--amber-soft); background: var(--surface-solid); }
.min-row { display: flex; align-items: center; gap: 16px; }
.min-row input { width: 120px; font-weight: 700; font-size: 20px; text-align: center; }

.day-picker { display: flex; gap: 12px; }
.day-chip {
  width: 46px; height: 46px; border-radius: 14px; border: 1px solid var(--rule-bright);
  background: var(--input-bg); color: var(--muted); font-size: 15px; font-weight: 700; cursor: pointer; transition: all 0.2s; display: flex; align-items: center; justify-content: center; padding: 0;
}
.day-chip:hover { background: var(--rule-bright); }
.day-chip-on { background: var(--ink-green); color: #fff; border-color: transparent; box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3); }
.day-chip-on:hover { background: #34d399; transform: translateY(-2px); }

.reminder-banner {
  background: var(--pen-red-soft); color: var(--pen-red); border: 1px solid rgba(244, 63, 94, 0.2);
  border-radius: 20px; padding: 20px 24px; font-size: 15px; margin-bottom: 24px; font-weight: 600;
  backdrop-filter: blur(10px);
}

.timetable-editor { display: flex; flex-direction: column; gap: 12px; }
.timetable-row { display: flex; align-items: center; gap: 16px; }
.timetable-day { width: 48px; font-size: 14px; color: var(--muted); font-weight: 700; flex-shrink: 0; text-transform: uppercase; }
.timetable-row input {
  flex: 1; background: var(--input-bg); border: 1px solid var(--rule-bright); border-radius: 14px;
  padding: 14px 16px; color: var(--paper); font-size: 15px; font-family: inherit; transition: all 0.2s; font-weight: 500;
}
.timetable-row input:focus { outline: none; border-color: var(--amber); box-shadow: 0 0 0 3px var(--amber-soft); }
.hint { font-size: 13px; color: var(--muted); line-height: 1.5; margin-top: 6px; font-weight: 500; }

.periods-checklist { display: flex; flex-direction: column; gap: 12px; }
.period-chip {
  display: inline-block; margin: 4px 8px 4px 0; padding: 12px 20px; border-radius: 14px;
  font-size: 15px; font-weight: 700; border: 1px solid transparent; cursor: pointer; transition: all 0.2s;
}
.period-chip-present { background: var(--ink-green-soft); color: var(--ink-green); border: 1px solid rgba(16, 185, 129, 0.2); }
.period-chip-present:hover { filter: brightness(1.1); transform: translateY(-1px); }
.period-chip-absent { background: var(--pen-red-soft); color: var(--pen-red); border: 1px solid rgba(244, 63, 94, 0.2); text-decoration: line-through; opacity: 0.8; }

.toast { position: fixed; bottom: 40px; left: 50%; transform: translateX(-50%); background: var(--paper); color: var(--bg-primary); border: none; padding: 16px 28px; border-radius: 16px; font-size: 16px; font-weight: 700; box-shadow: 0 20px 40px rgba(0,0,0,0.3); z-index: 100; animation: slideUp 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
@keyframes slideUp { from { opacity: 0; transform: translate(-50%, 20px) scale(0.95); } to { opacity: 1; transform: translate(-50%, 0) scale(1); } }

/* Auth */
.auth-root {
  display: flex;
  align-items: center;
  justify-content: center;
}
.auth-card {
  width: 100%;
  max-width: 420px;
  padding: 48px 32px;
}
.auth-error {
  background: var(--pen-red-soft);
  color: var(--pen-red);
  padding: 14px 18px;
  border-radius: 14px;
  font-size: 14px;
  margin-top: 16px;
  font-weight: 600;
  border: 1px solid rgba(244, 63, 94, 0.2);
}
.auth-toggle {
  margin-top: 32px;
  display: flex;
  flex-direction: column;
  align-items: center;
  border-top: 1px solid var(--rule-bright);
  padding-top: 24px;
}
.auth-divider {
  display: flex;
  align-items: center;
  text-align: center;
  margin: 24px 0;
  color: var(--muted);
  font-size: 13px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
}
.auth-divider::before, .auth-divider::after {
  content: '';
  flex: 1;
  border-bottom: 1px solid var(--rule-bright);
}
.auth-divider span {
  padding: 0 16px;
}
.btn-google {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  background: #fff;
  color: #000;
  border: 1px solid transparent;
  font-weight: 800;
}
.btn-google:hover {
  background: #f8fafc;
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(255,255,255,0.1);
}

/* Admin Dashboard Styles */
.admin-stat-box {
  background: var(--surface-hover);
  border: 1px solid var(--rule-bright);
  border-radius: 20px;
  padding: 32px 24px;
  flex: 1;
  min-width: 140px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.stat-value {
  font-size: 48px;
  font-weight: 800;
  color: var(--ink-green);
  line-height: 1;
  margin-bottom: 12px;
}
.stat-label {
  font-size: 15px;
  color: var(--muted);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
}
.admin-user-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.admin-user-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  background: var(--input-bg);
  border: 1px solid var(--rule-bright);
  border-radius: 18px;
  transition: all 0.2s;
}
.admin-user-row:hover {
  background: var(--surface-hover);
  border-color: var(--glass-border);
}
.admin-user-info {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.admin-user-info strong {
  font-size: 16px;
  color: var(--paper);
  font-weight: 700;
}
.admin-user-info span {
  font-size: 14px;
  color: var(--muted);
  font-weight: 500;
}
.admin-user-stats {
  font-size: 15px;
  font-weight: 800;
  color: var(--amber);
  background: var(--amber-soft);
  padding: 8px 16px;
  border-radius: 999px;
}

/* Heatmap */
.heatmap-container { display: flex; gap: 8px; margin-top: 16px; align-items: flex-start; }
.heatmap-labels-y { display: flex; flex-direction: column; justify-content: space-between; font-size: 11px; color: var(--muted); height: 98px; padding-top: 14px; margin-right: 4px; }
.heatmap-grid-scroll { flex: 1; overflow-x: auto; padding-bottom: 8px; }
.heatmap-grid-scroll::-webkit-scrollbar { height: 6px; }
.heatmap-grid-scroll::-webkit-scrollbar-thumb { background: var(--rule-bright); border-radius: 6px; }
.heatmap-grid { display: flex; gap: 4px; }
.heatmap-column { display: flex; flex-direction: column; gap: 4px; }
.heatmap-cell { width: 12px; height: 12px; border-radius: 3px; cursor: crosshair; transition: transform 0.1s; }
.heatmap-cell:hover { transform: scale(1.3); z-index: 2; position: relative; }
.heat-empty { background: var(--rule); }
.heat-future { background: transparent; }
.heat-holiday { background: var(--rule-bright); }
.heat-present { background: var(--ink-green); }
.heat-absent { background: var(--pen-red); }
.heat-partial { background: var(--amber); }

/* Responsive Grid for Desktop */
.top-dashboard {
  display: flex;
  flex-direction: column;
}
@media (min-width: 1024px) {
  .top-dashboard {
    flex-direction: row;
    align-items: stretch;
    gap: 16px;
    margin-bottom: 16px;
  }
  .top-dashboard .activity-card { flex: 3; margin-bottom: 0; }
  .top-dashboard .badges-card { flex: 2; margin-bottom: 0; display: flex; flex-direction: column; justify-content: center; }
  
  .app-root {
    max-width: 1200px;
    padding: 24px 40px;
  }
  .dashboard-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
    align-items: start;
  }
  .register-list {
    max-height: 600px;
  }
}
@media (max-width: 1023px) {
  .dashboard-grid {
    display: flex;
    flex-direction: column;
    gap: 0;
  }
}
`;
