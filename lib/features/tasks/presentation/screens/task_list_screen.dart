import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/navigation/app_page_route.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/productivity/productivity_analyzer.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_feedback.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
import 'package:nuvora/core/widgets/app_responsive.dart';
import 'package:nuvora/features/tasks/application/controllers/category_provider.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:nuvora/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:nuvora/features/tasks/presentation/widgets/task_item.dart';

class TaskListScreen extends ConsumerStatefulWidget {
	const TaskListScreen({super.key});

	@override
	ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
	bool _showArchived = false;

	@override
	Widget build(BuildContext context) {
		final horizontalPadding = AppResponsive.pagePadding(context);
		final motionDuration = AppMotion.resolvedDuration(context, AppMotion.duration);
		final motionCurve = AppMotion.resolvedCurve(context, AppMotion.curve);
		final categories = ref.watch(categoriesProvider).maybeWhen(
			data: (items) => items,
			orElse: () => const <Category>[],
		);
		final Map<String, String> categoryById = <String, String>{
			for (final category in categories) category.id: category.name,
		};
		final tasksAsync = _showArchived
			? ref.watch(archivedTasksProvider)
			: ref.watch(activeTasksProvider);
		final stateChild = tasksAsync.when(
			data: (tasks) {
				if (tasks.isEmpty) {
					return AppEmptyState(
						key: ValueKey(_showArchived ? 'tasks-archived-empty' : 'tasks-active-empty'),
						icon: _showArchived ? Icons.archive_outlined : Icons.check_circle_outline,
						title: _showArchived ? 'No archived tasks' : 'Start planning your day',
						detail: _showArchived ? 'Archive tasks to see them here' : 'No tasks yet',
						description: _showArchived
							? 'Archived tasks remain available for reference'
							: 'Create your first task to get started',
						button: _showArchived
							? null
							: ElevatedButton.icon(
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
					);
				}

				if (_showArchived) {
					return ListView(
						key: ValueKey('tasks-archived-data-${tasks.length}'),
						shrinkWrap: true,
						physics: const NeverScrollableScrollPhysics(),
						padding: EdgeInsets.symmetric(
							horizontal: horizontalPadding,
							vertical: AppSpacing.md,
						),
						children: [
							_TaskPrioritySection(
								title: 'Archived',
								tasks: tasks,
								emptyText: 'No archived tasks',
								childBuilder: (task) => _taskTile(
									context,
									task,
									categoryById,
								),
							),
						],
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
					key: ValueKey('tasks-active-data-${tasks.length}'),
					shrinkWrap: true,
					physics: const NeverScrollableScrollPhysics(),
					padding: EdgeInsets.symmetric(
						horizontal: horizontalPadding,
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
								boxShadow: [
									BoxShadow(
										color: Colors.black.withValues(alpha: 0.03),
										blurRadius: 8,
										offset: const Offset(0, 3),
									),
								],
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
											duration: AppMotion.duration,
											curve: AppMotion.curve,
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
							childBuilder: (task) => _taskTile(
								context,
								task,
								categoryById,
							),
						),
						_TaskPrioritySection(
							title: 'Upcoming',
							tasks: upcoming,
							emptyText: 'No upcoming tasks available',
							childBuilder: (task) => _taskTile(
								context,
								task,
								categoryById,
							),
						),
						_TaskPrioritySection(
							title: 'Completed today',
							tasks: completedToday,
							emptyText: 'No completed tasks yet',
							childBuilder: (task) => _taskTile(
								context,
								task,
								categoryById,
							),
						),
						const SizedBox(height: AppSpacing.sm),
					],
				);
			},
			loading: () => AppLoadingState(
				key: ValueKey(_showArchived ? 'tasks-archived-loading' : 'tasks-active-loading'),
				label: _showArchived ? 'Loading archived tasks...' : 'Loading tasks...',
			),
			error: (error, _) => Center(
				key: ValueKey(_showArchived ? 'tasks-archived-error' : 'tasks-active-error'),
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
								_showArchived ? 'Error loading archived tasks' : 'Error loading tasks',
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

		final lifecycleTabs = Padding(
			padding: EdgeInsets.fromLTRB(horizontalPadding, AppSpacing.md, horizontalPadding, 0),
			child: Row(
				children: [
					Expanded(
						child: ChoiceChip(
							key: const ValueKey('tasks-filter-active'),
							label: const Text('Active Tasks'),
							selected: !_showArchived,
							onSelected: (selected) {
								if (!selected) return;
								setState(() => _showArchived = false);
							},
						),
					),
					const SizedBox(width: AppSpacing.sm),
					Expanded(
						child: ChoiceChip(
							key: const ValueKey('tasks-filter-archived'),
							label: const Text('Archived'),
							selected: _showArchived,
							onSelected: (selected) {
								if (!selected) return;
								setState(() => _showArchived = true);
							},
						),
					),
				],
			),
		);

		return AnimatedSwitcher(
			duration: motionDuration,
			switchInCurve: motionCurve,
			switchOutCurve: motionCurve,
			transitionBuilder: (child, animation) {
				return FadeTransition(
					opacity: animation,
					child: SlideTransition(
						position: Tween<Offset>(
							begin: AppMotion.subtleOffset,
							end: Offset.zero,
						).animate(animation),
						child: child,
					),
				);
			},
			child: LayoutBuilder(
				key: ValueKey(_showArchived ? 'tasks-archived-view' : 'tasks-active-view'),
				builder: (context, constraints) {
					if (constraints.maxHeight.isFinite) {
						return Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								lifecycleTabs,
								Expanded(child: stateChild),
							],
						);
					}

					return Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							lifecycleTabs,
							stateChild,
						],
					);
				},
			),
		);
	}

	Widget _taskTile(
		BuildContext context,
		Task task,
		Map<String, String> categoryById,
	) {
		return Padding(
			padding: const EdgeInsets.only(bottom: AppSpacing.md),
			child: TaskItem(
				key: ValueKey(task.id),
				task: task,
				categoryName: task.categoryId == null
					? null
					: categoryById[task.categoryId!],
				onTap: () {
					Navigator.of(context).push(
						AppPageRoute<void>(
							builder: (_) => TaskDetailScreen(task: task),
						),
					);
				},
				onToggleCompleted: (value) async {
					try {
						HapticFeedback.selectionClick();
						await ref.read(taskControllerProvider).markTaskAsCompleted(
							taskId: task.id,
							isCompleted: value,
						);
						ref.invalidate(tasksProvider);
						ref.invalidate(activeTasksProvider);
						ref.invalidate(archivedTasksProvider);
					} catch (_) {
						if (context.mounted) {
							AppFeedback.showSnackBar(context, 'Could not update task');
						}
					}
				},
				onDelete: () async {
					try {
						HapticFeedback.mediumImpact();
						await ref.read(taskControllerProvider).deleteTask(task.id);
						ref.invalidate(tasksProvider);
						ref.invalidate(activeTasksProvider);
						ref.invalidate(archivedTasksProvider);
					} catch (_) {
						if (context.mounted) {
							AppFeedback.showSnackBar(context, 'Could not delete task');
						}
					}
				},
				onToggleArchived: (willBeArchived) async {
					try {
						HapticFeedback.selectionClick();
						if (willBeArchived) {
							await ref.read(taskControllerProvider).archiveTask(task);
						} else {
							await ref.read(taskControllerProvider).unarchiveTask(task);
						}
						ref.invalidate(tasksProvider);
						ref.invalidate(activeTasksProvider);
						ref.invalidate(archivedTasksProvider);
					} catch (_) {
						if (context.mounted) {
							AppFeedback.showSnackBar(
								context,
								willBeArchived
									? 'Could not archive task'
									: 'Could not unarchive task',
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
				Row(
					children: [
						Text(title, style: AppTypography.headlineSmall),
						if (tasks.isNotEmpty) ...[
							const SizedBox(width: AppSpacing.sm),
							Container(
								padding: const EdgeInsets.symmetric(
									horizontal: AppSpacing.sm,
									vertical: AppSpacing.xs,
								),
								decoration: BoxDecoration(
									color: AppColors.surfaceSecondary,
									borderRadius: BorderRadius.circular(AppRadius.full),
								),
								child: Text(
									'${tasks.length}',
									style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
								),
							),
						],
					],
				),
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
					ListView.builder(
						shrinkWrap: true,
						physics: const NeverScrollableScrollPhysics(),
						itemCount: tasks.length,
						itemBuilder: (context, index) => childBuilder(tasks[index]),
					),
				const SizedBox(height: AppSpacing.sm),
			],
		);
	}
}
