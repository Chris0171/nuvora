import 'package:flutter/material.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class TaskItem extends StatelessWidget {
	const TaskItem({
		super.key,
		required this.task,
		this.onTap,
	});

	final Task task;
	final VoidCallback? onTap;

	@override
	Widget build(BuildContext context) {
		return ListTile(
			title: Text(task.title),
			subtitle: task.description == null ? null : Text(task.description!),
			onTap: onTap,
		);
	}
}
