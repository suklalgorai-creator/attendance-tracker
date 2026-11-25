import 'dart:async';
import '../../../../core/utils/data_migration.dart';
import '../../domain/datasources/remote_sync_datasource.dart';

/// In-memory [RemoteSyncDataSource] fallback for offline tests and headless runs.
///
/// Ownership: Cloud Sync Feature (Data Layer)
// ==========================================
// SYNC DATA SOURCE - Offline/Test Implementation
// ==========================================
class SyncNetworkException implements Exception {
  final String message;
  const SyncNetworkException(this.message);
  @override
  String toString() => 'SyncNetworkException: $message';
}

/// Offline-safe, in-memory implementation of [RemoteSyncDataSource].
/// Prevents runtime crashes in environments without Firebase Native bindings (e.g. tests, desktop).
class DefaultRemoteSyncDataSource implements RemoteSyncDataSource {
  final Map<String, Map<String, dynamic>> _remoteStore = {};
  Map<String, dynamic> _globalSettings = {'holidays': <String, dynamic>{}};

  bool simulateOffline = false;
  Duration simulatedLatency = Duration.zero;

  DefaultRemoteSyncDataSource({
    Map<String, Map<String, dynamic>>? initialData,
    Map<String, dynamic>? initialGlobalSettings,
  }) {
    if (initialData != null) {
      _remoteStore.addAll(initialData);
    }
    if (initialGlobalSettings != null) {
      _globalSettings = Map<String, dynamic>.from(initialGlobalSettings);
    }
  }

  void seedRemoteUser(String uid, Map<String, dynamic> data) {
    _remoteStore[uid] = Map<String, dynamic>.from(data);
  }

  void setGlobalHolidays(Map<String, String> holidays) {
    _globalSettings = {'holidays': holidays};
  }

  Map<String, dynamic>? getRawRemoteUser(String uid) {
    final data = _remoteStore[uid];
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  @override
  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }
    if (simulateOffline) {
      throw const SyncNetworkException(
        'Network is unreachable (simulated offline)',
      );
    }
    final existing = _remoteStore[uid];
    if (existing == null) return null;
    return Map<String, dynamic>.from(existing);
  }

  @override
  Future<Map<String, dynamic>> updateUserData({
    required String uid,
    required Map<String, dynamic> localData,
    String? email,
    String? displayName,
  }) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }
    if (simulateOffline) {
      throw const SyncNetworkException(
        'Network is unreachable (simulated offline)',
      );
    }

    // Atomic transaction simulation matching Firestore runTransaction
    final existingCloud = _remoteStore[uid];
    final Map<String, dynamic> merged;
    if (existingCloud != null) {
      merged = mergeUserData(localData, existingCloud).toMap();
    } else {
      merged = migrateUserData(localData).data.toMap();
    }

    final toPersist = Map<String, dynamic>.from(merged)
      ..['email'] = email ?? ''
      ..['displayName'] = displayName ?? '';

    _remoteStore[uid] = toPersist;
    return merged;
  }

  @override
  Future<Map<String, dynamic>> fetchGlobalSettings() async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }
    if (simulateOffline) {
      return {'holidays': <String, dynamic>{}};
    }
    return Map<String, dynamic>.from(_globalSettings);
  }
}
