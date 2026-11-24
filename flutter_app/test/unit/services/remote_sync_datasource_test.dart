import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/sync/data/datasources/remote_sync_datasource_impl.dart';

void main() {
  group('RemoteSyncDataSource Unit Tests', () {
    late DefaultRemoteSyncDataSource dataSource;

    setUp(() {
      dataSource = DefaultRemoteSyncDataSource();
    });

    test('fetchUserData returns null when user doc does not exist', () async {
      final result = await dataSource.fetchUserData('nonexistent_uid');
      expect(result, isNull);
    });

    test('seedRemoteUser stores data and fetchUserData retrieves it', () async {
      final testData = {
        'schemaVersion': 2,
        'minPercent': 80.0,
        'subjects': [
          {'id': 'sub-1', 'name': 'Math', 'updatedAt': '2026-11-20T10:00:00Z'}
        ],
      };
      dataSource.seedRemoteUser('user-1', testData);

      final retrieved = await dataSource.fetchUserData('user-1');
      expect(retrieved, isNotNull);
      expect(retrieved!['minPercent'], 80.0);
      expect(retrieved['subjects'], isList);
      expect((retrieved['subjects'] as List).length, 1);
    });

    test('updateUserData performs atomic LWW merge and persists metadata', () async {
      // Cloud has subject-1 with newer timestamp
      final cloudData = {
        'schemaVersion': 2,
        'name': 'Cloud Name',
        'subjects': [
          {
            'id': 'sub-1',
            'name': 'Cloud Math',
            'color': '#00FF00',
            'updatedAt': '2026-11-22T10:00:00Z',
          }
        ],
        'updatedAt': '2026-11-20T10:00:00Z',
      };
      dataSource.seedRemoteUser('user-1', cloudData);

      // Local has subject-1 with older timestamp, but subject-2 as brand new
      final localData = {
        'schemaVersion': 2,
        'name': 'Local Name',
        'subjects': [
          {
            'id': 'sub-1',
            'name': 'Stale Local Math',
            'color': '#FF0000',
            'updatedAt': '2026-11-21T10:00:00Z',
          },
          {
            'id': 'sub-2',
            'name': 'Physics',
            'color': '#0000FF',
            'updatedAt': '2026-11-23T10:00:00Z',
          }
        ],
        'updatedAt': '2026-11-23T10:00:00Z',
      };

      final merged = await dataSource.updateUserData(
        uid: 'user-1',
        localData: localData,
        email: 'student@college.edu',
        displayName: 'College Student',
      );

      // LWW: sub-1 should win from cloud (2026-11-22 > 2026-11-21)
      final subjects = (merged['subjects'] as List).cast<Map<String, dynamic>>();
      final sub1 = subjects.firstWhere((s) => s['id'] == 'sub-1');
      expect(sub1['name'], 'Cloud Math');

      // sub-2 exists only in local, so it must be included
      final sub2 = subjects.firstWhere((s) => s['id'] == 'sub-2');
      expect(sub2['name'], 'Physics');

      // Check stored doc includes email and displayName
      final rawStored = dataSource.getRawRemoteUser('user-1');
      expect(rawStored!['email'], 'student@college.edu');
      expect(rawStored['displayName'], 'College Student');
    });

    test('fetchGlobalSettings returns default empty holidays map', () async {
      final global = await dataSource.fetchGlobalSettings();
      expect(global['holidays'], isA<Map>());
      expect((global['holidays'] as Map).isEmpty, isTrue);
    });

    test('setGlobalHolidays sets custom holidays successfully', () async {
      dataSource.setGlobalHolidays({'2026-12-25': 'Christmas'});
      final global = await dataSource.fetchGlobalSettings();
      expect((global['holidays'] as Map)['2026-12-25'], 'Christmas');
    });

    test('simulateOffline throws SyncNetworkException on fetch and update', () async {
      dataSource.simulateOffline = true;

      expect(
        () => dataSource.fetchUserData('user-1'),
        throwsA(isA<SyncNetworkException>()),
      );

      expect(
        () => dataSource.updateUserData(
          uid: 'user-1',
          localData: {'schemaVersion': 2},
        ),
        throwsA(isA<SyncNetworkException>()),
      );

      // fetchGlobalSettings falls back safely without throwing
      final global = await dataSource.fetchGlobalSettings();
      expect(global['holidays'], isEmpty);
    });
  });
}
