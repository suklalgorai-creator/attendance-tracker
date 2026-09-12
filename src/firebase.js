import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// TODO: Replace the following with your app's Firebase project configuration
// See: https://firebase.google.com/docs/web/learn-more#config-object
const firebaseConfig = {
  apiKey: "AIzaSyDIEmIORQvCySd9Btr8bGMHRb34XQSTtJ8",
  authDomain: "attendance-tracker-f510a.firebaseapp.com",
  projectId: "attendance-tracker-f510a",
  storageBucket: "attendance-tracker-f510a.firebasestorage.app",
  messagingSenderId: "651217207861",
  appId: "1:651217207861:web:7ebda2d88c0dc07506277c",
  measurementId: "G-CMH5SP6RDK"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase Authentication and get a reference to the service
export const auth = getAuth(app);

// Initialize Cloud Firestore and get a reference to the service
export const db = getFirestore(app);
