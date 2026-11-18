import '../entities/auth_user_entity.dart';

/// Abstract contract for Authentication & Session management in Domain layer.
abstract class AuthRepository {
  /// Stream broadcasting authentication state changes.
  Stream<AuthUserEntity?> watchAuthState();

  /// Returns current active user (Google account or Guest), or null if unauthenticated.
  Future<AuthUserEntity?> getCurrentUser();

  /// Synchronously returns cached user from in-memory / local storage.
  AuthUserEntity? getCachedCurrentUser();

  /// Authenticate with Google credential.
  Future<AuthUserEntity> signInWithGoogle();

  /// Switch session to offline-first guest mode.
  Future<AuthUserEntity> signInAsGuest();

  /// Terminate active session and clear persisted credentials.
  Future<void> signOut();

  /// Checks if the user has completed the onboarding register wizard.
  Future<bool> isOnboardingComplete();

  /// Synchronously checks if the user has completed the onboarding wizard.
  bool isCachedOnboardingComplete();

  /// Persists onboarding completion flag.
  Future<void> setOnboardingComplete(bool complete);
}
