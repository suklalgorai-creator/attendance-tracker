import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

/// Provider for local Hive-backed authentication data source.
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});

/// Provider for remote authentication data source backed by Firebase Auth & Google Sign-In.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return FirebaseAuthRemoteDataSource();
});

/// Provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

/// StateNotifierProvider exposing the authentication state.
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(
    repository,
    onAuthenticated: (uid) async {
      if (Firebase.apps.isNotEmpty) {
        final syncService = ref.read(cloudSyncServiceProvider);
        await syncService.loadUserData(uid);
      }
    },
  );
});
