import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/data_migration.dart';
import '../../domain/datasources/remote_sync_datasource.dart';
import 'remote_sync_datasource_impl.dart';

/// Production [RemoteSyncDataSource] backed by Cloud Firestore,
/// matching `react_app/src/services/cloudSync.js` (`users/{uid}` and `settings/global`).
class FirestoreRemoteSyncDataSource implements RemoteSyncDataSource {
  final FirebaseFirestore? _firestoreOverride;

  FirestoreRemoteSyncDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    try {
      final snapshot = await _db.collection('users').doc(uid).get();
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      return data != null ? Map<String, dynamic>.from(data) : null;
    } on FirebaseException catch (e) {
      throw SyncNetworkException(e.message ?? 'Failed to fetch user data.');
    } catch (e) {
      throw SyncNetworkException('Failed to fetch user data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> updateUserData({
    required String uid,
    required Map<String, dynamic> localData,
    String? email,
    String? displayName,
  }) async {
    try {
      final userRef = _db.collection('users').doc(uid);
      final merged = await _db.runTransaction<Map<String, dynamic>>((tx) async {
        final snapshot = await tx.get(userRef);
        final cloudData = snapshot.exists ? snapshot.data() : null;
        final Map<String, dynamic> resolved = cloudData != null
            ? mergeUserData(localData, cloudData).toMap()
            : migrateUserData(localData).data.toMap();

        final toPersist = Map<String, dynamic>.from(resolved)
          ..['email'] = email ?? ''
          ..['displayName'] = displayName ?? '';

        tx.set(userRef, toPersist);
        return resolved;
      });
      return merged;
    } on FirebaseException catch (e) {
      throw SyncNetworkException(e.message ?? 'Firestore sync transaction failed.');
    } catch (e) {
      throw SyncNetworkException('Firestore sync transaction failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchGlobalSettings() async {
    try {
      final snapshot = await _db.collection('settings').doc('global').get();
      if (!snapshot.exists) {
        return {'holidays': <String, dynamic>{}};
      }
      final data = snapshot.data();
      return data != null
          ? Map<String, dynamic>.from(data)
          : {'holidays': <String, dynamic>{}};
    } catch (_) {
      return {'holidays': <String, dynamic>{}};
    }
  }
}
