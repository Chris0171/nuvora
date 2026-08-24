import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';

class TaskController {
	TaskController({required this.repository});

	final TaskRepository repository;

	Future<List<Task>> loadTasks() async {
		return repository.getTasks();
	}

	Future<List<Task>> loadActiveTasks() async {
		return repository.getActiveTasks();
	}

	Future<List<Task>> loadArchivedTasks() async {
		return repository.getArchivedTasks();
	}

	Future<void> createTask(Task task) async {
		await repository.createTask(task);
	}

	Future<void> updateTask(Task task) async {
		await repository.updateTask(task);
	}

	Future<void> archiveTask(Task task) async {
		await repository.updateTask(
			task.copyWith(
				archived: true,
				deletedAt: task.deletedAt,
			),
		);
	}

	Future<void> unarchiveTask(Task task) async {
		await repository.updateTask(
			task.copyWith(
				archived: false,
				deletedAt: task.deletedAt,
			),
		);
	}

	Future<void> deleteTask(String taskId) async {
		await repository.deleteTask(taskId);
	}

	Future<void> markTaskAsCompleted({
		required String taskId,
		required bool isCompleted,
	}) async {
		await repository.updateTaskCompletion(
			taskId: taskId,
			isCompleted: isCompleted,
		);
	}
}
