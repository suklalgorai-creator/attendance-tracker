import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/core/services/database_service.dart';
import 'package:flutter_app/features/subjects/data/datasources/subject_local_datasource.dart';
import 'package:flutter_app/features/subjects/data/models/subject_model.dart';
import 'package:flutter_app/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:flutter_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:flutter_app/features/notes/data/models/note_model.dart';
import 'package:flutter_app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flutter_app/features/settings/data/models/user_settings_model.dart';

void main() {
  group('DatabaseService & Local DataSources Integration Tests with Real Hive', () {
    late Directory tempDir;
    late Box subjectsBox;
    late Box subjectsV2Box;
    late Box attendanceBox;
    late Box legacyBox;
    late Box notesBox;
    late Box settingsBox;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);

      subjectsBox = await Hive.openBox(DatabaseService.subjectsBoxName);
      subjectsV2Box = await Hive.openBox(DatabaseService.subjectsV2BoxName);
      attendanceBox = await Hive.openBox(
        DatabaseService.attendanceRecordsBoxName,
      );
      legacyBox = await Hive.openBox(DatabaseService.legacyAttendanceBoxName);
      notesBox = await Hive.openBox(DatabaseService.notesBoxName);
      settingsBox = await Hive.openBox(DatabaseService.settingsBoxName);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'SubjectLocalDataSourceImpl reads and writes to real Hive box',
      () async {
        final dataSource = SubjectLocalDataSourceImpl(box: subjectsV2Box);
        final now = DateTime(2026, 3, 1, 10, 0);

        final subject = SubjectModel(
          id: 's-hive-1',
          name: 'Database Systems',
          createdAt: now,
          updatedAt: now,
        );

        await dataSource.saveSubject(subject);
        final retrieved = await dataSource.getSubjects();

        expect(retrieved.length, 1);
        expect(retrieved.first.name, 'Database Systems');

        final byId = await dataSource.getSubjectById('s-hive-1');
        expect(byId, isNotNull);
        expect(byId!.name, 'Database Systems');

        await dataSource.deleteSubject('s-hive-1');
        expect((await dataSource.getSubjects()).isEmpty, isTrue);
      },
    );

    test(
      'AttendanceLocalDataSourceImpl reads and writes records to real Hive box',
      () async {
        final dataSource = AttendanceLocalDataSourceImpl(
          recordsBox: attendanceBox,
          legacyBox: legacyBox,
        );
        final now = DateTime(2026, 3, 1, 11, 0);

        final record = AttendanceRecordModel(
          id: 'att-hive-1',
          date: '2026-03-01',
          sessionId: 'session-1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        );

        await dataSource.saveAttendanceRecord(record);
        final records = await dataSource.getAttendanceRecords();

        expect(records.length, 1);
        expect(records.first.id, 'att-hive-1');

        await dataSource.clearAllAttendanceHistory();
        expect((await dataSource.getAttendanceRecords()).isEmpty, isTrue);
      },
    );

    test(
      'NotesLocalDataSourceImpl reads and writes notes to real Hive box',
      () async {
        final dataSource = NotesLocalDataSourceImpl(box: notesBox);
        final now = DateTime(2026, 3, 1, 12, 0);

        final note = NoteModel(
          id: 'n-hive-1',
          content: 'Check lab assignment',
          createdAt: now,
        );

        await dataSource.saveNote(note);
        final notes = await dataSource.getNotes();

        expect(notes.length, 1);
        expect(notes.first.content, 'Check lab assignment');

        await dataSource.deleteNote('n-hive-1');
        expect((await dataSource.getNotes()).isEmpty, isTrue);
      },
    );

    test(
      'SettingsLocalDataSourceImpl reads, writes, and resets settings in real Hive box',
      () async {
        final dataSource = SettingsLocalDataSourceImpl(box: settingsBox);

        final defaultSettings = await dataSource.getSettings();
        expect(defaultSettings.minPercent, 75.0);

        const customSettings = UserSettingsModel(
          name: 'Hive User',
          minPercent: 85.0,
        );

        await dataSource.saveSettings(customSettings);
        final loaded = await dataSource.getSettings();
        expect(loaded.name, 'Hive User');
        expect(loaded.minPercent, 85.0);

        await dataSource.resetSettings();
        final afterReset = await dataSource.getSettings();
        expect(afterReset.name, '');
        expect(afterReset.minPercent, 75.0);
      },
    );

    test('DatabaseService.clearAllBoxes clears all open boxes', () async {
      await subjectsBox.put('subjects', [
        {'id': '0'},
      ]);
      await subjectsV2Box.put('items', [
        {'id': '1'},
      ]);
      await notesBox.put('items', [
        {'id': '2'},
      ]);

      expect(subjectsBox.isNotEmpty, isTrue);
      expect(subjectsV2Box.isNotEmpty, isTrue);
      expect(notesBox.isNotEmpty, isTrue);

      await DatabaseService.clearAllBoxes();

      expect(subjectsBox.isEmpty, isTrue);
      expect(subjectsV2Box.isEmpty, isTrue);
      expect(notesBox.isEmpty, isTrue);
    });
  });
}
