import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_state.dart';

class _CancelledAuthRepo implements AuthRepository {
  @override
  AuthUserEntity? getCachedCurrentUser() => null;

  @override
  bool isCachedOnboardingComplete() => false;

  @override
  Future<AuthUserEntity?> getCurrentUser() async => null;

  @override
  Future<bool> isOnboardingComplete() async => false;

  @override
  Future<void> setOnboardingComplete(bool complete) async {}

  @override
  Future<AuthUserEntity> signInAsGuest() async => AuthUserEntity.guest();

  @override
  Future<AuthUserEntity> signInWithGoogle() async {
    throw const AuthCancelledException();
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthUserEntity?> watchAuthState() => const Stream.empty();
}

void main() {
  group('FirebaseAuthRemoteDataSource (unconfigured Firebase)', () {
    test(
      'getCurrentRemoteUser returns null when Firebase is not initialized',
      () async {
        final ds = FirebaseAuthRemoteDataSource();
        expect(await ds.getCurrentRemoteUser(), isNull);
      },
    );

    test(
      'signInWithGoogle throws AuthConfigurationException when Firebase is not initialized',
      () async {
        final ds = FirebaseAuthRemoteDataSource();
        expect(
          () => ds.signInWithGoogle(),
          throwsA(isA<AuthConfigurationException>()),
        );
      },
    );

    test(
      'watchRemoteAuthState returns empty stream when Firebase is not initialized',
      () async {
        final ds = FirebaseAuthRemoteDataSource();
        expect(await ds.watchRemoteAuthState().isEmpty, isTrue);
      },
    );
  });

  group('AuthNotifier Google Sign-In cancellation', () {
    test(
      'returns to unauthenticated without error on AuthCancelledException',
      () async {
        final notifier = AuthNotifier(_CancelledAuthRepo());
        await notifier.init();

        await notifier.signInWithGoogle();

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.errorMessage, isNull);
      },
    );
  });
}
