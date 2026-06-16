import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
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
					return Padding(
						padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								const SizedBox(height: 60),
								Container(
									width: 80,
									height: 80,
									decoration: BoxDecoration(
										color: AppColors.primaryLight,
										borderRadius: BorderRadius.circular(AppRadius.xl),
									),
									child: const Icon(
										Icons.check_circle_outline,
										size: 40,
										color: AppColors.primary,
									),
								),
								const SizedBox(height: AppSpacing.lg),
								const Text(
									'No tasks yet',
									style: AppTypography.headlineMedium,
									textAlign: TextAlign.center,
								),
								const SizedBox(height: AppSpacing.md),
								Text(
									'Create your first task to get started',
									style: AppTypography.bodyMedium.copyWith(
										color: AppColors.textSecondary,
									),
									textAlign: TextAlign.center,
								),
								const SizedBox(height: 60),
							],
						),
					);
				}

				return ListView.builder(
					padding: const EdgeInsets.symmetric(
						horizontal: AppSpacing.lg,
						vertical: AppSpacing.md,
					),
					shrinkWrap: true,
					physics: const NeverScrollableScrollPhysics(),
					itemCount: tasks.length,
					itemBuilder: (context, index) {
						final task = tasks[index];
						return Padding(
							padding: const EdgeInsets.only(bottom: AppSpacing.md),
							child: TaskItem(
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
													content: Text('Could not update task'),
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
													content: Text('Could not delete task'),
												),
											);
										}
									}
								},
							),
						);
					},
				);
			},
			loading: () => Center(
				child: Padding(
					padding: const EdgeInsets.all(AppSpacing.lg),
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							const CircularProgressIndicator(
								color: AppColors.primary,
							),
							const SizedBox(height: AppSpacing.lg),
							Text(
								'Loading tasks...',
								style: AppTypography.bodyMedium.copyWith(
									color: AppColors.textSecondary,
								),
							),
						],
					),
				),
			),
			error: (error, _) => Center(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							const Icon(
								Icons.error_outline,
								size: 48,
								color: AppColors.danger,
							),
							const SizedBox(height: AppSpacing.lg),
							Text(
								'Error loading tasks',
								style: AppTypography.headlineMedium,
								textAlign: TextAlign.center,
							),
							const SizedBox(height: AppSpacing.md),
							Text(
								error.toString(),
								style: AppTypography.bodySmall,
								textAlign: TextAlign.center,
							),
						],
					),
				),
			),
		);
	}
}
