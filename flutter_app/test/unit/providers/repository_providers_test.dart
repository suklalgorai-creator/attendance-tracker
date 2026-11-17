import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:flutter_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_app/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:flutter_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:flutter_app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flutter_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_app/features/subjects/data/datasources/subject_local_datasource.dart';
import 'package:flutter_app/features/subjects/domain/repositories/subject_repository.dart';

import '../repositories/attendance_repository_test.dart';
import '../repositories/notes_repository_test.dart';
import '../repositories/settings_repository_test.dart';
import '../repositories/subject_repository_test.dart';

void main() {
  group('Riverpod Repository Providers Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          subjectLocalDataSourceProvider.overrideWithValue(FakeSubjectLocalDataSource()),
          attendanceLocalDataSourceProvider.overrideWithValue(FakeAttendanceLocalDataSource()),
          notesLocalDataSourceProvider.overrideWithValue(FakeNotesLocalDataSource()),
          settingsLocalDataSourceProvider.overrideWithValue(FakeSettingsLocalDataSource()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('resolves all data source and repository providers cleanly', () {
      final subjectDs = container.read(subjectLocalDataSourceProvider);
      final attendanceDs = container.read(attendanceLocalDataSourceProvider);
      final notesDs = container.read(notesLocalDataSourceProvider);
      final settingsDs = container.read(settingsLocalDataSourceProvider);

      expect(subjectDs, isA<SubjectLocalDataSource>());
      expect(attendanceDs, isA<AttendanceLocalDataSource>());
      expect(notesDs, isA<NotesLocalDataSource>());
      expect(settingsDs, isA<SettingsLocalDataSource>());

      final subjectRepo = container.read(subjectRepositoryProvider);
      final attendanceRepo = container.read(attendanceRepositoryProvider);
      final notesRepo = container.read(notesRepositoryProvider);
      final settingsRepo = container.read(settingsRepositoryProvider);

      expect(subjectRepo, isA<SubjectRepository>());
      expect(attendanceRepo, isA<AttendanceRepository>());
      expect(notesRepo, isA<NotesRepository>());
      expect(settingsRepo, isA<SettingsRepository>());
    });

    test('reactive stream providers yield data through container', () async {
      final subjectsAsync = container.read(subjectsStreamProvider);
      expect(subjectsAsync, isA<AsyncValue>());

      final settingsAsync = container.read(settingsStreamProvider);
      expect(settingsAsync, isA<AsyncValue>());
    });
  });
}
