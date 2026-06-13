import 'package:nuvora/features/tasks/domain/entities/task.dart';

class TaskLocalDataSource {
	final List<Task> _tasks = <Task>[];

	Future<List<Task>> getTasks() async {
		return List<Task>.unmodifiable(_tasks);
	}

	Future<void> createTask(Task task) async {
		_tasks.add(task);
	}

	Future<void> updateTask(Task task) async {
		final int index = _tasks.indexWhere((Task item) => item.id == task.id);
		if (index == -1) {
			throw StateError('Task not found for update: ${task.id}');
		}

		_tasks[index] = task;
	}

	Future<void> deleteTask(String taskId) async {
		_tasks.removeWhere((Task task) => task.id == taskId);
	}
}
