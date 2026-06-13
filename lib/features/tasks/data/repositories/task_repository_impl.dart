import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
	@override
	Future<List<Task>> getTasks() async {
		throw UnimplementedError();
	}

	@override
	Future<void> createTask(Task task) async {
		throw UnimplementedError();
	}

	@override
	Future<void> updateTask(Task task) async {
		throw UnimplementedError();
	}

	@override
	Future<void> deleteTask(String taskId) async {
		throw UnimplementedError();
	}
}
