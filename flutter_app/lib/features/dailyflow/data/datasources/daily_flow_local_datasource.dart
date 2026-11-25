import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/database_service.dart';
import '../models/daily_task_model.dart';

abstract class DailyFlowLocalDataSource {
  Future<List<DailyTaskModel>> getTasks();
  Stream<List<DailyTaskModel>> watchTasks();
  Future<DailyTaskModel?> getTaskById(String id);
  Future<void> saveTask(DailyTaskModel task);
  Future<void> saveTasks(List<DailyTaskModel> tasks);
  Future<void> deleteTask(String id);
  Future<void> clearAllTasks();
}

class DailyFlowLocalDataSourceImpl implements DailyFlowLocalDataSource {
  final Box _box;

  DailyFlowLocalDataSourceImpl({Box? box})
    : _box =
          box ?? DatabaseService.getBox(DatabaseService.dailyFlowTasksBoxName);

  @override
  Future<List<DailyTaskModel>> getTasks() async {
    try {
      final rawData = _box.get('items', defaultValue: []);
      if (rawData is List) {
        return rawData
            .whereType<Map>()
            .map(
              (item) =>
                  DailyTaskModel.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw CacheException('Failed to load DailyFlow tasks: $e');
    }
  }

  @override
  Stream<List<DailyTaskModel>> watchTasks() async* {
    yield await getTasks();
    yield* _box.watch(key: 'items').asyncMap((_) => getTasks());
  }

  @override
  Future<DailyTaskModel?> getTaskById(String id) async {
    try {
      final current = await getTasks();
      for (final task in current) {
        if (task.id == id) return task;
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to load DailyFlow task by id: $e');
    }
  }

  @override
  Future<void> saveTasks(List<DailyTaskModel> tasks) async {
    try {
      final list = tasks.map((t) => t.toMap()).toList();
      await _box.put('items', list);
    } catch (e) {
      throw CacheException('Failed to save DailyFlow tasks: $e');
    }
  }

  @override
  Future<void> saveTask(DailyTaskModel task) async {
    try {
      final current = await getTasks();
      final index = current.indexWhere((t) => t.id == task.id);
      if (index >= 0) {
        current[index] = task;
      } else {
        current.add(task);
      }
      await saveTasks(current);
    } catch (e) {
      throw CacheException('Failed to save DailyFlow task: $e');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      final current = await getTasks();
      current.removeWhere((t) => t.id == id);
      await saveTasks(current);
    } catch (e) {
      throw CacheException('Failed to delete DailyFlow task: $e');
    }
  }

  @override
  Future<void> clearAllTasks() async {
    try {
      await _box.put('items', []);
    } catch (e) {
      throw CacheException('Failed to clear DailyFlow tasks: $e');
    }
  }
}
