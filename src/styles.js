export const CSS = `
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap');

body {
  margin: 0;
  padding: 0;
  background-color: #09090b; /* Pitch black / dark gray */
  background-image: radial-gradient(rgba(255, 255, 255, 0.06) 1px, transparent 1px);
  background-size: 24px 24px;
  background-attachment: fixed;
  color: #FAFAFA;
  font-family: 'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.app-root {
  --ink: transparent;
  --surface: #18181b; /* Solid dark gray, no blur */
  --surface-hover: #27272a;
  --rule: #27272a;
  --rule-bright: #3f3f46;
  --paper: #FAFAFA;
  --muted: #a1a1aa;
  
  --ink-green: #10b981;
  --ink-green-soft: rgba(16, 185, 129, 0.15);
  --pen-red: #f43f5e;
  --pen-red-soft: rgba(244, 63, 94, 0.15);
  --amber: #f59e0b;
  --amber-soft: rgba(245, 158, 11, 0.15);
  --glass-border: #27272a;

  background: var(--ink);
  color: var(--paper);
  font-family: 'Outfit', sans-serif;
  max-width: 440px;
  margin: 0 auto;
  padding: 32px 16px 60px;
  min-height: 100vh;
  box-sizing: border-box;
}

.app-root * { box-sizing: border-box; font-family: 'Outfit', sans-serif; }
.loading { text-align: center; padding: 60px 0; color: var(--muted); font-size: 16px; font-weight: 500; }

.header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 28px; }
.eyebrow { font-size: 12px; color: var(--amber); letter-spacing: 1px; margin-bottom: 6px; font-weight: 600; text-transform: uppercase; }
.course-name { font-size: 28px; font-weight: 800; color: #fff; letter-spacing: -0.5px; }
.header-right { display: flex; align-items: center; gap: 12px; }
.streak { background: var(--amber-soft); color: var(--amber); padding: 6px 14px; border-radius: 999px; font-size: 14px; font-weight: 700; border: 1px solid rgba(245, 158, 11, 0.3); }
.icon-btn { background: var(--surface); border: 1px solid var(--glass-border); color: var(--paper); width: 44px; height: 44px; border-radius: 12px; font-size: 20px; cursor: pointer; transition: all 0.2s ease; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
.icon-btn:hover { background: var(--surface-hover); transform: translateY(-2px); border-color: var(--rule-bright); }

.card { 
  background: var(--surface); 
  border: 1px solid var(--glass-border); 
  border-radius: 24px; 
  padding: 24px; 
  margin-bottom: 16px; 
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
}
.card-title { font-size: 13px; color: var(--muted); margin-bottom: 20px; letter-spacing: 1px; font-weight: 600; text-transform: uppercase; }

.hero-card { display: flex; flex-direction: column; align-items: center; padding: 40px 20px; position: relative; overflow: hidden; }
/* Instead of a hazy background, give the card a sharp colored border and subtle inner shadow */
.hero-card.safe { border: 1px solid rgba(16, 185, 129, 0.4); box-shadow: inset 0 0 40px rgba(16, 185, 129, 0.05), 0 10px 30px rgba(0,0,0,0.5); }
.hero-card.danger { border: 1px solid rgba(244, 63, 94, 0.4); box-shadow: inset 0 0 40px rgba(244, 63, 94, 0.05), 0 10px 30px rgba(0,0,0,0.5); }
.hero-card.none { border: 1px solid rgba(245, 158, 11, 0.4); box-shadow: inset 0 0 40px rgba(245, 158, 11, 0.05), 0 10px 30px rgba(0,0,0,0.5); }

.hero-sub { color: var(--muted); font-size: 15px; margin-top: 24px; text-align: center; }
.hero-sub strong { color: var(--paper); font-weight: 700; font-size: 17px; }

.banner { border-radius: 16px; padding: 18px 20px; font-size: 15px; margin-bottom: 20px; line-height: 1.6; border: 1px solid transparent; font-weight: 500; }
.banner-safe { background: var(--ink-green-soft); color: #34d399; border-color: rgba(16, 185, 129, 0.3); }
.banner-danger { background: var(--pen-red-soft); color: #fb7185; border-color: rgba(244, 63, 94, 0.3); }
.banner-none { background: var(--surface-hover); color: var(--paper); border-color: var(--glass-border); }
.banner strong { font-weight: 800; color: #fff; }

.badges-row { display: flex; flex-wrap: wrap; gap: 16px; }
.badge { display: flex; flex-direction: column; align-items: center; gap: 8px; font-size: 13px; color: var(--paper); width: 60px; font-weight: 600; transition: transform 0.2s ease; }
.badge:hover { transform: translateY(-3px); }
.badge-dot { width: 40px; height: 40px; border-radius: 50%; box-shadow: inset 0 -4px 8px rgba(0,0,0,0.4), 0 6px 12px rgba(0,0,0,0.3); border: 2px solid rgba(255,255,255,0.1); }

.register-list { display: flex; flex-direction: column; gap: 8px; max-height: 480px; overflow-y: auto; padding-right: 8px; margin-right: -8px; }
.register-list::-webkit-scrollbar { width: 6px; }
.register-list::-webkit-scrollbar-thumb { background: var(--rule-bright); border-radius: 6px; }

.day-row { border-radius: 14px; transition: background 0.2s; border: 1px solid transparent; }
.day-row:hover { background: var(--surface-hover); border-color: var(--glass-border); }
.day-row-main { display: flex; justify-content: space-between; align-items: center; padding: 14px 12px; cursor: pointer; }
.day-date { font-size: 15px; display: flex; align-items: center; gap: 12px; font-weight: 600; }
.today-tag { font-size: 11px; background: var(--ink-green); color: #fff; padding: 4px 10px; border-radius: 999px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; box-shadow: 0 4px 10px rgba(16,185,129,0.3); }
.day-status { font-size: 14px; font-weight: 700; }

.day-editor { padding: 4px 12px 18px; animation: slideDown 0.2s ease-out forwards; }
@keyframes slideDown { from { opacity: 0; transform: translateY(-5px); } to { opacity: 1; transform: translateY(0); } }

.quick-actions { display: flex; flex-wrap: wrap; gap: 10px; }
.custom-editor { display: flex; flex-direction: column; gap: 12px; background: #09090b; padding: 16px; border-radius: 14px; border: 1px solid var(--rule-bright); }
.custom-row { display: flex; justify-content: space-between; align-items: center; font-size: 15px; font-weight: 600; }
.custom-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 8px; }

button { font-family: inherit; }
.btn-present, .btn-absent, .btn-ghost, .btn-clear {
  border: none; border-radius: 12px; padding: 12px 18px; font-size: 15px; font-weight: 700; cursor: pointer; transition: all 0.2s ease;
}
/* Solid bold colors for buttons */
.btn-present { background: var(--ink-green); color: #fff; box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3); }
.btn-present:hover { transform: translateY(-2px); box-shadow: 0 6px 16px rgba(16, 185, 129, 0.4); background: #34d399; }
.btn-absent { background: var(--pen-red); color: #fff; box-shadow: 0 4px 12px rgba(244, 63, 94, 0.3); }
.btn-absent:hover { transform: translateY(-2px); box-shadow: 0 6px 16px rgba(244, 63, 94, 0.4); background: #fb7185; }
.btn-ghost { background: var(--surface-hover); color: var(--paper); border: 1px solid var(--rule-bright); }
.btn-ghost:hover { background: #3f3f46; transform: translateY(-2px); }
.btn-clear { background: transparent; color: var(--muted); border: 1px solid var(--rule); }
.btn-clear:hover { background: var(--pen-red-soft); color: var(--pen-red); border-color: rgba(244, 63, 94, 0.3); }
.btn-wide { width: 100%; margin-top: 16px; padding: 16px; font-size: 16px; }

.stepper { display: flex; align-items: center; gap: 14px; background: #09090b; border-radius: 12px; padding: 6px 10px; border: 1px solid var(--rule-bright); }
.stepper button { background: none; border: none; color: var(--paper); font-size: 20px; width: 36px; height: 36px; cursor: pointer; border-radius: 10px; display: flex; align-items: center; justify-content: center; transition: background 0.2s; }
.stepper button:hover { background: var(--rule-bright); }
.stepper span { min-width: 28px; text-align: center; font-weight: 800; font-size: 17px; }

.onboard { padding: 40px 10px; animation: fadeIn 0.5s ease-out; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.onboard h1 { font-family: 'Outfit', sans-serif; font-size: 36px; margin-bottom: 12px; font-weight: 800; color: #fff; letter-spacing: -1px; }
.onboard-sub { color: var(--muted); font-size: 16px; margin-bottom: 32px; line-height: 1.6; font-weight: 500; }
.field { display: flex; flex-direction: column; gap: 8px; margin-bottom: 24px; font-size: 14px; color: var(--muted); font-weight: 600; }
.field span { margin-left: 4px; }
.field input {
  background: #09090b; border: 1px solid var(--rule-bright); border-radius: 12px; padding: 16px 18px;
  color: var(--paper); font-size: 16px; font-family: inherit; transition: all 0.2s; font-weight: 500;
}
.field input:focus { outline: none; border-color: var(--amber); box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.2); }
.min-row { display: flex; align-items: center; gap: 14px; }
.min-row input { width: 120px; font-weight: 700; font-size: 18px; }

.day-picker { display: flex; gap: 10px; }
.day-chip {
  width: 42px; height: 42px; border-radius: 12px; border: 1px solid var(--rule-bright);
  background: #09090b; color: var(--muted); font-size: 15px; font-weight: 700; cursor: pointer; transition: all 0.2s; display: flex; align-items: center; justify-content: center; padding: 0;
}
.day-chip:hover { background: var(--surface-hover); }
.day-chip-on { background: var(--ink-green); color: #fff; border-color: transparent; box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3); }
.day-chip-on:hover { background: #34d399; transform: translateY(-2px); }

.reminder-banner {
  background: var(--pen-red-soft); color: #fb7185; border: 1px solid rgba(244, 63, 94, 0.3);
  border-radius: 16px; padding: 16px 20px; font-size: 15px; margin-bottom: 20px; font-weight: 600;
}

.timetable-editor { display: flex; flex-direction: column; gap: 12px; }
.timetable-row { display: flex; align-items: center; gap: 14px; }
.timetable-day { width: 44px; font-size: 14px; color: var(--muted); font-weight: 700; flex-shrink: 0; text-transform: uppercase; }
.timetable-row input {
  flex: 1; background: #09090b; border: 1px solid var(--rule-bright); border-radius: 12px;
  padding: 12px 16px; color: var(--paper); font-size: 15px; font-family: inherit; transition: all 0.2s; font-weight: 500;
}
.timetable-row input:focus { outline: none; border-color: var(--amber); box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.2); }
.hint { font-size: 13px; color: var(--muted); line-height: 1.5; margin-top: 6px; font-weight: 500; }

.periods-checklist { display: flex; flex-direction: column; gap: 12px; }
.period-chip {
  display: inline-block; margin: 4px 8px 4px 0; padding: 10px 18px; border-radius: 12px;
  font-size: 14px; font-weight: 700; border: 1px solid transparent; cursor: pointer; transition: all 0.2s;
}
.period-chip-present { background: var(--ink-green-soft); color: #34d399; border: 1px solid rgba(16, 185, 129, 0.3); }
.period-chip-present:hover { background: rgba(16, 185, 129, 0.25); transform: translateY(-1px); }
.period-chip-absent { background: var(--pen-red-soft); color: #fb7185; border: 1px solid rgba(244, 63, 94, 0.3); text-decoration: line-through; opacity: 0.8; }

.toast { position: fixed; bottom: 32px; left: 50%; transform: translateX(-50%); background: #fff; color: #000; border: none; padding: 14px 24px; border-radius: 14px; font-size: 15px; font-weight: 700; box-shadow: 0 10px 30px rgba(0,0,0,0.5); z-index: 100; animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1); }
@keyframes slideUp { from { opacity: 0; transform: translate(-50%, 20px); } to { opacity: 1; transform: translate(-50%, 0); } }

.auth-root {
  display: flex;
  align-items: center;
  justify-content: center;
}
.auth-card {
  width: 100%;
  max-width: 400px;
  padding: 40px 32px;
}
.auth-error {
  background: var(--pen-red-soft);
  color: #fb7185;
  padding: 12px 16px;
  border-radius: 12px;
  font-size: 14px;
  margin-top: 12px;
  font-weight: 600;
  border: 1px solid rgba(244, 63, 94, 0.3);
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
  margin: 20px 0;
  color: var(--muted);
  font-size: 13px;
  font-weight: 600;
  text-transform: uppercase;
}
.auth-divider::before, .auth-divider::after {
  content: '';
  flex: 1;
  border-bottom: 1px solid var(--rule-bright);
}
.auth-divider span {
  padding: 0 12px;
}
.btn-google {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  background: #fff;
  color: #000;
  border: 1px solid transparent;
  font-weight: 700;
}
.btn-google:hover {
  background: #e2e8f0;
  transform: translateY(-2px);
}
`;
