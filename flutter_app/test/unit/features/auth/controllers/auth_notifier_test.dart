import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_state.dart';

class FakeAuthRepository implements AuthRepository {
  AuthUserEntity? currentUser;
  bool onboardingComplete = false;
  bool shouldThrowOnGoogle = false;
  Completer<AuthUserEntity>? googleSignInCompleter;

  final _controller = StreamController<AuthUserEntity?>.broadcast();

  @override
  Stream<AuthUserEntity?> watchAuthState() => _controller.stream;

  @override
  AuthUserEntity? getCachedCurrentUser() => currentUser;

  @override
  bool isCachedOnboardingComplete() => onboardingComplete;

  @override
  Future<AuthUserEntity?> getCurrentUser() async => currentUser;

  @override
  Future<AuthUserEntity> signInWithGoogle() async {
    if (googleSignInCompleter != null) {
      final user = await googleSignInCompleter!.future;
      currentUser = user;
      _controller.add(user);
      return user;
    }
    if (shouldThrowOnGoogle) {
      throw Exception('Network connection timed out');
    }
    const user = AuthUserEntity(
      id: 'google_user_1',
      email: 'user@college.edu',
      displayName: 'Google Student',
    );
    currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUserEntity> signInAsGuest() async {
    final guest = AuthUserEntity.guest();
    currentUser = guest;
    _controller.add(guest);
    return guest;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    onboardingComplete = false;
    _controller.add(null);
  }

  @override
  Future<bool> isOnboardingComplete() async => onboardingComplete;

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    onboardingComplete = complete;
  }
}

void main() {
  group('AuthNotifier Unit Tests', () {
    late FakeAuthRepository fakeRepo;
    late AuthNotifier notifier;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      notifier = AuthNotifier(fakeRepo);
    });

    test('initial state is unauthenticated when repo has no user', () {
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.user, isNull);
      expect(notifier.state.isOnboardingComplete, isFalse);
      expect(notifier.state.isLoggedIn, isFalse);
    });

    test('signInWithGoogle updates state to authenticated with user', () async {
      await notifier.signInWithGoogle();

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user, isNotNull);
      expect(notifier.state.user!.id, 'google_user_1');
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.isGuest, isFalse);
      expect(notifier.state.isLoggedIn, isTrue);
    });

    test('signInWithGoogle handles exception and sets error state', () async {
      fakeRepo.shouldThrowOnGoogle = true;

      await notifier.signInWithGoogle();

      expect(notifier.state.status, AuthStatus.error);
      expect(
        notifier.state.errorMessage,
        contains('Network connection timed out'),
      );
      expect(notifier.state.isAuthenticated, isFalse);
    });

    test('signInAsGuest updates state to guest', () async {
      await notifier.signInAsGuest();

      expect(notifier.state.status, AuthStatus.guest);
      expect(notifier.state.user, isNotNull);
      expect(notifier.state.user!.isGuest, isTrue);
      expect(notifier.state.isGuest, isTrue);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.isLoggedIn, isTrue);
    });

    test('completeOnboarding marks onboarding complete in state', () async {
      expect(notifier.state.isOnboardingComplete, isFalse);

      await notifier.completeOnboarding();

      expect(notifier.state.isOnboardingComplete, isTrue);
      expect(fakeRepo.onboardingComplete, isTrue);
    });

    test('signOut clears authenticated user and resets onboarding', () async {
      await notifier.signInWithGoogle();
      await notifier.completeOnboarding();
      expect(notifier.state.isLoggedIn, isTrue);
      expect(notifier.state.isOnboardingComplete, isTrue);

      await notifier.signOut();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.user, isNull);
      expect(notifier.state.isOnboardingComplete, isFalse);
      expect(notifier.state.isLoggedIn, isFalse);
    });

    test(
      'calling signInWithGoogle followed immediately by signOut leaves final state as unauthenticated',
      () async {
        fakeRepo.googleSignInCompleter = Completer<AuthUserEntity>();

        // 1. Initiate Google sign-in (in-flight)
        final googleFuture = notifier.signInWithGoogle();
        expect(notifier.state.status, AuthStatus.loading);

        // 2. Immediate signOut
        final signOutFuture = notifier.signOut();
        await signOutFuture;
        expect(notifier.state.status, AuthStatus.unauthenticated);

        // 3. Complete the in-flight Google sign-in
        const user = AuthUserEntity(
          id: 'delayed_google_user',
          email: 'delayed@college.edu',
          displayName: 'Delayed User',
        );
        fakeRepo.googleSignInCompleter!.complete(user);
        await googleFuture;

        // 4. Verify epoch guard prevented clobbering back to authenticated
        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.user, isNull);
      },
    );

    test(
      'calling signInWithGoogle followed immediately by signInAsGuest leaves final state as guest',
      () async {
        fakeRepo.googleSignInCompleter = Completer<AuthUserEntity>();

        // 1. Initiate Google sign-in (in-flight)
        final googleFuture = notifier.signInWithGoogle();
        expect(notifier.state.status, AuthStatus.loading);

        // 2. Immediate guest login
        final guestFuture = notifier.signInAsGuest();
        await guestFuture;
        expect(notifier.state.status, AuthStatus.guest);
        expect(notifier.state.user?.isGuest, isTrue);

        // 3. Complete in-flight Google sign-in
        const user = AuthUserEntity(
          id: 'delayed_google_user',
          email: 'delayed@college.edu',
          displayName: 'Delayed User',
        );
        fakeRepo.googleSignInCompleter!.complete(user);
        await googleFuture;

        // 4. Verify epoch guard prevented clobbering to authenticated
        expect(notifier.state.status, AuthStatus.guest);
        expect(notifier.state.user?.isGuest, isTrue);
      },
    );

    test(
      'delayed error on signInWithGoogle does not overwrite state if subsequent action occurred',
      () async {
        fakeRepo.googleSignInCompleter = Completer<AuthUserEntity>();

        final googleFuture = notifier.signInWithGoogle();
        await notifier.signInAsGuest();
        expect(notifier.state.status, AuthStatus.guest);

        // Complete with error
        fakeRepo.googleSignInCompleter!.completeError(Exception('Late error'));
        try {
          await googleFuture;
        } catch (_) {}

        // State remains guest, not error
        expect(notifier.state.status, AuthStatus.guest);
      },
    );
  });
}
