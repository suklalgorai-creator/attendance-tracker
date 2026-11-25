import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/auth_user_model.dart';

/// Thrown when the user cancels the interactive Google Sign-In flow.
class AuthCancelledException implements Exception {
  final String message;
  const AuthCancelledException([this.message = 'Sign-in was cancelled.']);
  @override
  String toString() => message;
}

/// Thrown when Firebase or Google Sign-In is not configured for this build.
class AuthConfigurationException implements Exception {
  final String message;
  const AuthConfigurationException(this.message);
  @override
  String toString() => message;
}

/// Contract for remote authentication (Google Sign-In, Firebase Auth).
abstract class AuthRemoteDataSource {
  Stream<AuthUserModel?> watchRemoteAuthState();
  Future<AuthUserModel?> getCurrentRemoteUser();
  Future<AuthUserModel> signInWithGoogle();
  Future<void> signOut();
}

/// Production remote auth data source backed by [FirebaseAuth] and [GoogleSignIn].
class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final FirebaseAuth? _firebaseAuthOverride;
  bool _googleInitialized = false;

  FirebaseAuthRemoteDataSource({FirebaseAuth? firebaseAuth})
    : _firebaseAuthOverride = firebaseAuth;

  bool get _isFirebaseReady =>
      _firebaseAuthOverride != null || Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => _firebaseAuthOverride ?? FirebaseAuth.instance;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<AuthUserModel> _mapFirebaseUser(User user) async {
    bool isAdmin = false;
    try {
      final tokenResult = await user.getIdTokenResult();
      isAdmin = tokenResult.claims?['admin'] == true;
    } catch (_) {}

    return AuthUserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAdmin: isAdmin,
      isGuest: false,
    );
  }

  @override
  Stream<AuthUserModel?> watchRemoteAuthState() {
    if (!_isFirebaseReady) return const Stream.empty();
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _mapFirebaseUser(user);
    });
  }

  @override
  Future<AuthUserModel?> getCurrentRemoteUser() async {
    if (!_isFirebaseReady) return null;
    final user = _auth.currentUser;
    if (user == null) return null;
    return _mapFirebaseUser(user);
  }

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      throw const AuthConfigurationException(
        'Google Sign-In is not supported on Windows Desktop. Use Chrome (flutter run -d chrome) for desktop testing or Android/iOS.',
      );
    }

    if (!_isFirebaseReady) {
      throw const AuthConfigurationException(
        'Firebase is not configured for this build. Pass --dart-define Firebase keys or run flutterfire configure.',
      );
    }

    if (kIsWeb) {
      try {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final userCredential = await _auth.signInWithPopup(provider);
        final firebaseUser = userCredential.user;
        if (firebaseUser == null) {
          throw const AuthConfigurationException(
            'Firebase authentication succeeded but returned no user profile.',
          );
        }
        return _mapFirebaseUser(firebaseUser);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          throw const AuthCancelledException();
        }
        throw Exception(e.message ?? 'Google Sign-In failed (${e.code}).');
      }
    }

    try {
      await _ensureGoogleInitialized();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthConfigurationException(
          'Google Sign-In did not return an ID token. Verify your Web Client ID and SHA-1/SHA-256 fingerprints in Firebase Console.',
        );
      }

      String? accessToken;
      try {
        final authorization = await googleUser.authorizationClient
            .authorizationForScopes(const ['email', 'profile']);
        accessToken = authorization?.accessToken;
      } catch (_) {
        // idToken alone is sufficient for Firebase GoogleAuthProvider.credential
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthConfigurationException(
          'Firebase authentication succeeded but returned no user profile.',
        );
      }
      return _mapFirebaseUser(firebaseUser);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthCancelledException();
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw const AuthConfigurationException(
          'Google Sign-In client configuration error. Verify google-services.json, package name, and SHA-1/SHA-256 in Firebase Console.',
        );
      }
      throw Exception(
        e.description ?? 'Google Sign-In failed (${e.code.name}).',
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Firebase sign-in failed (${e.code}).');
    }
  }

  @override
  Future<void> signOut() async {
    if (_isFirebaseReady) {
      await _auth.signOut();
    }
    try {
      if (_googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
  }
}

/// Headless/unit-test-only in-memory [AuthRemoteDataSource] implementation.
@visibleForTesting
class DefaultAuthRemoteDataSource implements AuthRemoteDataSource {
  final StreamController<AuthUserModel?> _authStateController =
      StreamController<AuthUserModel?>.broadcast();
  AuthUserModel? _currentUser;

  DefaultAuthRemoteDataSource({AuthUserModel? initialUser})
    : _currentUser = initialUser;

  @override
  Stream<AuthUserModel?> watchRemoteAuthState() {
    return _authStateController.stream;
  }

  @override
  Future<AuthUserModel?> getCurrentRemoteUser() async {
    return _currentUser;
  }

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    const googleUser = AuthUserModel(
      id: 'google_user_demo_101',
      email: 'student@college.edu',
      displayName: 'College Student',
      photoUrl: null,
      isAdmin: false,
      isGuest: false,
    );
    _currentUser = googleUser;
    _authStateController.add(googleUser);
    return googleUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
