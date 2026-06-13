import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/tasks/application/controllers/task_controller.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

final taskControllerProvider = Provider<TaskController>((ref) {
	return const TaskController();
});

final tasksProvider = FutureProvider<List<Task>>((ref) async {
	return ref.read(taskControllerProvider).loadTasks();
});
