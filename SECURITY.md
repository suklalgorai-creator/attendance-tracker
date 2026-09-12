# Security Policy

## Supported Versions
Only the latest version of this software is supported.

## Reporting a Vulnerability

If you discover any security vulnerabilities in this project, please **do not create a public issue**. Instead, report them privately via email:

* **Email:** suklalgorai@gmail.com

You will receive an acknowledgment within 48 hours of reporting. 

## Firebase Security
This project uses Firebase Authentication and Cloud Firestore.
- API keys are meant to be public, but should be restricted in the Google Cloud Console to your specific domains.
- Firestore rules must be updated in the Firebase Console using the provided `firestore.rules` file to restrict data access appropriately.
- Ensure your Firebase project is on a plan with appropriate quota limits, as this app implements client-side rate limiting (5s debounce) which can be bypassed by malicious actors.
