import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_feedback.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
import 'package:nuvora/features/tasks/application/controllers/category_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
	const CreateTaskScreen({super.key});

	@override
	ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
	final _formKey = GlobalKey<FormState>();
	final _titleController = TextEditingController();
	final _descriptionController = TextEditingController();
	String? _selectedCategoryId;
	DateTime? _selectedDueDate;
	RepeatType _selectedRepeatType = RepeatType.none;
	bool _isSaving = false;

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

	String _categoryLabel(List<Category> categories) {
		if (_selectedCategoryId == null) {
			return 'No category';
		}

		for (final category in categories) {
			if (category.id == _selectedCategoryId) {
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

	String _formatDueDate(DateTime date) {
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
		return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
	}

	@override
	void dispose() {
		_titleController.dispose();
		_descriptionController.dispose();
		super.dispose();
	}

	Future<void> _saveTask() async {
		if (!_formKey.currentState!.validate() || _isSaving) {
			return;
		}

		setState(() => _isSaving = true);
		HapticFeedback.lightImpact();

		final newTask = Task(
			id: DateTime.now().microsecondsSinceEpoch.toString(),
			title: _titleController.text.trim(),
			description: _descriptionController.text.trim().isEmpty
					? null
					: _descriptionController.text.trim(),
			createdAt: DateTime.now(),
			dueDate: _selectedDueDate,
			isCompleted: false,
			priority: Priority.medium,
			categoryId: _selectedCategoryId,
			repeatType: _selectedRepeatType,
		);

		try {
			await ref.read(taskControllerProvider).createTask(newTask);
			ref.invalidate(tasksProvider);
			if (mounted) {
				Navigator.of(context).pop(true);
			}
		} catch (_) {
			if (mounted) {
				AppFeedback.showSnackBar(context, 'Could not save task');
			}
		} finally {
			if (mounted) setState(() => _isSaving = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final categoriesAsync = ref.watch(categoriesProvider);
		final categories = categoriesAsync.maybeWhen(
			data: (items) => items,
			orElse: () => const <Category>[],
		);

		return Scaffold(
			appBar: AppBar(
				title: const Text('New Task'),
				titleTextStyle: AppTypography.headlineLarge,
			),
			body: SingleChildScrollView(
				child: Padding(
					padding: const EdgeInsets.all(AppSpacing.lg),
					child: Form(
						key: _formKey,
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								// Title Field
								Text(
									'Title',
									style: AppTypography.labelLarge.copyWith(
										color: AppColors.textPrimary,
									),
								),
								const SizedBox(height: AppSpacing.md),
								TextFormField(
									controller: _titleController,
									decoration: InputDecoration(
										hintText: 'Enter task title',
										prefixIcon: const Icon(Icons.title, color: AppColors.primary),
									),
									style: AppTypography.bodyMedium,
									validator: (value) {
										if (value == null || value.trim().isEmpty) {
											return 'Title is required';
										}
										return null;
									},
								),
								const SizedBox(height: AppSpacing.xl),
								// Description Field
								Text(
									'Description',
									style: AppTypography.labelLarge.copyWith(
										color: AppColors.textPrimary,
									),
								),
								const SizedBox(height: AppSpacing.md),
								TextFormField(
									controller: _descriptionController,
									decoration: InputDecoration(
										hintText: 'Add task details',
										prefixIcon: const Icon(Icons.description, color: AppColors.primary),
									),
									style: AppTypography.bodyMedium,
									minLines: 3,
									maxLines: 5,
								),
								const SizedBox(height: AppSpacing.xl),
								Text(
									'Repeat',
									style: AppTypography.labelLarge.copyWith(
										color: AppColors.textPrimary,
									),
								),
								const SizedBox(height: AppSpacing.md),
								DropdownButtonFormField<RepeatType>(
									key: const ValueKey('create-task-repeat-field'),
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
								const SizedBox(height: AppSpacing.xl),
								Text(
									'Category',
									style: AppTypography.labelLarge.copyWith(
										color: AppColors.textPrimary,
									),
								),
								const SizedBox(height: AppSpacing.md),
								InkWell(
									key: const ValueKey('create-task-category-selector'),
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
														_categoryLabel(categories),
														key: const ValueKey('create-task-category-label'),
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
								const SizedBox(height: AppSpacing.xl),
								Text(
									'Due date',
									style: AppTypography.labelLarge.copyWith(
										color: AppColors.textPrimary,
									),
								),
								const SizedBox(height: AppSpacing.md),
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
													_selectedDueDate == null
														? 'No due date'
														: _formatDueDate(_selectedDueDate!),
													key: const ValueKey('create-task-due-date-label'),
													style: AppTypography.bodyMedium.copyWith(
														color: _selectedDueDate == null
															? AppColors.textSecondary
															: AppColors.textPrimary,
													),
												),
											),
											TextButton.icon(
												key: const ValueKey('create-task-select-date-button'),
												onPressed: _pickDueDate,
												icon: const Icon(Icons.calendar_today_outlined),
												label: Text(_selectedDueDate == null ? 'Select date' : 'Change'),
											),
											if (_selectedDueDate != null)
												IconButton(
													key: const ValueKey('create-task-clear-date-button'),
													onPressed: _clearDueDate,
													icon: const Icon(Icons.close),
													tooltip: 'Remove due date',
												),
										],
									),
								),
								const SizedBox(height: AppSpacing.xxl),
								// Save Button
								SizedBox(
									width: double.infinity,
									height: 56,
									child: ElevatedButton(
										onPressed: _isSaving ? null : _saveTask,
										style: ElevatedButton.styleFrom(
											elevation: _isSaving ? 0 : AppElevation.sm,
											disabledBackgroundColor: AppColors.disabledBackground,
											disabledForegroundColor: AppColors.textTertiary,
										),
										child: AnimatedSwitcher(
											duration: AppMotion.shortDuration,
											switchInCurve: AppMotion.curve,
											switchOutCurve: AppMotion.curve,
											child: _isSaving
													? const SizedBox(
														key: ValueKey('task-saving'),
														height: 24,
														width: 24,
														child: CircularProgressIndicator(
															strokeWidth: 2.5,
															valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
														),
													)
													: const Text(
														key: ValueKey('task-create-label'),
														'Create Task',
														style: AppTypography.labelLarge,
													),
										),
									),
								),
							],
						),
					),
				),
			),
		);
	}
}

