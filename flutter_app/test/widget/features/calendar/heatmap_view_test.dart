import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/core/utils/date_utils.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
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
    Brightness brightness = Brightness.dark,
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
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const Scaffold(body: SingleChildScrollView(child: HeatmapView())),
      ),
    );
  }

  group('HeatmapView Tests', () {
    testWidgets('Renders Y-axis day labels and legend', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('Renders attendance colors and today paper border correctly', (
      tester,
    ) async {
      final todayStrVal = formatDateKey(DateTime.now());
      final records = [
        AttendanceRecordEntity(
          id: 'rec-1',
          date: todayStrVal,
          subjectId: 'sub-1',
          sessionId: 's-1',
          status: AttendanceStatus.present,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Test dark mode
      await tester.pumpWidget(
        createWidget(records: records, brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();

      // Find the today cell which has a 2px Border with paperDark
      final todayContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final dec = c.decoration;
            if (dec is BoxDecoration && dec.border != null) {
              return dec.border!.top.color == AppColors.paperDark &&
                  dec.border!.top.width == 2.0;
            }
            return false;
          });
      expect(todayContainers.isNotEmpty, isTrue);

      // Verify inkGreen cell for 100% attendance
      final greenContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final dec = c.decoration;
            if (dec is BoxDecoration) {
              return dec.color == AppColors.inkGreen;
            }
            return false;
          });
      expect(greenContainers.isNotEmpty, isTrue);

      // Test light mode respects paperLight
      await tester.pumpWidget(
        createWidget(records: records, brightness: Brightness.light),
      );
      await tester.pumpAndSettle();

      final lightTodayContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final dec = c.decoration;
            if (dec is BoxDecoration && dec.border != null) {
              return dec.border!.top.color == AppColors.paperLight &&
                  dec.border!.top.width == 2.0;
            }
            return false;
          });
      expect(lightTodayContainers.isNotEmpty, isTrue);
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
      expect(find.text('Mon'), findsOneWidget);
    });
  });
}
