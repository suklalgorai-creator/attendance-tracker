/* eslint-disable no-restricted-globals */
/* eslint-disable no-undef */

// Import Firebase scripts for messaging in Service Worker
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: 'AIzaSyDIEmIORQvCySd9Btr8bGMHRb34XQSTtJ8',
  authDomain: 'attendance-tracker-f510a.firebaseapp.com',
  projectId: 'attendance-tracker-f510a',
  storageBucket: 'attendance-tracker-f510a.firebasestorage.app',
  messagingSenderId: '651217207861',
  appId: '1:651217207861:web:7ebda2d88c0dc07506277c',
});

const messaging = firebase.messaging();

// Handle background messages (when app is closed or in background)
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  const notificationTitle = payload.notification?.title || 'Attendance Reminder ⏰';
  const notificationOptions = {
    body: payload.notification?.body || "Don't forget to mark your attendance today!",
    icon: '/icon.svg',
    badge: '/icon.svg',
    vibrate: [200, 100, 200],
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click - open the app
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // If app is already open, focus it
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      // Otherwise open a new window
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
