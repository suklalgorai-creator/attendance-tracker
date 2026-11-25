import 'package:hive_flutter/hive_flutter.dart';
import '../../models/subject.dart';

/// Central database service managing Hive local storage boxes for Schema Version 2.
class DatabaseService {
  static const String subjectsBoxName = 'subjects_box'; // legacy compatibility
  static const String subjectsV2BoxName = 'subjects_v2_box';
  static const String attendanceRecordsBoxName = 'attendance_records_box';
  static const String legacyAttendanceBoxName = 'legacy_attendance_box';
  static const String notesBoxName = 'notes_box';
  static const String settingsBoxName = 'settings_box';
  static const String dailyFlowTasksBoxName = 'dailyflow_tasks_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(subjectsBoxName),
      Hive.openBox(subjectsV2BoxName),
      Hive.openBox(attendanceRecordsBoxName),
      Hive.openBox(legacyAttendanceBoxName),
      Hive.openBox(notesBoxName),
      Hive.openBox(settingsBoxName),
      Hive.openBox(dailyFlowTasksBoxName),
    ]);
  }

  static Box getBox(String name) => Hive.box(name);

  static bool isBoxOpen(String name) => Hive.isBoxOpen(name);

  /// Clears all stored data across all boxes. Useful for tests and data resets.
  static Future<void> clearAllBoxes() async {
    final boxesToClear = [
      subjectsBoxName,
      subjectsV2BoxName,
      attendanceRecordsBoxName,
      legacyAttendanceBoxName,
      notesBoxName,
      settingsBoxName,
      dailyFlowTasksBoxName,
    ];
    await Future.wait(
      boxesToClear
          .where((boxName) => Hive.isBoxOpen(boxName))
          .map((boxName) => getBox(boxName).clear()),
    );
  }

  /// Closes all open Hive boxes.
  static Future<void> close() async {
    await Hive.close();
  }

  // Legacy helper methods preserved for backward compatibility
  static Box get _box => Hive.box(subjectsBoxName);

  static List<Subject> getSubjects() {
    final rawData = _box.get('subjects', defaultValue: []);
    if (rawData is List) {
      return rawData
          .map(
            (item) => Subject.fromMap(Map<dynamic, dynamic>.from(item as Map)),
          )
          .toList();
    }
    return [];
  }

  static Future<void> saveSubjects(List<Subject> subjects) async {
    final list = subjects.map((s) => s.toMap()).toList();
    await _box.put('subjects', list);
  }

  static Future<void> addSubject(Subject subject) async {
    final current = getSubjects();
    current.add(subject);
    await saveSubjects(current);
  }

  static Future<void> deleteSubject(String id) async {
    final current = getSubjects();
    current.removeWhere((s) => s.id == id);
    await saveSubjects(current);
  }
}
