import 'package:flutter/material.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class TaskItem extends StatelessWidget {
	const TaskItem({
		super.key,
		required this.task,
		this.onTap,
		this.onDelete,
		this.onToggleCompleted,
	});

	final Task task;
	final VoidCallback? onTap;
	final VoidCallback? onDelete;
	final ValueChanged<bool>? onToggleCompleted;

	@override
	Widget build(BuildContext context) {
		return ListTile(
			leading: Checkbox(
				value: task.isCompleted,
				onChanged: (value) {
					if (value == null) {
						return;
					}
					onToggleCompleted?.call(value);
				},
			),
			title: Text(task.title),
			subtitle: task.description == null ? null : Text(task.description!),
			trailing: IconButton(
				onPressed: onDelete,
				icon: const Icon(Icons.delete_outline),
			),
			onTap: onTap,
		);
	}
}
