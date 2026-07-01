import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/navigation/app_page_route.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/productivity/productivity_analyzer.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:nuvora/features/tasks/presentation/widgets/task_item.dart';

class TaskListScreen extends ConsumerWidget {
	const TaskListScreen({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final tasksAsync = ref.watch(tasksProvider);
		final stateChild = tasksAsync.when(
			data: (tasks) {
				if (tasks.isEmpty) {
					return Padding(
						key: const ValueKey('tasks-empty'),
						padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								const SizedBox(height: 60),
								Container(
									width: 84,
									height: 84,
									decoration: BoxDecoration(
										gradient: const LinearGradient(
											colors: [Color(0xFFE3F2FD), Color(0xFFF3F4F6)],
											begin: Alignment.topLeft,
											end: Alignment.bottomRight,
										),
										borderRadius: BorderRadius.circular(AppRadius.xl),
									),
									child: const Icon(
										Icons.check_circle_outline,
										size: 42,
										color: AppColors.primary,
									),
								),
								const SizedBox(height: AppSpacing.lg),
								const Text(
									'Start planning your day',
									style: AppTypography.headlineMedium,
									textAlign: TextAlign.center,
								),
								const SizedBox(height: AppSpacing.md),
								Text(
									'No tasks yet',
									style: AppTypography.bodyMedium.copyWith(
										color: AppColors.textSecondary,
									),
									textAlign: TextAlign.center,
								),
								const SizedBox(height: AppSpacing.xs),
								Text(
									'Create your first task to get started',
									style: AppTypography.bodyMedium.copyWith(
										color: AppColors.textSecondary,
									),
									textAlign: TextAlign.center,
								),
								const SizedBox(height: AppSpacing.lg),
								ElevatedButton.icon(
									onPressed: () {
										Navigator.of(context).push(
											AppPageRoute<void>(
												builder: (_) => const CreateTaskScreen(),
											),
										);
									},
									icon: const Icon(Icons.add),
									label: const Text('Create your first task'),
								),
								const SizedBox(height: 60),
							],
						),
					);
				}

				final progress = ProductivityAnalyzer.calculateCompletionRate(tasks);
				final progressLabel = '${(progress * 100).round()}% complete today';

				final mustDoNow = tasks
					.where((task) =>
						!task.isCompleted &&
						(task.priority == Priority.high || task.priority == Priority.urgent))
					.toList();
				final upcoming = tasks
					.where((task) =>
						!task.isCompleted &&
						(task.priority == Priority.medium || task.priority == Priority.low))
					.toList();
				final completedToday = tasks
					.where((task) => task.isCompleted)
					.toList();

				return ListView(
					key: ValueKey('tasks-data-${tasks.length}'),
					shrinkWrap: true,
					physics: const NeverScrollableScrollPhysics(),
					padding: const EdgeInsets.symmetric(
						horizontal: AppSpacing.lg,
						vertical: AppSpacing.md,
					),
					children: [
						Container(
							width: double.infinity,
							padding: const EdgeInsets.all(AppSpacing.lg),
							decoration: BoxDecoration(
								color: AppColors.surface,
								borderRadius: BorderRadius.circular(AppRadius.xl),
								border: Border.all(color: AppColors.border),
							),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									const Text('Daily completion score', style: AppTypography.headlineMedium),
									const SizedBox(height: AppSpacing.sm),
									Text(
										progressLabel,
										style: AppTypography.bodySmall.copyWith(
											color: AppColors.textSecondary,
										),
									),
									const SizedBox(height: AppSpacing.md),
									ClipRRect(
										borderRadius: BorderRadius.circular(AppRadius.full),
										child: TweenAnimationBuilder<double>(
											tween: Tween<double>(begin: 0, end: progress),
											duration: const Duration(milliseconds: 700),
											curve: Curves.easeOutCubic,
											builder: (context, value, _) {
												return LinearProgressIndicator(
													value: value,
													minHeight: 8,
													backgroundColor: AppColors.surfaceSecondary,
													valueColor: const AlwaysStoppedAnimation<Color>(
														AppColors.primary,
													),
												);
											},
										),
									),
								],
							),
						),
						const SizedBox(height: AppSpacing.xl),
						_TaskPrioritySection(
							title: 'Must do now',
							tasks: mustDoNow,
							emptyText: 'No urgent tasks right now',
							childBuilder: (task) => _taskTile(context, ref, task),
						),
						_TaskPrioritySection(
							title: 'Upcoming',
							tasks: upcoming,
							emptyText: 'No upcoming tasks available',
							childBuilder: (task) => _taskTile(context, ref, task),
						),
						_TaskPrioritySection(
							title: 'Completed today',
							tasks: completedToday,
							emptyText: 'No completed tasks yet',
							childBuilder: (task) => _taskTile(context, ref, task),
						),
					],
				);
			},
			loading: () => Center(
				key: const ValueKey('tasks-loading'),
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
				key: const ValueKey('tasks-error'),
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

		return AnimatedSwitcher(
			duration: const Duration(milliseconds: 320),
			switchInCurve: Curves.easeOutCubic,
			switchOutCurve: Curves.easeInCubic,
			transitionBuilder: (child, animation) {
				return FadeTransition(
					opacity: animation,
					child: SlideTransition(
						position: Tween<Offset>(
							begin: const Offset(0, 0.03),
							end: Offset.zero,
						).animate(animation),
						child: child,
					),
				);
			},
			child: stateChild,
		);
	}

	Widget _taskTile(BuildContext context, WidgetRef ref, Task task) {
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
								const SnackBar(content: Text('Could not update task')),
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
								const SnackBar(content: Text('Could not delete task')),
							);
						}
					}
				},
			),
		);
	}
}

class _TaskPrioritySection extends StatelessWidget {
	const _TaskPrioritySection({
		required this.title,
		required this.tasks,
		required this.emptyText,
		required this.childBuilder,
	});

	final String title;
	final List<Task> tasks;
	final String emptyText;
	final Widget Function(Task task) childBuilder;

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(title, style: AppTypography.headlineSmall),
				const SizedBox(height: AppSpacing.md),
				if (tasks.isEmpty)
					Padding(
						padding: const EdgeInsets.only(bottom: AppSpacing.md),
						child: Text(
							emptyText,
							style: AppTypography.bodySmall.copyWith(
								color: AppColors.textSecondary,
							),
						),
					)
				else
					...tasks.map(childBuilder),
				const SizedBox(height: AppSpacing.sm),
			],
		);
	}
}
