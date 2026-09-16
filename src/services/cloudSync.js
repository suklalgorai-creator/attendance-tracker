import { doc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '../firebase';

const BASE_STORAGE_KEY = 'attendance-register-v1';

/**
 * Load user data: local-first, then cloud if stale (>1 hour)
 */
export async function loadUserData(uid) {
  const storageKey = `${BASE_STORAGE_KEY}_${uid}`;
  const lastSyncKey = `${storageKey}_lastSync`;
  
  // 1. Load from localStorage FIRST (instant, no Firestore read)
  let localData = null;
  try {
    const cached = localStorage.getItem(storageKey);
    if (cached) localData = JSON.parse(cached);
  } catch (e) {}

  // 2. Check if cloud data is newer (only 1 read per session)
  let lastSync = 0;
  try {
    lastSync = parseInt(localStorage.getItem(lastSyncKey) || '0', 10);
  } catch (e) {}
  
  const now = Date.now();
  const ONE_HOUR = 60 * 60 * 1000;

  let cloudData = null;

  if (uid !== 'guest' && (!localData || (now - lastSync) > ONE_HOUR)) {
    try {
      const docRef = doc(db, 'users', uid);
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        cloudData = docSnap.data();
        const cloudRecordCount = Object.keys(cloudData.records || {}).length;
        const localRecordCount = Object.keys((localData || {}).records || {}).length;

        if (cloudRecordCount >= localRecordCount) {
          localStorage.setItem(storageKey, JSON.stringify(cloudData));
        } else {
          cloudData = null; // local is newer, keep it
        }
        localStorage.setItem(lastSyncKey, String(now));
      }
    } catch (e) {
      console.warn('Cloud fetch skipped (offline?):', e.message);
    }
  }

  return cloudData || localData || null;
}

/**
 * Save data to localStorage instantly
 */
export function saveLocal(uid, data) {
  if (!uid) return;
  const storageKey = `${BASE_STORAGE_KEY}_${uid}`;
  try {
    localStorage.setItem(storageKey, JSON.stringify(data));
  } catch (e) {}
}

/**
 * Flush data to Firestore
 */
export async function flushToCloud(user, data) {
  if (!user || !user.uid || user.uid === 'guest') return;
  const lastSyncKey = `${BASE_STORAGE_KEY}_${user.uid}_lastSync`;
  await setDoc(doc(db, 'users', user.uid), { ...data, email: user.email, displayName: user.displayName || '' });
  localStorage.setItem(lastSyncKey, String(Date.now()));
}

/**
 * Fetch Global Settings (Holidays, etc)
 */
export async function getGlobalSettings() {
  try {
    const docRef = doc(db, 'settings', 'global');
    const docSnap = await getDoc(docRef);
    if (docSnap.exists()) {
      return docSnap.data();
    }
  } catch (e) {
    console.warn('Failed to fetch global settings:', e);
  }
  return { holidays: {} };
}
