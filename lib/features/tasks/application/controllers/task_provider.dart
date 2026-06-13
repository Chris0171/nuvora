import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/tasks/application/controllers/task_controller.dart';
import 'package:nuvora/features/tasks/data/datasources/sqlite_task_datasource.dart';
import 'package:nuvora/features/tasks/data/datasources/task_datasource.dart';
import 'package:nuvora/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';

final taskDataSourceProvider = Provider<TaskDataSource>((ref) {
	return SQLiteTaskDataSource();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
	return TaskRepositoryImpl(dataSource: ref.read(taskDataSourceProvider));
});

final taskControllerProvider = Provider<TaskController>((ref) {
	return TaskController(repository: ref.read(taskRepositoryProvider));
});

final tasksProvider = FutureProvider<List<Task>>((ref) async {
	return ref.read(taskControllerProvider).loadTasks();
});
