import 'package:nuvora/features/tasks/domain/entities/task.dart';

abstract class TaskLocalDataSource {
	Future<List<Task>> getTasks();
	Future<void> createTask(Task task);
	Future<void> updateTask(Task task);
	Future<void> deleteTask(String taskId);
}
