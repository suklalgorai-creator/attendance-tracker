import '../entities/daily_task_entity.dart';

/// Repository contract for DailyFlow task persistence and reactive streams.
abstract class DailyFlowRepository {
  Future<List<DailyTaskEntity>> getTasks();
  Stream<List<DailyTaskEntity>> watchTasks();
  Future<DailyTaskEntity?> getTaskById(String id);
  Future<void> saveTask(DailyTaskEntity task);
  Future<void> saveTasks(List<DailyTaskEntity> tasks);
  Future<void> deleteTask(String id);
  Future<void> clearAllTasks();
}
