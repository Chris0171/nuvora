import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

class TaskController {
	TaskController({required this.repository});

	final TaskRepository repository;
	static const Uuid _uuid = Uuid();

	Future<List<Task>> loadTasks() async {
		return repository.getTasks();
	}

	Future<void> createTask(Task task) async {
		final String normalizedId = _shouldReplaceId(task.id) ? _uuid.v4() : task.id;
		final DateTime now = DateTime.now();

		await repository.createTask(
			task.copyWith(
				id: normalizedId,
				updatedAt: now,
			),
		);
	}

	Future<void> updateTask(Task task) async {
		await repository.updateTask(task.copyWith(updatedAt: DateTime.now()));
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

	bool _shouldReplaceId(String id) {
		if (id.trim().isEmpty) {
			return true;
		}

		// Legacy IDs were generated from timestamps in the UI.
		return RegExp(r'^\d{10,}$').hasMatch(id);
	}
}
