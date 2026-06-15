import 'package:nuvora/core/utils/app_logger.dart';
import 'package:nuvora/features/tasks/data/datasources/task_datasource.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

class TaskRepositoryImpl implements TaskRepository {
	TaskRepositoryImpl({required this.dataSource});

	final TaskDataSource dataSource;
	static const Uuid _uuid = Uuid();
	static final AppLogger _log = AppLogger('TaskRepository');

	@override
	Future<List<Task>> getTasks() async {
		return dataSource.getTasks();
	}

	@override
	Future<void> createTask(Task task) async {
		final DateTime now = DateTime.now();
		final bool replaceId = _shouldReplaceId(task.id);
		final String newId = replaceId ? _uuid.v4() : task.id;

		if (replaceId) {
			_log.debug('Replaced legacy id with UUID v4', newId);
		}

		final Task normalizedTask = task.copyWith(id: newId, updatedAt: now);
		await dataSource.createTask(normalizedTask);
		_log.debug('Task created', newId);
	}

	@override
	Future<void> updateTask(Task task) async {
		await dataSource.updateTask(task.copyWith(updatedAt: DateTime.now()));
		_log.debug('Task updated', task.id);
	}

	@override
	Future<void> updateTaskCompletion({
		required String taskId,
		required bool isCompleted,
	}) async {
		await dataSource.updateTaskCompletion(
			taskId: taskId,
			isCompleted: isCompleted,
		);
	}

	@override
	Future<void> deleteTask(String taskId) async {
		await dataSource.deleteTask(taskId);
		_log.debug('Task soft-deleted', taskId);
	}

	bool _shouldReplaceId(String id) {
		if (id.trim().isEmpty) {
			return true;
		}

		// Legacy IDs were generated from timestamps in the UI.
		return RegExp(r'^\d{10,}$').hasMatch(id);
	}
}
