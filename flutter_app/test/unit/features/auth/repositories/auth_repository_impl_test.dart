import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_app/features/auth/data/models/auth_user_model.dart';
import 'package:flutter_app/features/auth/data/repositories/auth_repository_impl.dart';

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  AuthUserModel? _savedUser;
  bool _isGuest = false;
  bool _isOnboarded = false;
  Map<String, dynamic>? _userSettings;

  void setUserSettings(Map<String, dynamic>? settings) {
    _userSettings = settings;
  }

  @override
  AuthUserModel? getSavedUserSync() => _savedUser;

  @override
  bool isGuestModeSync() => _isGuest;

  @override
  bool isOnboardingCompleteSync() {
    if (_isOnboarded) return true;
    final startDate = _userSettings?['startDate']?.toString().trim();
    if (startDate != null && startDate.isNotEmpty) return true;
    return false;
  }

  @override
  Future<AuthUserModel?> getSavedUser() async => _savedUser;

  @override
  Future<void> saveUser(AuthUserModel user) async {
    _savedUser = user;
  }

  @override
  Future<void> clearUser() async {
    _savedUser = null;
    _isGuest = false;
  }

  @override
  Future<bool> isGuestMode() async => _isGuest;

  @override
  Future<void> setGuestMode(bool isGuest) async {
    _isGuest = isGuest;
  }

  @override
  Future<bool> isOnboardingComplete() async => isOnboardingCompleteSync();

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    _isOnboarded = complete;
  }
}

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  final _controller = StreamController<AuthUserModel?>.broadcast();
  AuthUserModel? _remoteUser;

  @override
  Stream<AuthUserModel?> watchRemoteAuthState() => _controller.stream;

  @override
  Future<AuthUserModel?> getCurrentRemoteUser() async => _remoteUser;

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    const user = AuthUserModel(
      id: 'google_1',
      email: 'test@college.edu',
      displayName: 'Test Student',
    );
    _remoteUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _remoteUser = null;
    _controller.add(null);
  }
}

void main() {
  group('AuthRepositoryImpl Unit Tests', () {
    late FakeAuthLocalDataSource fakeLocal;
    late FakeAuthRemoteDataSource fakeRemote;
    late AuthRepositoryImpl repository;

    setUp(() {
      fakeLocal = FakeAuthLocalDataSource();
      fakeRemote = FakeAuthRemoteDataSource();
      repository = AuthRepositoryImpl(
        localDataSource: fakeLocal,
        remoteDataSource: fakeRemote,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test(
      'getCurrentUser returns null when unauthenticated and not guest',
      () async {
        final user = await repository.getCurrentUser();
        expect(user, isNull);
        expect(repository.getCachedCurrentUser(), isNull);
      },
    );

    test(
      'getCurrentUser returns guest user when guest mode is active',
      () async {
        await fakeLocal.setGuestMode(true);

        final user = await repository.getCurrentUser();
        expect(user, isNotNull);
        expect(user!.isGuest, isTrue);
        expect(user.id, 'guest');
        expect(repository.getCachedCurrentUser()?.isGuest, isTrue);
      },
    );

    test('getCurrentUser returns local user when present', () async {
      const saved = AuthUserModel(id: 'local_1', email: 'saved@college.edu');
      await fakeLocal.saveUser(saved);

      final user = await repository.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.id, 'local_1');
      expect(user.email, 'saved@college.edu');
      expect(user.isGuest, isFalse);
    });

    test(
      'signInWithGoogle signs in remotely, persists locally, and returns entity',
      () async {
        final user = await repository.signInWithGoogle();

        expect(user.id, 'google_1');
        expect(user.email, 'test@college.edu');
        expect(await fakeLocal.getSavedUser(), isNotNull);
        expect(await fakeLocal.isGuestMode(), isFalse);
      },
    );

    test('signInAsGuest sets guest mode in local data source', () async {
      final guest = await repository.signInAsGuest();

      expect(guest.isGuest, isTrue);
      expect(await fakeLocal.isGuestMode(), isTrue);
      expect(await fakeLocal.getSavedUser(), isNull);
    });

    test(
      'signOut clears local and remote state without resetting onboarding',
      () async {
        await repository.signInWithGoogle();
        await repository.setOnboardingComplete(true);

        await repository.signOut();

        expect(await repository.getCurrentUser(), isNull);
        expect(await fakeLocal.isGuestMode(), isFalse);
        expect(await repository.isOnboardingComplete(), isTrue);
      },
    );

    test(
      're-login after sign out retains isOnboardingComplete == true when user_settings has non-empty startDate',
      () async {
        fakeLocal.setUserSettings({
          'startDate': '2026-01-10',
          'programName': 'B.Tech CSE',
          'minPercent': 75.0,
        });

        // Initial login
        final user = await repository.signInWithGoogle();
        expect(user.id, 'google_1');
        expect(await repository.isOnboardingComplete(), isTrue);
        expect(repository.isCachedOnboardingComplete(), isTrue);

        // Sign out
        await repository.signOut();
        expect(await repository.getCurrentUser(), isNull);
        expect(await repository.isOnboardingComplete(), isTrue);
        expect(repository.isCachedOnboardingComplete(), isTrue);

        // Re-login
        final relogged = await repository.signInWithGoogle();
        expect(relogged.id, 'google_1');
        expect(await repository.isOnboardingComplete(), isTrue);
        expect(repository.isCachedOnboardingComplete(), isTrue);
      },
    );

    test('isOnboardingComplete delegates to local data source', () async {
      expect(await repository.isOnboardingComplete(), isFalse);
      expect(repository.isCachedOnboardingComplete(), isFalse);

      await repository.setOnboardingComplete(true);

      expect(await repository.isOnboardingComplete(), isTrue);
      expect(repository.isCachedOnboardingComplete(), isTrue);
    });
  });
}
