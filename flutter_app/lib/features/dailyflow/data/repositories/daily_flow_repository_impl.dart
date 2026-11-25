import '../../domain/entities/daily_task_entity.dart';
import '../../domain/repositories/daily_flow_repository.dart';
import '../datasources/daily_flow_local_datasource.dart';
import '../models/daily_task_model.dart';

/// Repository implementation delegating DailyFlow task persistence to [DailyFlowLocalDataSource].
///
/// Ownership: DailyFlow Feature (Data Layer)
// ==========================================
// DAILYFLOW REPOSITORY - Implementation
// ==========================================
class DailyFlowRepositoryImpl implements DailyFlowRepository {
  final DailyFlowLocalDataSource localDataSource;

  DailyFlowRepositoryImpl({required this.localDataSource});

  @override
  Future<List<DailyTaskEntity>> getTasks() => localDataSource.getTasks();

  @override
  Stream<List<DailyTaskEntity>> watchTasks() => localDataSource.watchTasks();

  @override
  Future<DailyTaskEntity?> getTaskById(String id) =>
      localDataSource.getTaskById(id);

  @override
  Future<void> saveTask(DailyTaskEntity task) =>
      localDataSource.saveTask(DailyTaskModel.fromEntity(task));

  @override
  Future<void> saveTasks(List<DailyTaskEntity> tasks) =>
      localDataSource.saveTasks(tasks.map(DailyTaskModel.fromEntity).toList());

  @override
  Future<void> deleteTask(String id) => localDataSource.deleteTask(id);

  @override
  Future<void> clearAllTasks() => localDataSource.clearAllTasks();
}
