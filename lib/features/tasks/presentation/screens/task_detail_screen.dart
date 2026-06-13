import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class TaskDetailScreen extends ConsumerWidget {
	const TaskDetailScreen({
		super.key,
		required this.task,
	});

	final Task task;

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		return Scaffold(
			appBar: AppBar(title: const Text('Detalle de tarea')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(task.title, style: Theme.of(context).textTheme.titleLarge),
						const SizedBox(height: 8),
						Text(task.description ?? 'Sin descripcion'),
						const SizedBox(height: 16),
						SwitchListTile(
							title: const Text('Completada'),
							value: task.isCompleted,
							onChanged: (value) async {
								await ref.read(taskControllerProvider).markTaskAsCompleted(
									taskId: task.id,
									isCompleted: value,
								);
								ref.invalidate(tasksProvider);
								if (context.mounted) {
									Navigator.of(context).pop();
								}
							},
						),
					],
				),
			),
		);
	}
}
