import { useState, useEffect, useCallback } from 'react';
import { todayStr, isClassDay, getPeriodsForDate } from '../utils/date';
import { requestFCMToken } from '../firebase';

export function useReminders(data, saveSettings, globalSettings) {
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

    // If granted, get FCM token and save it to user data
    if (perm === 'granted') {
      try {
        const token = await requestFCMToken();
        if (token && saveSettings) {
          saveSettings({ fcmToken: token, pushNotificationsEnabled: true });
          console.log('FCM Token saved to cloud.');
        }
      } catch (e) {
        console.warn('Could not get FCM token:', e);
      }
    }
  }, [saveSettings]);

  // Refresh FCM token on load if permission is already granted
  useEffect(() => {
    if (permission !== 'granted' || !saveSettings) return;
    if (data?.pushNotificationsEnabled === false) return;
    
    (async () => {
      try {
        const token = await requestFCMToken();
        if (token && data && data.fcmToken !== token) {
          saveSettings({ fcmToken: token, pushNotificationsEnabled: true });
          console.log('FCM Token refreshed.');
        }
      } catch (e) {
        // Silent fail — token refresh is not critical
      }
    })();
  }, [permission]); // Only run once on mount

  const revokePermission = useCallback(() => {
    if (saveSettings) {
      saveSettings({ fcmToken: null, pushNotificationsEnabled: false });
    }
  }, [saveSettings]);

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
      
      // Check if today is a global holiday
      const globalHolidays = globalSettings?.holidays || {};
      if (globalHolidays[today]) return;

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
                  icon: '/icon.svg',
                  badge: '/icon.svg',
                  vibrate: [200, 100, 200]
                });
              });
            } else {
              // Fallback for desktop/non-SW
              new Notification('Attendance Reminder ⏰', {
                body: bodyText,
                icon: '/icon.svg'
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
  }, [permission, data, globalSettings]);

  return { permission, requestPermission, revokePermission };
}
