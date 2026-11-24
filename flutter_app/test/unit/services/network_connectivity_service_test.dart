import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/services/network_connectivity_service.dart';

void main() {
  group('NetworkConnectivityService Unit Tests', () {
    late FakeNetworkConnectivityService service;

    setUp(() {
      service = FakeNetworkConnectivityService(initialOnline: true);
    });

    tearDown(() {
      service.dispose();
    });

    test('isOnline returns initial online status', () async {
      expect(await service.isOnline, isTrue);

      final offlineService = FakeNetworkConnectivityService(initialOnline: false);
      expect(await offlineService.isOnline, isFalse);
      offlineService.dispose();
    });

    test('onConnectivityChanged broadcasts transitions between online and offline', () async {
      final events = <bool>[];
      final subscription = service.onConnectivityChanged.listen(events.add);

      service.setOnline(false);
      service.setOnline(true);
      service.setOnline(false);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, equals([false, true, false]));
      expect(await service.isOnline, isFalse);

      await subscription.cancel();
    });

    test('setting the same online status does not trigger duplicate events', () async {
      final events = <bool>[];
      final subscription = service.onConnectivityChanged.listen(events.add);

      service.setOnline(true); // already true
      service.setOnline(false);
      service.setOnline(false); // already false

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, equals([false]));

      await subscription.cancel();
    });
  });
}

