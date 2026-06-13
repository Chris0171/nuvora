import 'package:nuvora/features/tasks/data/datasources/task_datasource.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
	TaskRepositoryImpl({required TaskDataSource localDataSource})
			: dataSource = localDataSource;

	final TaskDataSource dataSource;

	@override
	Future<List<Task>> getTasks() async {
		return dataSource.getTasks();
	}

	@override
	Future<void> createTask(Task task) async {
		await dataSource.createTask(task);
	}

	@override
	Future<void> updateTask(Task task) async {
		await dataSource.updateTask(task);
	}

	@override
	Future<void> deleteTask(String taskId) async {
		await dataSource.deleteTask(taskId);
	}
}
