import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/sync/data/datasources/remote_sync_datasource_impl.dart';

void main() {
  group('RemoteSyncDataSource Unit Tests', () {
    late DefaultRemoteSyncDataSource dataSource;

    setUp(() {
      dataSource = DefaultRemoteSyncDataSource();
    });

    test('fetchUserData returns null on nonexistent document', () async {
      final data = await dataSource.fetchUserData('user_none');
      expect(data, isNull);
    });

    test(
      'updateUserData writes initial dataset when cloud document is empty',
      () async {
        final local = {
          'schemaVersion': 2,
          'subjects': [
            {'id': 'sub_1', 'name': 'Physics'},
          ],
        };

        final merged = await dataSource.updateUserData(
          uid: 'user_1',
          localData: local,
          email: 'user1@college.edu',
          displayName: 'User One',
        );

        expect(merged['subjects'].length, 1);
        expect(merged['subjects'][0]['name'], 'Physics');

        final stored = dataSource.getRawRemoteUser('user_1');
        expect(stored?['email'], 'user1@college.edu');
        expect(stored?['displayName'], 'User One');
      },
    );

    test(
      'updateUserData executes atomic LWW merge against existing cloud snapshot',
      () async {
        dataSource.seedRemoteUser('user_2', {
          'schemaVersion': 2,
          'updatedAt': '2026-10-01T10:00:00.000Z',
          'subjects': [
            {
              'id': 'sub_cloud',
              'name': 'Cloud Chemistry',
              'updatedAt': '2026-10-01T10:00:00.000Z',
            },
          ],
          'attendanceRecords': [
            {
              'id': 'rec_1',
              'date': '2026-10-01',
              'sessionId': 's1',
              'status': 'PRESENT',
              'updatedAt': '2026-10-01T10:00:00.000Z',
            },
          ],
        });

        final local = {
          'schemaVersion': 2,
          'updatedAt': '2026-10-02T10:00:00.000Z',
          'subjects': [
            {
              'id': 'sub_local',
              'name': 'Local Math',
              'updatedAt': '2026-10-02T10:00:00.000Z',
            },
          ],
          'attendanceRecords': [
            {
              'id': 'rec_1',
              'date': '2026-10-01',
              'sessionId': 's1',
              'status': 'ABSENT',
              'updatedAt': '2026-10-02T10:00:00.000Z', // newer than cloud
            },
          ],
        };

        final merged = await dataSource.updateUserData(
          uid: 'user_2',
          localData: local,
        );

        // Both subjects coexist
        expect(merged['subjects'].length, 2);

        // Newer local record (ABSENT) won over cloud (PRESENT)
        final record = (merged['attendanceRecords'] as List).firstWhere(
          (r) => r['id'] == 'rec_1',
        );
        expect(record['status'], 'ABSENT');
      },
    );

    test(
      'simulateOffline throws SyncNetworkException on fetch and update',
      () async {
        dataSource.simulateOffline = true;

        expect(
          () => dataSource.fetchUserData('u1'),
          throwsA(isA<SyncNetworkException>()),
        );

        expect(
          () => dataSource.updateUserData(uid: 'u1', localData: {}),
          throwsA(isA<SyncNetworkException>()),
        );
      },
    );

    test(
      'fetchGlobalSettings returns holiday schedule or empty fallback',
      () async {
        var settings = await dataSource.fetchGlobalSettings();
        expect(settings['holidays'], isEmpty);

        dataSource.setGlobalHolidays({'2026-12-25': 'Christmas'});
        settings = await dataSource.fetchGlobalSettings();
        expect(settings['holidays']['2026-12-25'], 'Christmas');
      },
    );
  });
}
