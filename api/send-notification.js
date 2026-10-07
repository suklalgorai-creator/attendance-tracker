import admin from 'firebase-admin';

let adminInitError = null;

try {
  if (!admin.apps.length) {
    let pk = process.env.FIREBASE_PRIVATE_KEY || '';
    if (pk.startsWith('"') && pk.endsWith('"')) {
      pk = pk.slice(1, -1);
    }
    pk = pk.replace(/\\n/g, '\n');

    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: pk,
      }),
    });
  }
} catch (e) {
  console.error("Firebase Admin Init Error:", e);
  adminInitError = e.message;
}

const db = admin.apps.length ? admin.firestore() : null;

/**
 * Vercel Serverless Function: /api/send-notification
 * 
 * Modes:
 * 1. POST { uid, title, body } → Send a notification to a specific user (Admin use)
 * 2. GET ?type=cron → Auto-check all users and send reminders (GitHub Actions use)
 */
export default async function handler(req, res) {
  // CORS headers for frontend access
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    // Return early if initialization failed
    if (adminInitError) {
      return res.status(500).json({ error: 'Server configuration error (Admin Init)', details: adminInitError });
    }

    // ===== MODE 1: Admin sends notification to a specific user =====
    if (req.method === 'POST') {
      const { uid, title, body } = req.body;

      // Extract Auth Token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Missing or invalid authorization header' });
      }

      const idToken = authHeader.split('Bearer ')[1];
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        return res.status(401).json({ error: 'Unauthorized: Invalid token' });
      }

      // Check if user is Admin
      if (decodedToken.email !== process.env.VITE_ADMIN_EMAIL && decodedToken.email !== process.env.ADMIN_EMAIL) {
        return res.status(403).json({ error: 'Forbidden: Admin access required' });
      }

      if (!uid || !body) {
        return res.status(400).json({ error: 'uid and body are required' });
      }

      // Get user's FCM token from Firestore
      const userDoc = await db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return res.status(404).json({ error: 'User not found' });
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        return res.status(400).json({ error: 'User has no FCM token (notifications not enabled)' });
      }

      // Send the push notification
      const message = {
        token: fcmToken,
        notification: {
          title: title || 'Attendance Reminder ⏰',
          body: body,
        },
        webpush: {
          notification: {
            icon: '/icon.svg',
            badge: '/icon.svg',
            vibrate: [200, 100, 200],
          },
        },
      };

      const result = await admin.messaging().send(message);
      return res.status(200).json({ success: true, messageId: result });
    }

    // ===== MODE 2: Cron job — auto-send reminders =====
    if (req.method === 'GET' && req.query.type === 'cron') {
      const cronKey = req.query.key;
      if (cronKey !== process.env.CRON_SECRET_KEY) {
        return res.status(403).json({ error: 'Unauthorized cron request' });
      }

      // Get current date and time in IST (Indian Standard Time)
      const now = new Date();
      const istTime = new Date(now.getTime() + (330 * 60000));
      const currentDayNumber = istTime.getUTCDay(); // 0 (Sun) to 6 (Sat)
      const istMinutes = istTime.getUTCHours() * 60 + istTime.getUTCMinutes();
      const todayStr = istTime.toISOString().slice(0, 10); // "YYYY-MM-DD" in IST

      // Fetch global settings (holidays)
      let globalHolidays = {};
      try {
        const settingsDoc = await db.collection('settings').doc('global').get();
        if (settingsDoc.exists) {
          globalHolidays = settingsDoc.data().holidays || {};
        }
      } catch (e) {
        console.warn('Failed to fetch global settings in cron:', e);
      }

      const usersSnapshot = await db.collection('users').get();
      let sent = 0;
      let skipped = 0;

      const sendPromises = [];

      usersSnapshot.forEach((doc) => {
        const data = doc.data();
        const fcmToken = data.fcmToken;
        const classDays = data.classDays || [1, 2, 3, 4, 5];
        const records = data.records || {};
        const reminderTime = data.reminderTime || '18:00';

        // Skip if no FCM token
        if (!fcmToken) { skipped++; return; }

        // Skip if today is a global holiday
        if (globalHolidays[todayStr]) { skipped++; return; }

        // Skip if today is not a class day (classDays is an array of numbers 0-6)
        const isClassDay = classDays.includes(currentDayNumber);
        if (!isClassDay) { skipped++; return; }

        // Skip if attendance already marked
        if (records[todayStr]) { skipped++; return; }

        // Check if current time is past reminder time
        const [rh, rm] = reminderTime.split(':').map(Number);
        const reminderMinutes = (rh || 0) * 60 + (rm || 0);
        if (istMinutes < reminderMinutes) { skipped++; return; }
        
        // Skip if already notified today (to avoid hourly spam)
        if (data.lastNotified === todayStr) { skipped++; return; }

        // Send reminder
        const message = {
          token: fcmToken,
          notification: {
            title: 'Attendance Reminder ⏰',
            body: "Aaj ki attendance abhi tak mark nahi ki! Don't forget! 📝",
          },
          webpush: {
            notification: {
              icon: '/icon.svg',
              badge: '/icon.svg',
              vibrate: [200, 100, 200],
            },
          },
        };

        sendPromises.push(
          admin.messaging().send(message)
            .then(() => { 
              sent++; 
              // Update lastNotified in Firestore to prevent hourly spam
              return db.collection('users').doc(doc.id).update({ lastNotified: todayStr }).catch(() => {});
            })
            .catch((err) => {
              console.error(`Failed to send to ${doc.id}:`, err.message);
              skipped++;
            })
        );
      });

      await Promise.all(sendPromises);

      return res.status(200).json({
        success: true,
        sent,
        skipped,
        checkedAt: now.toISOString(),
      });
    }

    return res.status(405).json({ error: 'Method not allowed' });

  } catch (error) {
    console.error('API Error:', error);
    return res.status(500).json({ error: 'Internal server error', details: error.message });
  }
}
