import admin from 'firebase-admin';
import { calculateOverallAttendance } from '../src/utils/attendance.js';
import { migrateUserData, nowIso } from '../src/utils/dataModel.js';

if (!admin.apps.length) {
  let privateKey = process.env.FIREBASE_PRIVATE_KEY || '';
  if (privateKey.startsWith('"') && privateKey.endsWith('"')) privateKey = privateKey.slice(1, -1);
  privateKey = privateKey.replace(/\\n/g, '\n');
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey,
    }),
  });
}

const db = admin.firestore();

export default async function handler(req, res) {
  const allowedOrigin = process.env.APP_ORIGIN || process.env.VITE_APP_ORIGIN;
  if (allowedOrigin && req.headers.origin === allowedOrigin) res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Bearer ')) return res.status(401).json({ error: 'Authentication required.' });

  try {
    const token = await admin.auth().verifyIdToken(authHeader.slice(7));
    const userRef = db.collection('users').doc(token.uid);
    const userSnapshot = await userRef.get();
    if (!userSnapshot.exists) return res.status(404).json({ error: 'User data not found.' });

    const raw = userSnapshot.data();
    const data = migrateUserData(raw).data;
    const leaderboardRef = db.collection('leaderboard').doc(token.uid);
    const holidays = (await db.collection('settings').doc('global').get()).data()?.holidays || {};
    const overall = calculateOverallAttendance({
      attendanceRecords: data.attendanceRecords,
      legacyAttendance: data.legacyAttendance,
      minPercent: data.minPercent,
      holidays,
    });
    if (overall.attendance === null) {
      await leaderboardRef.delete();
      return res.status(200).json({ published: false });
    }

    const rawName = data.name || raw.displayName || 'Anonymous';
    const displayName = rawName.replace(/[^\p{L}\p{N} ._-]/gu, '').trim().slice(0, 40) || 'Anonymous';
    await leaderboardRef.set({
      displayName,
      attendancePercent: Number(overall.attendance.toFixed(1)),
      updatedAt: nowIso(),
    });
    return res.status(200).json({ published: true });
  } catch (error) {
    console.error('Leaderboard update failed:', error.message);
    return res.status(401).json({ error: 'Unable to update leaderboard.' });
  }
}
