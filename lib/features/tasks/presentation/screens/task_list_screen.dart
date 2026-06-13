import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/presentation/widgets/task_item.dart';

class TaskListScreen extends ConsumerWidget {
	const TaskListScreen({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final tasksAsync = ref.watch(tasksProvider);

		return tasksAsync.when(
			data: (tasks) {
				if (tasks.isEmpty) {
					return const Center(child: Text('No hay tareas todavia.'));
				}

				return ListView.builder(
					itemCount: tasks.length,
					itemBuilder: (context, index) {
						final task = tasks[index];
						return TaskItem(
							task: task,
							onToggleCompleted: (value) async {
								await ref.read(taskControllerProvider).markTaskAsCompleted(
									taskId: task.id,
									isCompleted: value,
								);
								ref.invalidate(tasksProvider);
							},
							onDelete: () async {
								await ref.read(taskControllerProvider).deleteTask(task.id);
								ref.invalidate(tasksProvider);
							},
						);
					},
				);
			},
			loading: () => const Center(child: CircularProgressIndicator()),
			error: (error, _) => Center(child: Text('Error: $error')),
		);
	}
}
