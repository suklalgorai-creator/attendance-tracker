import { doc, getDoc, runTransaction } from 'firebase/firestore';
import { db } from '../firebase';
import { migrateUserData } from '../utils/dataModel.js';
import { mergeUserData } from '../utils/sync.js';

const BASE_STORAGE_KEY = 'attendance-register-v2';
const LEGACY_STORAGE_KEY = 'attendance-register-v1';

function storageKey(uid) {
  return `${BASE_STORAGE_KEY}_${uid}`;
}

function legacyStorageKey(uid) {
  return `${LEGACY_STORAGE_KEY}_${uid}`;
}

export function loadLocal(uid) {
  try {
    const raw = localStorage.getItem(storageKey(uid)) || localStorage.getItem(legacyStorageKey(uid));
    return raw ? migrateUserData(JSON.parse(raw)).data : null;
  } catch (error) {
    return { error: error instanceof Error ? error.message : 'Unable to read local data.' };
  }
}

export function saveLocal(uid, data) {
  if (!uid) return { ok: false, error: 'Missing local storage identity.' };
  try {
    localStorage.setItem(storageKey(uid), JSON.stringify(data));
    return { ok: true };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : 'Unable to save local data.' };
  }
}

/** Local state is always usable; cloud is a synchronized backup, never a winner by record count. */
export async function loadUserData(uid) {
  const localResult = loadLocal(uid);
  if (localResult?.error) throw new Error(localResult.error);
  const local = localResult;
  if (uid === 'guest') return { data: local, needsSync: false, warnings: [] };

  try {
    const snapshot = await getDoc(doc(db, 'users', uid));
    const cloud = snapshot.exists() ? snapshot.data() : null;
    if (!local && !cloud) return { data: null, needsSync: false, warnings: [] };
    const data = local && cloud ? mergeUserData(local, cloud) : migrateUserData(local || cloud).data;
    const saveResult = saveLocal(uid, data);
    if (!saveResult.ok) throw new Error(saveResult.error);
    const normalizedCloud = cloud ? migrateUserData(cloud).data : null;
    return { data, needsSync: !normalizedCloud || JSON.stringify(data) !== JSON.stringify(normalizedCloud), warnings: migrateUserData(local || cloud).warnings };
  } catch (error) {
    if (local) return { data: local, needsSync: true, warnings: ['Cloud data is currently unavailable; using local data.'] };
    throw error;
  }
}

/**
 * Uses a transaction so a stale client cannot overwrite a newly changed cloud
 * entity. The result is the canonical merged snapshot that was written.
 */
export async function flushToCloud(user, localData) {
  if (!user?.uid || user.uid === 'guest') return migrateUserData(localData).data;
  const userRef = doc(db, 'users', user.uid);
  const merged = await runTransaction(db, async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const data = snapshot.exists() ? mergeUserData(localData, snapshot.data()) : migrateUserData(localData).data;
    transaction.set(userRef, {
      ...data,
      email: user.email || '',
      displayName: user.displayName || '',
    });
    return data;
  });
  const saveResult = saveLocal(user.uid, merged);
  if (!saveResult.ok) throw new Error(saveResult.error);
  return merged;
}

export async function getGlobalSettings() {
  try {
    const docRef = doc(db, 'settings', 'global');
    const snapshot = await getDoc(docRef);
    return snapshot.exists() ? snapshot.data() : { holidays: {} };
  } catch {
    return { holidays: {} };
  }
}

export function getLocalBackupKey(uid) {
  return `${storageKey(uid)}_pre_restore_${Date.now()}`;
}

export function savePreRestoreBackup(uid, data) {
  try {
    localStorage.setItem(getLocalBackupKey(uid), JSON.stringify(data));
    return { ok: true };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : 'Unable to create safety backup.' };
  }
}
