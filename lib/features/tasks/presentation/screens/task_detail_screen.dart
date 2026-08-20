import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_feedback.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
	const TaskDetailScreen({
		super.key,
		required this.task,
	});

	final Task task;

	@override
	ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
	late final TextEditingController _titleController;
	late final TextEditingController _descriptionController;
	late Task _task;
	late Priority _selectedPriority;
	bool _isEditing = false;
	bool _isSaving = false;

	@override
	void initState() {
		super.initState();
		_task = widget.task;
		_titleController = TextEditingController(text: _task.title);
		_descriptionController = TextEditingController(text: _task.description ?? '');
		_selectedPriority = _task.priority;
	}

	@override
	void dispose() {
		_titleController.dispose();
		_descriptionController.dispose();
		super.dispose();
	}

	void _startEditing() {
		setState(() {
			_titleController.text = _task.title;
			_descriptionController.text = _task.description ?? '';
			_selectedPriority = _normalizeEditablePriority(_task.priority);
			_isEditing = true;
		});
	}

	void _cancelEditing() {
		setState(() {
			_isEditing = false;
		});
	}

	Priority _normalizeEditablePriority(Priority priority) {
		switch (priority) {
			case Priority.high:
			case Priority.medium:
			case Priority.low:
				return priority;
			case Priority.urgent:
				return Priority.high;
		}
	}

	String _priorityLabel(Priority priority) {
		switch (priority) {
			case Priority.high:
				return 'High';
			case Priority.medium:
				return 'Medium';
			case Priority.low:
				return 'Low';
			case Priority.urgent:
				return 'Urgent';
		}
	}

	String _formatDate(DateTime value) {
		final month = value.month.toString().padLeft(2, '0');
		final day = value.day.toString().padLeft(2, '0');
		final hour = value.hour.toString().padLeft(2, '0');
		final minute = value.minute.toString().padLeft(2, '0');
		return '${value.year}-$month-$day $hour:$minute';
	}

	Future<void> _toggleCompleted(bool value) async {
		try {
			await ref.read(taskControllerProvider).markTaskAsCompleted(
				taskId: _task.id,
				isCompleted: value,
			);
			ref.invalidate(tasksProvider);
			if (!mounted) return;
			setState(() {
				_task = _task.copyWith(
					isCompleted: value,
					updatedAt: DateTime.now(),
				);
			});
		} catch (_) {
			if (mounted) {
				AppFeedback.showSnackBar(context, 'Could not update task');
			}
		}
	}

	Future<void> _saveChanges() async {
		if (!_formKey.currentState!.validate() || _isSaving) {
			return;
		}

		setState(() => _isSaving = true);

		final Task updatedTask = _task.copyWith(
			title: _titleController.text.trim(),
			description: _descriptionController.text.trim().isEmpty
				? null
				: _descriptionController.text.trim(),
			priority: _selectedPriority,
		);

		try {
			await ref.read(taskControllerProvider).updateTask(updatedTask);
			ref.invalidate(tasksProvider);
			if (!mounted) return;
			setState(() {
				_task = updatedTask;
				_isEditing = false;
			});
			AppFeedback.showSnackBar(context, 'Task updated');
		} catch (_) {
			if (mounted) {
				AppFeedback.showSnackBar(context, 'Could not update task');
			}
		} finally {
			if (mounted) {
				setState(() => _isSaving = false);
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		final Widget bodyContent = _isEditing
			? Form(
				key: _formKey,
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text('Title', style: AppTypography.labelLarge),
						const SizedBox(height: AppSpacing.sm),
						TextFormField(
							key: const ValueKey('task-edit-title-field'),
							controller: _titleController,
							decoration: const InputDecoration(hintText: 'Enter task title'),
							validator: (value) {
								if (value == null || value.trim().isEmpty) {
									return 'Title is required';
								}
								return null;
							},
						),
						const SizedBox(height: AppSpacing.lg),
						Text('Description', style: AppTypography.labelLarge),
						const SizedBox(height: AppSpacing.sm),
						TextFormField(
							key: const ValueKey('task-edit-description-field'),
							controller: _descriptionController,
							minLines: 3,
							maxLines: 5,
							decoration: const InputDecoration(hintText: 'Add task details'),
						),
						const SizedBox(height: AppSpacing.lg),
						Text('Priority', style: AppTypography.labelLarge),
						const SizedBox(height: AppSpacing.sm),
						DropdownButtonFormField<Priority>(
							key: const ValueKey('task-edit-priority-field'),
							initialValue: _selectedPriority,
							items: const [Priority.high, Priority.medium, Priority.low]
								.map(
									(priority) => DropdownMenuItem<Priority>(
										value: priority,
										child: Text(
											priority == Priority.high
												? 'High'
												: priority == Priority.medium
													? 'Medium'
													: 'Low',
										),
									),
								)
								.toList(growable: false),
							onChanged: (priority) {
								if (priority == null) return;
								setState(() => _selectedPriority = priority);
							},
						),
						const SizedBox(height: AppSpacing.xl),
						Row(
							children: [
								Expanded(
									child: OutlinedButton(
										onPressed: _isSaving ? null : _cancelEditing,
										child: const Text('Cancel'),
									),
								),
								const SizedBox(width: AppSpacing.md),
								Expanded(
									child: ElevatedButton(
										onPressed: _isSaving ? null : _saveChanges,
										child: _isSaving
											? const SizedBox(
												height: 18,
												width: 18,
												child: CircularProgressIndicator(strokeWidth: 2),
											)
											: const Text('Save changes'),
									),
								),
							],
						),
					],
				),
			)
			: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(_task.title, style: AppTypography.displaySmall),
					const SizedBox(height: AppSpacing.sm),
					Text(
						_task.description ?? 'No description',
						style: AppTypography.bodyMedium.copyWith(
							color: AppColors.textSecondary,
						),
					),
					const SizedBox(height: AppSpacing.lg),
					Container(
						padding: const EdgeInsets.all(AppSpacing.lg),
						decoration: BoxDecoration(
							color: AppColors.surface,
							borderRadius: BorderRadius.circular(AppRadius.lg),
							border: Border.all(color: AppColors.border),
						),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Priority: ${_priorityLabel(_task.priority)}',
									style: AppTypography.bodyMedium,
								),
								const SizedBox(height: AppSpacing.sm),
								Text(
									'Created: ${_formatDate(_task.createdAt)}',
									style: AppTypography.bodySmall,
								),
								const SizedBox(height: AppSpacing.xs),
								Text(
									'Updated: ${_formatDate(_task.updatedAt)}',
									style: AppTypography.bodySmall,
								),
							],
						),
					),
					const SizedBox(height: AppSpacing.md),
					SwitchListTile(
						contentPadding: EdgeInsets.zero,
						title: const Text('Completed'),
						value: _task.isCompleted,
						onChanged: _toggleCompleted,
					),
				],
			);

		return Scaffold(
			appBar: AppBar(
				title: Text(_isEditing ? 'Edit Task' : 'Task Detail'),
				actions: [
					if (!_isEditing)
						TextButton.icon(
							onPressed: _startEditing,
							icon: const Icon(Icons.edit_outlined),
							label: const Text('Edit'),
						),
				],
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.all(AppSpacing.lg),
				child: bodyContent,
			),
		);
	}
}
