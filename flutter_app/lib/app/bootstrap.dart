import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../core/services/database_service.dart';

const _firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
const _firebaseMessagingSenderId = String.fromEnvironment(
  'FIREBASE_MESSAGING_SENDER_ID',
);
const _firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
const _firebaseStorageBucket = String.fromEnvironment(
  'FIREBASE_STORAGE_BUCKET',
);

/// Startup initialization sequence preparing Flutter bindings, optional Firebase
/// options from `--dart-define`, and Hive local boxes before `runApp`.
///
/// Ownership: App Initialization
// ==========================================
// APP BOOTSTRAP - Firebase & Hive Startup
// ==========================================
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      if (_firebaseApiKey.isNotEmpty &&
          _firebaseAppId.isNotEmpty &&
          _firebaseProjectId.isNotEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: _firebaseApiKey,
            appId: _firebaseAppId,
            messagingSenderId: _firebaseMessagingSenderId,
            projectId: _firebaseProjectId,
            authDomain: _firebaseAuthDomain.isNotEmpty
                ? _firebaseAuthDomain
                : null,
            storageBucket: _firebaseStorageBucket.isNotEmpty
                ? _firebaseStorageBucket
                : null,
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[BOOTSTRAP] Firebase initialization skipped/failed: $e');
    }
  }
  await DatabaseService.init();
}
