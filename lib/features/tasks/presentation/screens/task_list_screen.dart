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
							key: ValueKey(task.id),
							task: task,
							onToggleCompleted: (value) async {
								try {
									await ref.read(taskControllerProvider).markTaskAsCompleted(
										taskId: task.id,
										isCompleted: value,
									);
									ref.invalidate(tasksProvider);
								} catch (_) {
									if (context.mounted) {
										ScaffoldMessenger.of(context).showSnackBar(
											const SnackBar(
												content: Text('No se pudo actualizar la tarea.'),
											),
										);
									}
								}
							},
							onDelete: () async {
								try {
									await ref.read(taskControllerProvider).deleteTask(task.id);
									ref.invalidate(tasksProvider);
								} catch (_) {
									if (context.mounted) {
										ScaffoldMessenger.of(context).showSnackBar(
											const SnackBar(
												content: Text('No se pudo eliminar la tarea.'),
											),
										);
									}
								}
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
