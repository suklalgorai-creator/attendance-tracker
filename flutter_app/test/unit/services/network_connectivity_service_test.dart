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

    test('initial status defaults to true', () async {
      expect(await service.isOnline, isTrue);
    });

    test('setOnline updates isOnline correctly', () async {
      service.setOnline(false);
      expect(await service.isOnline, isFalse);

      service.setOnline(true);
      expect(await service.isOnline, isTrue);
    });

    test('onConnectivityChanged emits events on state transition', () async {
      final emitted = <bool>[];
      final sub = service.onConnectivityChanged.listen(emitted.add);

      service.setOnline(false);
      service.setOnline(true);
      service.setOnline(true); // Redundant transition, should not duplicate
      service.setOnline(false);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(emitted, [false, true, false]);

      await sub.cancel();
    });
  });
}
