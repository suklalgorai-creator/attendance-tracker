/// Contract for remote cloud synchronization data sources.
/// Replicates Firestore operations from react_app/src/services/cloudSync.js.
abstract class RemoteSyncDataSource {
  /// Fetches raw user data snapshot from remote doc 'users/{uid}'.
  /// Returns null if the document does not exist.
  Future<Map<String, dynamic>?> fetchUserData(String uid);

  /// Executes an atomic transaction on 'users/{uid}':
  /// 1. Reads remote snapshot.
  /// 2. Merges with [localData] using LWW [mergeUserData].
  /// 3. Writes back merged state with [email] and [displayName].
  /// Returns the canonical merged dataset.
  Future<Map<String, dynamic>> updateUserData({
    required String uid,
    required Map<String, dynamic> localData,
    String? email,
    String? displayName,
  });

  /// Fetches global settings from 'settings/global' containing holiday lists.
  /// Returns a map with `'holidays': <String, dynamic>{}` on absence or error.
  Future<Map<String, dynamic>> fetchGlobalSettings();
}
