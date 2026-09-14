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

  if (!localData || (now - lastSync) > ONE_HOUR) {
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
export async function flushToCloud(uid, email, data) {
  if (!uid) return;
  const lastSyncKey = `${BASE_STORAGE_KEY}_${uid}_lastSync`;
  await setDoc(doc(db, 'users', uid), { ...data, email });
  localStorage.setItem(lastSyncKey, String(Date.now()));
}
