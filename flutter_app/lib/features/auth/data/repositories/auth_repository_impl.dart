import 'dart:async';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Repository coordinating Google Sign-In, offline guest sessions, and onboarding flags.
///
/// Ownership: Authentication Feature (Data Layer)
// ==========================================
// AUTH REPOSITORY - Session & Onboarding Persistence
// ==========================================
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;
  final StreamController<AuthUserEntity?> _authStreamController =
      StreamController<AuthUserEntity?>.broadcast();

  AuthRepositoryImpl({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  @override
  Stream<AuthUserEntity?> watchAuthState() async* {
    // Emit initial cached state immediately
    final initial = await getCurrentUser();
    yield initial;
    yield* _authStreamController.stream;
  }

  @override
  AuthUserEntity? getCachedCurrentUser() {
    if (_localDataSource.isGuestModeSync()) {
      return AuthUserEntity.guest();
    }
    return _localDataSource.getSavedUserSync();
  }

  @override
  bool isCachedOnboardingComplete() {
    return _localDataSource.isOnboardingCompleteSync();
  }

  @override
  Future<AuthUserEntity?> getCurrentUser() async {
    // 1. Check guest session first
    final isGuest = await _localDataSource.isGuestMode();
    if (isGuest) {
      return AuthUserEntity.guest();
    }

    // 2. Check cached local user
    final localUser = await _localDataSource.getSavedUser();
    if (localUser != null) {
      return localUser;
    }

    // 3. Check remote active user
    final remoteUser = await _remoteDataSource.getCurrentRemoteUser();
    if (remoteUser != null) {
      await _localDataSource.saveUser(remoteUser);
      return remoteUser;
    }

    return null;
  }

  @override
  Future<AuthUserEntity> signInWithGoogle() async {
    final remoteUser = await _remoteDataSource.signInWithGoogle();
    await _localDataSource.saveUser(remoteUser);
    await _localDataSource.setGuestMode(false);
    _authStreamController.add(remoteUser);
    return remoteUser;
  }

  @override
  Future<AuthUserEntity> signInAsGuest() async {
    final guest = AuthUserEntity.guest();
    await _localDataSource.setGuestMode(true);
    await _localDataSource.clearUser();
    // Reinforce guest mode flag since clearUser resets it
    await _localDataSource.setGuestMode(true);
    _authStreamController.add(guest);
    return guest;
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
    await _localDataSource.clearUser();
    await _localDataSource.setGuestMode(false);
    _authStreamController.add(null);
  }

  @override
  Future<bool> isOnboardingComplete() async {
    return _localDataSource.isOnboardingComplete();
  }

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    await _localDataSource.setOnboardingComplete(complete);
  }

  void dispose() {
    _authStreamController.close();
  }
}
