import 'dart:async';
import '../models/auth_user_model.dart';

/// Contract for remote authentication (Google Sign-In, Firebase Auth).
abstract class AuthRemoteDataSource {
  Stream<AuthUserModel?> watchRemoteAuthState();
  Future<AuthUserModel?> getCurrentRemoteUser();
  Future<AuthUserModel> signInWithGoogle();
  Future<void> signOut();
}

/// Offline-safe remote auth data source ensuring zero Firebase / network crashes in offline mode and tests.
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
    // Provide a deterministic offline user account replicating Google Auth credentials
    final googleUser = const AuthUserModel(
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
