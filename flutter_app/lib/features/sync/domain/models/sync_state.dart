enum SyncStatus { idle, syncing, synced, offlineWarning, error }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? message;
  final bool hasPendingChanges;
  final List<String> warnings;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.message,
    this.hasPendingChanges = false,
    this.warnings = const [],
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? message,
    bool? hasPendingChanges,
    List<String>? warnings,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: message ?? this.message,
      hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
      warnings: warnings ?? this.warnings,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          lastSyncedAt == other.lastSyncedAt &&
          message == other.message &&
          hasPendingChanges == other.hasPendingChanges;

  @override
  int get hashCode =>
      Object.hash(status, lastSyncedAt, message, hasPendingChanges);

  @override
  String toString() =>
      'SyncState(status: $status, lastSyncedAt: $lastSyncedAt, pending: $hasPendingChanges)';
}

class SyncResult {
  final bool isSuccess;
  final bool isOffline;
  final bool isInProgress;
  final bool skippedGuest;
  final String? error;

  const SyncResult({
    required this.isSuccess,
    this.isOffline = false,
    this.isInProgress = false,
    this.skippedGuest = false,
    this.error,
  });

  factory SyncResult.success({bool skippedGuest = false}) =>
      SyncResult(isSuccess: true, skippedGuest: skippedGuest);
  factory SyncResult.inProgress() =>
      const SyncResult(isSuccess: false, isInProgress: true);
  factory SyncResult.offlineQueued(String error) =>
      SyncResult(isSuccess: false, isOffline: true, error: error);
}

class SyncLoadResult {
  final bool isSuccess;
  final bool isOfflineFallback;
  final List<String> warnings;

  const SyncLoadResult({
    required this.isSuccess,
    this.isOfflineFallback = false,
    required this.warnings,
  });

  factory SyncLoadResult.success({required List<String> warnings}) =>
      SyncLoadResult(isSuccess: true, warnings: warnings);
  factory SyncLoadResult.offlineFallback({required List<String> warnings}) =>
      SyncLoadResult(
        isSuccess: true,
        isOfflineFallback: true,
        warnings: warnings,
      );
}
