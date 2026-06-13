import 'package:nuvora/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
	TaskRepositoryImpl({required this.localDataSource});

	final TaskLocalDataSource localDataSource;

	@override
	Future<List<Task>> getTasks() async {
		return localDataSource.getTasks();
	}

	@override
	Future<void> createTask(Task task) async {
		await localDataSource.createTask(task);
	}

	@override
	Future<void> updateTask(Task task) async {
		await localDataSource.updateTask(task);
	}

	@override
	Future<void> deleteTask(String taskId) async {
		await localDataSource.deleteTask(taskId);
	}
}
