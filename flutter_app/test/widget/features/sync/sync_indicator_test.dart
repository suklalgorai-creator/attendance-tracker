import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/sync/domain/models/sync_state.dart';
import 'package:flutter_app/features/sync/presentation/widgets/sync_indicator_widget.dart';

void main() {
  Widget buildWidget({required SyncState state}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SyncIndicatorWidget(overrideState: state),
        ),
      ),
    );
  }

  group('SyncIndicatorWidget Tests', () {
    testWidgets('renders cloud_done icon when status is synced', (tester) async {
      await tester.pumpWidget(buildWidget(
        state: SyncState(
          status: SyncStatus.synced,
          lastSyncedAt: DateTime.now(),
        ),
      ));

      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('renders CircularProgressIndicator when status is syncing', (tester) async {
      await tester.pumpWidget(buildWidget(
        state: const SyncState(status: SyncStatus.syncing),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders cloud_off icon when status is offlineWarning', (tester) async {
      await tester.pumpWidget(buildWidget(
        state: const SyncState(
          status: SyncStatus.offlineWarning,
          hasPendingChanges: true,
        ),
      ));

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('renders cloud_outlined icon when status is idle', (tester) async {
      await tester.pumpWidget(buildWidget(
        state: const SyncState(status: SyncStatus.idle),
      ));

      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    });
  });
}
