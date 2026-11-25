import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter_app/features/leaderboard/presentation/leaderboard_page.dart';
import 'package:flutter_app/features/register/presentation/pages/register_page.dart';
import 'package:flutter_app/features/settings/presentation/settings_page.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/subjects/domain/repositories/subject_repository.dart';

class ViewportTestSettingsRepo implements SettingsRepository {
  final UserSettingsEntity _settings = const UserSettingsEntity(
    name: 'Compact Viewport Tester',
    programName: 'B.Tech IT',
    courseName: 'Semester 3',
    minPercent: 75.0,
    classDays: [1, 2, 3, 4, 5],
  );

  @override
  Future<UserSettingsEntity> getSettings() async => _settings;
  @override
  Stream<UserSettingsEntity> watchSettings() => Stream.value(_settings);
  @override
  Future<void> saveSettings(UserSettingsEntity s) async {}
  @override
  Future<void> resetSettings() async {}
}

class ViewportTestSubjectRepo implements SubjectRepository {
  final List<SubjectEntity> _subjects = [
    SubjectEntity(
      id: 'sub_1',
      name: 'Microprocessors & Embedded Systems',
      code: 'EC301',
      color: '#10B981',
      createdAt: DateTime(2026, 11, 20),
      updatedAt: DateTime(2026, 11, 20),
    ),
  ];

  @override
  Future<List<SubjectEntity>> getSubjects({
    bool includeDeleted = false,
  }) async => _subjects;
  @override
  Stream<List<SubjectEntity>> watchSubjects({bool includeDeleted = false}) =>
      Stream.value(_subjects);
  @override
  Future<SubjectEntity?> getSubjectById(String id) async => _subjects.first;
  @override
  Future<void> saveSubject(SubjectEntity s) async {}
  @override
  Future<void> saveSubjects(List<SubjectEntity> l) async {}
  @override
  Future<void> reorderSubjects(List<String> o) async {}
  @override
  Future<void> deleteSubject(String id) async {}
  @override
  Future<void> restoreSubject(String id) async {}
  @override
  Future<void> hardDeleteSubject(String id) async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildViewportHarness({
    required Widget child,
    required Size screenSize,
  }) {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          ViewportTestSettingsRepo(),
        ),
        subjectRepositoryProvider.overrideWithValue(ViewportTestSubjectRepo()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: Scaffold(
            body: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('Phase 7: Compact Viewport (320px) Regression Audit', () {
    const compact320 = Size(
      320,
      568,
    ); // iPhone SE 1st gen / narrowest mobile width

    testWidgets(
      'DashboardPage renders cleanly without overflow on 320px viewport',
      (tester) async {
        await tester.binding.setSurfaceSize(compact320);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildViewportHarness(
            child: const DashboardPage(),
            screenSize: compact320,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(DashboardPage), findsOneWidget);
      },
    );

    testWidgets(
      'RegisterPage renders cleanly without overflow on 320px viewport',
      (tester) async {
        await tester.binding.setSurfaceSize(compact320);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildViewportHarness(
            child: const RegisterPage(),
            screenSize: compact320,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(RegisterPage), findsOneWidget);
      },
    );

    testWidgets(
      'LeaderboardPage renders cleanly without overflow on 320px viewport',
      (tester) async {
        await tester.binding.setSurfaceSize(compact320);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildViewportHarness(
            child: const LeaderboardPage(),
            screenSize: compact320,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(LeaderboardPage), findsOneWidget);
      },
    );

    testWidgets(
      'SettingsPage renders cleanly without overflow on 320px viewport',
      (tester) async {
        await tester.binding.setSurfaceSize(compact320);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildViewportHarness(
            child: const SettingsPage(),
            screenSize: compact320,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(SettingsPage), findsOneWidget);
      },
    );
  });
}
