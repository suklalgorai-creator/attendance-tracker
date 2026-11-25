import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_app/features/auth/data/models/auth_user_model.dart';

void main() {
  group('DefaultAuthRemoteDataSource Unit Tests', () {
    late DefaultAuthRemoteDataSource remoteDataSource;

    setUp(() {
      remoteDataSource = DefaultAuthRemoteDataSource();
    });

    tearDown(() {
      remoteDataSource.dispose();
    });

    test('getCurrentRemoteUser initially returns null', () async {
      final user = await remoteDataSource.getCurrentRemoteUser();
      expect(user, isNull);
    });

    test(
      'signInWithGoogle signs in offline user and emits to stream',
      () async {
        final streamExpectation = expectLater(
          remoteDataSource.watchRemoteAuthState(),
          emits(
            isA<AuthUserModel>().having(
              (u) => u.email,
              'email',
              'student@college.edu',
            ),
          ),
        );

        final user = await remoteDataSource.signInWithGoogle();
        expect(user.id, 'google_user_demo_101');
        expect(user.email, 'student@college.edu');
        expect(user.displayName, 'College Student');

        final current = await remoteDataSource.getCurrentRemoteUser();
        expect(current, equals(user));

        await streamExpectation;
      },
    );

    test('signOut clears current remote user and emits null', () async {
      await remoteDataSource.signInWithGoogle();
      expect(await remoteDataSource.getCurrentRemoteUser(), isNotNull);

      final streamExpectation = expectLater(
        remoteDataSource.watchRemoteAuthState(),
        emits(isNull),
      );

      await remoteDataSource.signOut();
      expect(await remoteDataSource.getCurrentRemoteUser(), isNull);
      await streamExpectation;
    });
  });
}
