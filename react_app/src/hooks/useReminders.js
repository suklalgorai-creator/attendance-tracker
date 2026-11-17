import { useState, useEffect, useCallback } from 'react';
import { todayStr, isClassDay } from '../utils/date';
import { computeStats } from '../utils/stats';
import { requestFCMToken } from '../firebase';
import { ATTENDANCE_STATUS, DAILY_SUBJECT_ID } from '../utils/dataModel';

export function useReminders(data, saveSettings, globalSettings) {
  const [permission, setPermission] = useState(() => (
    typeof window !== 'undefined' && 'Notification' in window ? Notification.permission : 'denied'
  ));

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
        }
      } catch (e) {
        // Silent fail — token refresh is not critical
      }
    })();
  }, [permission, data, saveSettings]);

  const revokePermission = useCallback(() => {
    if (saveSettings) {
      saveSettings({ fcmToken: null, pushNotificationsEnabled: false });
    }
  }, [saveSettings]);

  useEffect(() => {
    if (permission !== 'granted' || !data) return;

    const sendPushNotification = (title, body) => {
      try {
        if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
          navigator.serviceWorker.ready.then(registration => {
            registration.showNotification(title, {
              body,
              icon: '/icon.svg',
              badge: '/icon.svg',
              vibrate: [200, 100, 200]
            });
          });
        } else {
          new Notification(title, { body, icon: '/icon.svg' });
        }
      } catch (e) {
        console.error('Notification failed', e);
      }
    };

    const checkAndNotify = () => {
      const now = new Date();
      const currentMinutes = now.getHours() * 60 + now.getMinutes();
      const today = todayStr();
      
      // 1. Check Attendance Reminders
      const reminderTime = data.reminderTime || '18:00';
      const globalHolidays = globalSettings?.holidays || {};
      // Pending sessions are reminders only; they are never counted as absences.
      const { unmarkedPastSessions } = computeStats(data, globalHolidays);
      if (unmarkedPastSessions > 0) {
        const lastPastDaysNotified = localStorage.getItem('lastPastDaysReminderDate');
        if (lastPastDaysNotified !== today) {
          sendPushNotification('Pending Attendance ⏰', `You have ${unmarkedPastSessions} scheduled class sessions that haven't been marked. Please update them.`);
          localStorage.setItem('lastPastDaysReminderDate', today);
        }
      }

      const todaySessions = [];
      const todayRecords = (data.attendanceRecords || []).filter((record) => !record.deletedAt && record.date === today);
      const markedSessionIds = new Set(todayRecords
        .filter((record) => [ATTENDANCE_STATUS.PRESENT, ATTENDANCE_STATUS.ABSENT, ATTENDANCE_STATUS.CANCELLED].includes(record.status))
        .map((record) => record.sessionId));
      const dailyLegacy = data.legacyAttendance?.find((record) => !record.deletedAt && record.date === today);
      const dailyMarked = Boolean(dailyLegacy) || todayRecords.some((record) => record.subjectId === DAILY_SUBJECT_ID && [ATTENDANCE_STATUS.PRESENT, ATTENDANCE_STATUS.ABSENT, ATTENDANCE_STATUS.CANCELLED].includes(record.status));
      const pendingToday = todaySessions.length > 0
        ? todaySessions.filter((session) => !markedSessionIds.has(session.id))
        : (data.startDate && today >= data.startDate && isClassDay(today, data.classDays) && !dailyMarked ? [{ id: DAILY_SUBJECT_ID }] : []);

      if (pendingToday.length > 0 && !globalHolidays[today]) {
        const [rh, rm] = reminderTime.split(':').map(Number);
        const reminderMinutes = (rh || 0) * 60 + (rm || 0);

        if (currentMinutes >= reminderMinutes) {
          const lastNotified = localStorage.getItem('lastReminderDate');
          if (lastNotified !== today) {
            const bodyText = `You have ${pendingToday.length} scheduled session${pendingToday.length === 1 ? '' : 's'} still pending today.`;
            
            sendPushNotification('Attendance Reminder ⏰', bodyText);
            localStorage.setItem('lastReminderDate', today);
          }
        }
      }

      // 2. Check Sticky Notes Reminders
      const notes = data.notes || [];
      notes.forEach(note => {
        if (!note.reminderDate) return;
        const noteDate = new Date(note.reminderDate);
        if (now >= noteDate) {
          const notifiedKey = `note_notified_${note.id}`;
          if (localStorage.getItem(notifiedKey) !== 'true') {
            sendPushNotification('Sticky Note Reminder 📝', note.content.slice(0, 100));
            localStorage.setItem(notifiedKey, 'true');
          }
        }
      });
    };

    // Check immediately and then every 1 minute
    checkAndNotify();
    const interval = setInterval(checkAndNotify, 60 * 1000);

    return () => clearInterval(interval);
  }, [permission, data, globalSettings]);

  return { permission, requestPermission, revokePermission };
}
