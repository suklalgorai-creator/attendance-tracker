import 'package:hive_flutter/hive_flutter.dart';
import '../../models/subject.dart';

class DatabaseService {
  static const String boxName = 'subjects_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  static Box get _box => Hive.box(boxName);

  static List<Subject> getSubjects() {
    final rawData = _box.get('subjects', defaultValue: []);
    if (rawData is List) {
      return rawData
          .map((item) => Subject.fromMap(Map<dynamic, dynamic>.from(item as Map)))
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
