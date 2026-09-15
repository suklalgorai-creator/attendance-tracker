import admin from 'firebase-admin';

// Initialize Firebase Admin (only once)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      // The private key comes as a string with escaped newlines from env vars
      privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    }),
  });
}

const db = admin.firestore();

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
    // ===== MODE 1: Admin sends notification to a specific user =====
    if (req.method === 'POST') {
      const { uid, title, body, adminKey } = req.body;

      // Simple auth check — only allow requests with the correct admin key
      if (adminKey !== process.env.ADMIN_SECRET_KEY) {
        return res.status(403).json({ error: 'Unauthorized' });
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

      const now = new Date();
      const currentDay = now.toLocaleDateString('en-US', { weekday: 'short' }); // "Mon", "Tue", etc.
      const currentMinutes = now.getUTCHours() * 60 + now.getUTCMinutes();
      const todayStr = now.toISOString().slice(0, 10); // "2026-09-14"

      const usersSnapshot = await db.collection('users').get();
      let sent = 0;
      let skipped = 0;

      const sendPromises = [];

      usersSnapshot.forEach((doc) => {
        const data = doc.data();
        const fcmToken = data.fcmToken;
        const classDays = data.classDays || [];
        const records = data.records || {};
        const reminderTime = data.reminderTime || '18:00';

        // Skip if no FCM token
        if (!fcmToken) { skipped++; return; }

        // Skip if today is not a class day
        const isClassDay = classDays.some(d => 
          d.substring(0, 3).toLowerCase() === currentDay.toLowerCase()
        );
        if (!isClassDay) { skipped++; return; }

        // Skip if attendance already marked
        if (records[todayStr]) { skipped++; return; }

        // Check if current time is past reminder time (convert to user's perspective)
        const [rh, rm] = reminderTime.split(':').map(Number);
        const reminderMinutes = (rh || 0) * 60 + (rm || 0);
        // Note: We use IST offset (+5:30 = 330 min) since target audience is Indian students
        const istMinutes = currentMinutes + 330;
        if (istMinutes < reminderMinutes) { skipped++; return; }

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
            .then(() => { sent++; })
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
