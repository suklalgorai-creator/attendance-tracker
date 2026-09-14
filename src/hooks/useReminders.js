import { useState, useEffect, useCallback } from 'react';
import { todayStr, isClassDay, getPeriodsForDate } from '../utils/date';

export function useReminders(data) {
  const [permission, setPermission] = useState(
    'Notification' in window ? Notification.permission : 'denied'
  );

  const requestPermission = useCallback(async () => {
    if (!('Notification' in window)) {
      alert('This browser does not support desktop notifications.');
      return;
    }
    const perm = await Notification.requestPermission();
    setPermission(perm);
  }, []);

  useEffect(() => {
    if (permission !== 'granted' || !data) return;

    const checkAndNotify = () => {
      const today = todayStr();
      const classDays = data.classDays || [];
      const records = data.records || {};
      const timetable = data.timetable || {};
      const reminderTime = data.reminderTime || '18:00';
      
      // Check if today is a class day and attendance isn't marked
      if (!isClassDay(today, classDays) || records[today]) return;

      const now = new Date();
      const currentMinutes = now.getHours() * 60 + now.getMinutes();
      const [rh, rm] = reminderTime.split(':').map(Number);
      const reminderMinutes = (rh || 0) * 60 + (rm || 0);

      // Check if it's past reminder time
      if (currentMinutes >= reminderMinutes) {
        // Prevent spamming multiple notifications a day
        const lastNotified = localStorage.getItem('lastReminderDate');
        if (lastNotified !== today) {
          const periods = getPeriodsForDate(today, timetable);
          const bodyText = periods && periods.length > 0
            ? `You have ${periods.length} periods today. Don't forget to mark them!`
            : 'Don\'t forget to mark your attendance for today!';

          try {
            // Check if Service Worker is active for mobile push
            if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
              navigator.serviceWorker.ready.then(registration => {
                registration.showNotification('Attendance Reminder ⏰', {
                  body: bodyText,
                  icon: '/icon-192x192.png',
                  badge: '/icon-192x192.png',
                  vibrate: [200, 100, 200]
                });
              });
            } else {
              // Fallback for desktop/non-SW
              new Notification('Attendance Reminder ⏰', {
                body: bodyText,
                icon: '/icon-192x192.png'
              });
            }
            
            localStorage.setItem('lastReminderDate', today);
          } catch (e) {
            console.error('Notification failed', e);
          }
        }
      }
    };

    // Check immediately and then every 1 minute
    checkAndNotify();
    const interval = setInterval(checkAndNotify, 60 * 1000);

    return () => clearInterval(interval);
  }, [permission, data]);

  return { permission, requestPermission };
}
