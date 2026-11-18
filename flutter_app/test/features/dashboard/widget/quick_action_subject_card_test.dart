import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/dashboard/domain/models/subject_attendance_stats.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/quick_action_subject_card.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    darkTheme: ThemeData.dark(),
    themeMode: ThemeMode.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final now = DateTime(2026, 11, 18);
  final subject = SubjectEntity(
    id: 'sub_algo',
    name: 'Algorithms & Data Structures',
    color: '#3B82F6',
    createdAt: now,
    updatedAt: now,
  );

  group('QuickActionSubjectCard Widget Tests', () {
    testWidgets('Renders subject details, percentage, and safe bunk chip', (tester) async {
      final stats = SubjectAttendanceStats(
        subject: subject,
        conducted: 20,
        present: 18,
        absent: 2,
        percentage: 90.0,
        canMiss: 4,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      await tester.pumpWidget(_wrap(QuickActionSubjectCard(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('Algorithms & Data Structures'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);
      expect(find.text('18 / 20 classes'), findsOneWidget);
      expect(find.text('+4 safe'), findsOneWidget);
      expect(find.text('+ Present'), findsOneWidget);
      expect(find.text('- Absent'), findsOneWidget);
    });

    testWidgets('Renders danger chip when attendance is below threshold', (tester) async {
      final stats = SubjectAttendanceStats(
        subject: subject,
        conducted: 10,
        present: 5,
        absent: 5,
        percentage: 50.0,
        canMiss: 0,
        needToAttend: 10,
        isImpossible: false,
        isSafe: false,
      );

      await tester.pumpWidget(_wrap(QuickActionSubjectCard(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('50.0%'), findsOneWidget);
      expect(find.text('5 / 10 classes'), findsOneWidget);
      expect(find.text('Need 10'), findsOneWidget);
    });

    testWidgets('Renders New chip and dash for zero conducted classes', (tester) async {
      final stats = SubjectAttendanceStats(
        subject: subject,
        conducted: 0,
        present: 0,
        absent: 0,
        percentage: null,
        canMiss: 0,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      await tester.pumpWidget(_wrap(QuickActionSubjectCard(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
      expect(find.text('0 / 0 classes'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('Renders On edge chip when safe but canMiss == 0', (tester) async {
      final stats = SubjectAttendanceStats(
        subject: subject,
        conducted: 4,
        present: 3,
        absent: 1,
        percentage: 75.0,
        canMiss: 0,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      await tester.pumpWidget(_wrap(QuickActionSubjectCard(stats: stats)));
      await tester.pumpAndSettle();

      expect(find.text('On edge'), findsOneWidget);
    });

    testWidgets('Tapping + Present and - Absent triggers respective callbacks', (tester) async {
      var presentTapped = false;
      var absentTapped = false;

      final stats = SubjectAttendanceStats(
        subject: subject,
        conducted: 10,
        present: 8,
        absent: 2,
        percentage: 80.0,
        canMiss: 0,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      await tester.pumpWidget(_wrap(QuickActionSubjectCard(
        stats: stats,
        onPresent: () => presentTapped = true,
        onAbsent: () => absentTapped = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Present'));
      await tester.pump();
      expect(presentTapped, isTrue);

      await tester.tap(find.text('- Absent'));
      await tester.pump();
      expect(absentTapped, isTrue);
    });

    testWidgets(
        'Renders cleanly without overflow on compact 320x568 viewport with 1.5x text scaler and large counts',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final extremeStats = SubjectAttendanceStats(
        subject: subject,
        conducted: 1500,
        present: 1250,
        absent: 250,
        percentage: 83.3,
        canMiss: 15,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: QuickActionSubjectCard(stats: extremeStats),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuickActionSubjectCard), findsOneWidget);
    });
  });
}
