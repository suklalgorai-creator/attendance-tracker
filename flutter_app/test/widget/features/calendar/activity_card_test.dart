import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/calendar/presentation/widgets/activity_card.dart';
import 'package:flutter_app/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:flutter_app/features/calendar/presentation/widgets/heatmap_view.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createWidget({
    List<AttendanceRecordEntity> records = const [],
    List<LegacyAttendanceEntity> legacy = const [],
    UserSettingsEntity? settings,
  }) {
    return ProviderScope(
      overrides: [
        attendanceRecordsStreamProvider.overrideWith(
          (ref) => Stream.value(records),
        ),
        legacyAttendanceStreamProvider.overrideWith(
          (ref) => Stream.value(legacy),
        ),
        settingsStreamProvider.overrideWith(
          (ref) => Stream.value(settings ?? const UserSettingsEntity()),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ActivityCard())),
      ),
    );
  }

  group('ActivityCard Tests', () {
    testWidgets('Renders Activity title and Month/Heatmap toggle buttons', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Heatmap'), findsOneWidget);
    });

    testWidgets('Toggles between CalendarView and HeatmapView', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially shows CalendarViewWidget
      expect(find.byType(CalendarViewWidget), findsOneWidget);
      expect(find.byType(HeatmapView), findsNothing);

      // Tap 'Heatmap'
      await tester.tap(find.text('Heatmap'));
      await tester.pumpAndSettle();

      expect(find.byType(HeatmapView), findsOneWidget);
      expect(find.byType(CalendarViewWidget), findsNothing);

      // Tap 'Month'
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarViewWidget), findsOneWidget);
      expect(find.byType(HeatmapView), findsNothing);
    });

    testWidgets('Renders cleanly on 320px narrow width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Activity'), findsOneWidget);
    });
  });
}
