import 'dart:async';
import '../../../../core/services/network_connectivity_service.dart';
import '../../../../core/utils/data_migration.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../settings/domain/services/backup_service.dart';
import '../datasources/remote_sync_datasource.dart';
import '../models/sync_state.dart';

class CloudSyncService {
  final Duration debounceDuration;

  final RemoteSyncDataSource _remoteDataSource;
  final BackupService _backupService;
  final NetworkConnectivityService _connectivityService;

  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();
  SyncState _currentState = const SyncState();

  Timer? _debounceTimer;
  StreamSubscription<bool>? _connectivitySub;
  AuthUserEntity? _currentUser;
  bool _isSyncing = false;
  bool _isApplyingRemoteMerge = false;

  CloudSyncService({
    required RemoteSyncDataSource remoteDataSource,
    required BackupService backupService,
    required NetworkConnectivityService connectivityService,
    Duration? debounceDuration,
  }) : _remoteDataSource = remoteDataSource,
       _backupService = backupService,
       _connectivityService = connectivityService,
       debounceDuration = debounceDuration ?? const Duration(seconds: 5) {
    _initConnectivityListener();
  }

  Stream<SyncState> get syncStateStream => _stateController.stream;
  SyncState get currentState => _currentState;
  bool get isSyncing => _isSyncing;
  bool get isApplyingRemoteMerge => _isApplyingRemoteMerge;
  bool get hasActiveDebounceTimer => _debounceTimer?.isActive ?? false;

  void _updateState(SyncState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  void _initConnectivityListener() {
    _connectivitySub = _connectivityService.onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline && _currentState.hasPendingChanges && !_isSyncing) {
        // Automatic sync retry on re-established connection
        flushToCloud();
      }
    });
  }

  /// Sets the currently active user session.
  void updateUser(AuthUserEntity? user) {
    _currentUser = user;
    if (user == null || user.isGuest) {
      _debounceTimer?.cancel();
      _updateState(const SyncState(status: SyncStatus.idle));
    }
  }

  /// Schedules a 5-second debounced synchronization.
  /// Called on local data changes across subjects, attendance, timetable, notes, and settings.
  void scheduleDebouncedSync() {
    if (_isApplyingRemoteMerge) return;
    final user = _currentUser;
    if (user == null || user.isGuest || user.id == 'guest') return;

    _updateState(_currentState.copyWith(hasPendingChanges: true));
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      flushToCloud();
    });
  }

  /// Executes an immediate synchronization cycle with Firestore.
  /// Bypasses debounce timer, reads atomic cloud snapshot, merges via LWW,
  /// saves back locally, and handles offline fallbacks.
  Future<SyncResult> flushToCloud() async {
    _debounceTimer?.cancel();

    final user = _currentUser;
    if (user == null || user.isGuest || user.id == 'guest') {
      _updateState(
        _currentState.copyWith(
          status: SyncStatus.idle,
          hasPendingChanges: false,
        ),
      );
      return SyncResult.success(skippedGuest: true);
    }

    if (_isSyncing) {
      return SyncResult.inProgress();
    }

    _isSyncing = true;
    _updateState(_currentState.copyWith(status: SyncStatus.syncing));

    try {
      final isOnline = await _connectivityService.isOnline;
      if (!isOnline) {
        throw Exception('Device is currently offline.');
      }

      // 1. Export current local Schema V2 data
      final backupEnvelope = await _backupService.createBackup();
      final localData = (backupEnvelope['data'] is Map<String, dynamic>)
          ? backupEnvelope['data'] as Map<String, dynamic>
          : backupEnvelope;

      // 2. Perform atomic cloud transaction
      final mergedData = await _remoteDataSource.updateUserData(
        uid: user.id,
        localData: localData,
        email: user.email,
        displayName: user.displayName,
      );

      // 3. Restore canonical merged state to Hive with loop guard
      _isApplyingRemoteMerge = true;
      try {
        await _backupService.restoreBackup(mergedData);
      } finally {
        _isApplyingRemoteMerge = false;
      }

      final now = DateTime.now();
      _updateState(
        SyncState(
          status: SyncStatus.synced,
          lastSyncedAt: now,
          hasPendingChanges: false,
        ),
      );

      return SyncResult.success();
    } catch (error) {
      // Offline fallback: Queue pending changes and notify UI
      _updateState(
        _currentState.copyWith(
          status: SyncStatus.offlineWarning,
          message: 'Cloud sync unavailable; offline changes queued.',
          hasPendingChanges: true,
        ),
      );
      return SyncResult.offlineQueued(error.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Initial load and hydration on login matching React loadUserData(uid).
  Future<SyncLoadResult> loadUserData(String uid) async {
    if (uid == 'guest') {
      _updateState(const SyncState(status: SyncStatus.idle));
      return SyncLoadResult.success(warnings: []);
    }

    _updateState(_currentState.copyWith(status: SyncStatus.syncing));

    try {
      final isOnline = await _connectivityService.isOnline;
      if (!isOnline) {
        throw Exception('Device is currently offline.');
      }

      // 1. Read local state
      final backupEnvelope = await _backupService.createBackup();
      final localData = (backupEnvelope['data'] is Map<String, dynamic>)
          ? backupEnvelope['data'] as Map<String, dynamic>
          : backupEnvelope;

      // 2. Fetch remote document
      final cloudData = await _remoteDataSource.fetchUserData(uid);

      if (cloudData == null) {
        // First cloud sync for fresh user
        await flushToCloud();
        return SyncLoadResult.success(warnings: []);
      }

      // 3. Merge entity-by-entity
      final merged = mergeUserData(localData, cloudData);

      _isApplyingRemoteMerge = true;
      try {
        await _backupService.restoreBackup(merged.toMap());
      } finally {
        _isApplyingRemoteMerge = false;
      }

      final normalizedCloud = migrateUserData(cloudData).data.toMap();
      final needsSync = !_mapsEqual(merged.toMap(), normalizedCloud);

      if (needsSync) {
        scheduleDebouncedSync();
      }

      _updateState(
        SyncState(
          status: SyncStatus.synced,
          lastSyncedAt: DateTime.now(),
          hasPendingChanges: needsSync,
        ),
      );

      return SyncLoadResult.success(warnings: []);
    } catch (error) {
      // Cloud unavailable; fallback to local data with warning matching React
      _updateState(
        _currentState.copyWith(
          status: SyncStatus.offlineWarning,
          message: 'Cloud data is currently unavailable; using local data.',
          hasPendingChanges: true,
        ),
      );
      return SyncLoadResult.offlineFallback(
        warnings: const [
          'Cloud data is currently unavailable; using local data.',
        ],
      );
    }
  }

  bool _mapsEqual(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] is Map && b[key] is Map) {
        if (!_mapsEqual(a[key] as Map, b[key] as Map)) return false;
      } else if (a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySub?.cancel();
    _stateController.close();
  }
}
