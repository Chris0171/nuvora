import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/tasks/application/controllers/task_controller.dart';
import 'package:nuvora/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:nuvora/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
	return TaskLocalDataSource();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
	return TaskRepositoryImpl(localDataSource: ref.read(taskLocalDataSourceProvider));
});

final taskControllerProvider = Provider<TaskController>((ref) {
	return TaskController(repository: ref.read(taskRepositoryProvider));
});

final tasksProvider = FutureProvider<List<Task>>((ref) async {
	return ref.read(taskControllerProvider).loadTasks();
});
