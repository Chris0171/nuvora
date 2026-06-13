import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';

class TaskController {
	TaskController({required this.repository});

	final TaskRepository repository;

	Future<List<Task>> loadTasks() async {
		return repository.getTasks();
	}

	Future<void> createTask(Task task) async {
		await repository.createTask(task);
	}

	Future<void> updateTask(Task task) async {
		await repository.updateTask(task);
	}

	Future<void> deleteTask(String taskId) async {
		await repository.deleteTask(taskId);
	}

	Future<void> markTaskAsCompleted({
		required String taskId,
		required bool isCompleted,
	}) async {
		final List<Task> tasks = await repository.getTasks();
		final Task currentTask = tasks.firstWhere((Task task) => task.id == taskId);
		final Task updatedTask = currentTask.copyWith(isCompleted: isCompleted);
		await repository.updateTask(updatedTask);
	}
}
