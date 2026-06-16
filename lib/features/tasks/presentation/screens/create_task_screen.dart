import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
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
	bool _isSaving = false;

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

		final newTask = Task(
			id: DateTime.now().microsecondsSinceEpoch.toString(),
			title: _titleController.text.trim(),
			description: _descriptionController.text.trim().isEmpty
					? null
					: _descriptionController.text.trim(),
			createdAt: DateTime.now(),
			dueDate: null,
			isCompleted: false,
			priority: Priority.medium,
			categoryId: null,
			repeatType: RepeatType.none,
		);

		try {
			await ref.read(taskControllerProvider).createTask(newTask);
			ref.invalidate(tasksProvider);
			if (mounted) {
				Navigator.of(context).pop(true);
			}
		} catch (_) {
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Could not save task')),
				);
			}
		} finally {
			if (mounted) setState(() => _isSaving = false);
		}
	}

	@override
	Widget build(BuildContext context) {
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
								const SizedBox(height: AppSpacing.xxl),
								// Save Button
								SizedBox(
									width: double.infinity,
									height: 56,
									child: ElevatedButton(
										onPressed: _isSaving ? null : _saveTask,
										style: ElevatedButton.styleFrom(
											elevation: _isSaving ? 0 : AppElevation.sm,
										),
										child: _isSaving
												? const SizedBox(
													height: 24,
													width: 24,
													child: CircularProgressIndicator(
														strokeWidth: 2.5,
														valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
													),
												)
												: const Text(
													'Create Task',
													style: AppTypography.labelLarge,
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

