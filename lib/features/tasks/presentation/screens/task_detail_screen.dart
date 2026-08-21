import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_feedback.dart';
import 'package:nuvora/features/tasks/application/controllers/category_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';
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
	RepeatType _selectedRepeatType = RepeatType.none;
	String? _selectedCategoryId;
	DateTime? _selectedDueDate;
	bool _isEditing = false;
	bool _isSaving = false;

	@override
	void initState() {
		super.initState();
		_task = widget.task;
		_titleController = TextEditingController(text: _task.title);
		_descriptionController = TextEditingController(text: _task.description ?? '');
		_selectedPriority = _task.priority;
		_selectedRepeatType = _task.repeatType;
		_selectedCategoryId = _task.categoryId;
		_selectedDueDate = _task.dueDate;
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
			_selectedRepeatType = _task.repeatType;
			_selectedCategoryId = _task.categoryId;
			_selectedDueDate = _task.dueDate;
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

	String _repeatLabel(RepeatType repeatType) {
		switch (repeatType) {
			case RepeatType.none:
				return 'No repeat';
			case RepeatType.daily:
				return 'Daily';
			case RepeatType.weekly:
				return 'Weekly';
			case RepeatType.monthly:
				return 'Monthly';
		}
	}

	String _formatDate(DateTime value) {
		final month = value.month.toString().padLeft(2, '0');
		final day = value.day.toString().padLeft(2, '0');
		final hour = value.hour.toString().padLeft(2, '0');
		final minute = value.minute.toString().padLeft(2, '0');
		return '${value.year}-$month-$day $hour:$minute';
	}

	String _formatDueDate(DateTime value) {
		const months = <String>[
			'Jan',
			'Feb',
			'Mar',
			'Apr',
			'May',
			'Jun',
			'Jul',
			'Aug',
			'Sep',
			'Oct',
			'Nov',
			'Dec',
		];
		return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
	}

	Future<void> _pickDueDate() async {
		final now = DateTime.now();
		final initialDate = _selectedDueDate ?? DateTime(now.year, now.month, now.day);
		final selected = await showDatePicker(
			context: context,
			initialDate: initialDate,
			firstDate: DateTime(now.year - 10),
			lastDate: DateTime(now.year + 20),
			helpText: 'Select due date',
		);

		if (selected == null || !mounted) {
			return;
		}

		setState(() {
			_selectedDueDate = DateTime(selected.year, selected.month, selected.day);
		});
	}

	void _clearDueDate() {
		setState(() {
			_selectedDueDate = null;
		});
	}

	String _categoryLabel(List<Category> categories, String? categoryId) {
		if (categoryId == null) {
			return 'No category';
		}

		for (final category in categories) {
			if (category.id == categoryId) {
				return category.name;
			}
		}

		return 'No category';
	}

	Future<Category?> _showCreateCategoryDialog() async {
		final controller = TextEditingController();
		String? errorText;

		final Category? result = await showDialog<Category>(
			context: context,
			builder: (context) {
				return StatefulBuilder(
					builder: (context, setDialogState) {
						return AlertDialog(
							title: const Text('Create category'),
							content: TextField(
								controller: controller,
								autofocus: true,
								decoration: InputDecoration(
									hintText: 'Category name',
									errorText: errorText,
								),
							),
							actions: [
								TextButton(
									onPressed: () => Navigator.of(context).pop(),
									child: const Text('Cancel'),
								),
								ElevatedButton(
									onPressed: () {
										final name = controller.text.trim();
										if (name.isEmpty) {
											setDialogState(() {
												errorText = 'Category name is required';
											});
											return;
										}
										Navigator.of(context).pop(
											Category(id: '', name: name),
										);
									},
									child: const Text('Create'),
								),
							],
						);
					},
				);
			},
		);

		controller.dispose();
		return result;
	}

	Future<void> _openCategorySelector() async {
		final categories = await ref.read(categoriesProvider.future);
		if (!mounted) return;

		final selectedCategoryId = await showModalBottomSheet<String?>(
			context: context,
			showDragHandle: true,
			builder: (context) {
				return SafeArea(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							ListTile(
								title: const Text('No category'),
								leading: _selectedCategoryId == null
									? const Icon(Icons.check_circle, color: AppColors.primary)
									: const Icon(Icons.circle_outlined),
								onTap: () => Navigator.of(context).pop('__none__'),
							),
							...categories.map(
								(category) => ListTile(
									title: Text(category.name),
									leading: _selectedCategoryId == category.id
										? const Icon(Icons.check_circle, color: AppColors.primary)
										: const Icon(Icons.circle_outlined),
									onTap: () => Navigator.of(context).pop(category.id),
								),
							),
							ListTile(
								leading: const Icon(Icons.add),
								title: const Text('Create category'),
								onTap: () => Navigator.of(context).pop('__create__'),
							),
						],
					),
				);
			},
		);

		if (!mounted || selectedCategoryId == null) {
			return;
		}

		if (selectedCategoryId == '__none__') {
			setState(() {
				_selectedCategoryId = null;
			});
			return;
		}

		if (selectedCategoryId == '__create__') {
			final newCategory = await _showCreateCategoryDialog();
			if (newCategory == null) return;
			try {
				await ref.read(categoryControllerProvider).createCategory(newCategory);
				ref.invalidate(categoriesProvider);
				final refreshed = await ref.read(categoriesProvider.future);
				if (!mounted) return;
				final Category created = refreshed.firstWhere(
					(category) =>
						category.name.toLowerCase() == newCategory.name.toLowerCase(),
				);
				setState(() {
					_selectedCategoryId = created.id;
				});
			} catch (_) {
				if (mounted) {
					AppFeedback.showSnackBar(context, 'Could not create category');
				}
			}
			return;
		}

		setState(() {
			_selectedCategoryId = selectedCategoryId;
		});
	}

	String _dueDateLabel(DateTime? dueDate) {
		if (dueDate == null) {
			return 'No due date';
		}

		final now = DateTime.now();
		final today = DateTime(now.year, now.month, now.day);
		final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

		if (due == today) {
			return 'Today';
		}

		return _formatDueDate(dueDate);
	}

	bool _isOverdue(DateTime? dueDate) {
		if (dueDate == null || _task.isCompleted) {
			return false;
		}

		final now = DateTime.now();
		final today = DateTime(now.year, now.month, now.day);
		final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
		return due.isBefore(today);
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

		final Task updatedTask = Task(
			id: _task.id,
			title: _titleController.text.trim(),
			description: _descriptionController.text.trim().isEmpty
				? null
				: _descriptionController.text.trim(),
			createdAt: _task.createdAt,
			updatedAt: _task.updatedAt,
			dueDate: _selectedDueDate,
			isCompleted: _task.isCompleted,
			priority: _selectedPriority,
			categoryId: _selectedCategoryId,
			repeatType: _selectedRepeatType,
			archived: _task.archived,
			deletedAt: _task.deletedAt,
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
		final categoriesAsync = ref.watch(categoriesProvider);
		final categories = categoriesAsync.maybeWhen(
			data: (items) => items,
			orElse: () => const <Category>[],
		);
		final detailCategoryLabel = _categoryLabel(categories, _task.categoryId);
		final overdue = _isOverdue(_task.dueDate);
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
						const SizedBox(height: AppSpacing.lg),
						Text('Repeat', style: AppTypography.labelLarge),
						const SizedBox(height: AppSpacing.sm),
						DropdownButtonFormField<RepeatType>(
							key: const ValueKey('task-edit-repeat-field'),
							initialValue: _selectedRepeatType,
							items: RepeatType.values
								.map(
									(repeatType) => DropdownMenuItem<RepeatType>(
										value: repeatType,
										child: Text(_repeatLabel(repeatType)),
									),
								)
								.toList(growable: false),
							onChanged: (value) {
								if (value == null) return;
								setState(() {
									_selectedRepeatType = value;
								});
							},
						),
						const SizedBox(height: AppSpacing.lg),
						Text('Category', style: AppTypography.labelLarge),
						const SizedBox(height: AppSpacing.sm),
						InkWell(
							key: const ValueKey('task-edit-category-selector'),
							onTap: _openCategorySelector,
							borderRadius: BorderRadius.circular(AppRadius.lg),
							child: Container(
								padding: const EdgeInsets.all(AppSpacing.md),
								decoration: BoxDecoration(
									color: AppColors.surface,
									border: Border.all(color: AppColors.border),
									borderRadius: BorderRadius.circular(AppRadius.lg),
								),
								child: Row(
									children: [
										Expanded(
											child: Text(
												_categoryLabel(categories, _selectedCategoryId),
												key: const ValueKey('task-edit-category-label'),
												style: AppTypography.bodyMedium.copyWith(
													color: _selectedCategoryId == null
														? AppColors.textSecondary
														: AppColors.textPrimary,
												),
											),
										),
										const Icon(Icons.keyboard_arrow_down),
									],
								),
							),
						),
						const SizedBox(height: AppSpacing.lg),
						Text('Due date', style: AppTypography.labelLarge),
						const SizedBox(height: AppSpacing.sm),
						Container(
							padding: const EdgeInsets.all(AppSpacing.md),
							decoration: BoxDecoration(
								color: AppColors.surface,
								border: Border.all(color: AppColors.border),
								borderRadius: BorderRadius.circular(AppRadius.lg),
							),
							child: Row(
								children: [
									Expanded(
										child: Text(
											_dueDateLabel(_selectedDueDate),
											key: const ValueKey('task-edit-due-date-label'),
											style: AppTypography.bodyMedium.copyWith(
												color: _selectedDueDate == null
													? AppColors.textSecondary
													: AppColors.textPrimary,
											),
										),
									),
									TextButton.icon(
										key: const ValueKey('task-edit-select-date-button'),
										onPressed: _pickDueDate,
										icon: const Icon(Icons.calendar_today_outlined),
										label: Text(_selectedDueDate == null ? 'Select date' : 'Change'),
									),
									if (_selectedDueDate != null)
										IconButton(
											key: const ValueKey('task-edit-clear-date-button'),
											onPressed: _clearDueDate,
											icon: const Icon(Icons.close),
											tooltip: 'Remove due date',
										),
								],
							),
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
								Text('Repeat', style: AppTypography.labelMedium),
								const SizedBox(height: AppSpacing.xs),
								Text(
									_repeatLabel(_task.repeatType),
									key: const ValueKey('task-detail-repeat-label'),
									style: AppTypography.bodyMedium.copyWith(
										color: _task.repeatType == RepeatType.none
											? AppColors.textSecondary
											: AppColors.textPrimary,
									),
								),
								const SizedBox(height: AppSpacing.sm),
								Text('Category', style: AppTypography.labelMedium),
								const SizedBox(height: AppSpacing.xs),
								Text(
									detailCategoryLabel,
									key: const ValueKey('task-detail-category-label'),
									style: AppTypography.bodyMedium.copyWith(
										color: detailCategoryLabel == 'No category'
											? AppColors.textSecondary
											: AppColors.textPrimary,
									),
								),
								const SizedBox(height: AppSpacing.sm),
								Text('Due date', style: AppTypography.labelMedium),
								const SizedBox(height: AppSpacing.xs),
								Row(
									children: [
										Text(
											_dueDateLabel(_task.dueDate),
											key: const ValueKey('task-detail-due-date-label'),
											style: AppTypography.bodyMedium.copyWith(
												color: overdue ? AppColors.danger : AppColors.textPrimary,
											),
										),
										if (overdue) ...[
											const SizedBox(width: AppSpacing.sm),
											Container(
												padding: const EdgeInsets.symmetric(
													horizontal: AppSpacing.sm,
													vertical: AppSpacing.xs,
												),
												decoration: BoxDecoration(
													color: AppColors.danger.withValues(alpha: 0.12),
													borderRadius: BorderRadius.circular(AppRadius.full),
												),
												child: Text(
													'Overdue',
													style: AppTypography.labelSmall.copyWith(color: AppColors.danger),
												),
											),
										],
									],
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
