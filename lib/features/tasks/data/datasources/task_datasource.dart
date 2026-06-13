import 'package:nuvora/features/tasks/domain/entities/task.dart';

abstract class TaskDataSource {
  Future<List<Task>> getTasks();
  Future<void> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> updateTaskCompletion({
    required String taskId,
    required bool isCompleted,
  });
  Future<void> deleteTask(String taskId);
}