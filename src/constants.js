export const STORAGE_KEY = 'attendance-register-v1';
export const DEFAULT_MIN = 75;
export const DEFAULT_CLASS_DAYS = [1, 2, 3, 4, 5]; // Mon–Fri (0 = Sun ... 6 = Sat)
export const DAY_LABELS = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

export const BADGES = [
  { id: 'bronze', label: 'Bronze', min: 75, color: '#B97A50' },
  { id: 'silver', label: 'Silver', min: 85, color: '#A9AFC0' },
  { id: 'gold', label: 'Gold', min: 95, color: '#D6A24C' },
];

export const STREAK_BADGES = [
  { id: 'streak7', label: '7-day streak', min: 7 },
  { id: 'streak30', label: '30-day streak', min: 30 },
];
