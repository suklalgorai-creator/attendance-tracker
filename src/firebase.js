import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { initializeFirestore, getFirestore, persistentLocalCache, persistentMultipleTabManager } from "firebase/firestore";
import { getMessaging, getToken, isSupported } from "firebase/messaging";

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID
};

// Prevent duplicate initialization during HMR
const app = getApps().length ? getApp() : initializeApp(firebaseConfig);

export const auth = getAuth(app);

// Initialize Firestore with offline persistence (safe for HMR re-runs)
let db;
try {
  db = initializeFirestore(app, {
    localCache: persistentLocalCache({
      tabManager: persistentMultipleTabManager()
    })
  });
} catch (e) {
  // Already initialized (HMR re-run) — just grab the existing instance
  db = getFirestore(app);
}
export { db };

// Initialize Firebase Cloud Messaging (safe — won't break if unsupported)
let messaging = null;

/**
 * Get the FCM messaging instance (lazy, only when needed).
 * Returns null if messaging is not supported in this browser.
 */
export async function getMessagingInstance() {
  if (messaging) return messaging;
  try {
    const supported = await isSupported();
    if (supported) {
      messaging = getMessaging(app);
      return messaging;
    }
  } catch (e) {
    console.warn('Firebase Messaging not supported:', e.message);
  }
  return null;
}

/**
 * Request an FCM token for push notifications.
 * Returns the token string, or null if not supported/denied.
 */
export async function requestFCMToken() {
  try {
    const msgInstance = await getMessagingInstance();
    if (!msgInstance) return null;
    
    const token = await getToken(msgInstance, {
      vapidKey: import.meta.env.VITE_FIREBASE_VAPID_KEY || undefined,
    });
    return token || null;
  } catch (e) {
    console.error('Failed to get FCM token:', e);
    return null;
  }
}

