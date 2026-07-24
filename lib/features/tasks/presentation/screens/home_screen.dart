import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/navigation/app_page_route.dart';
import 'package:nuvora/core/productivity/productivity_analyzer.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
import 'package:nuvora/core/widgets/app_responsive.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:nuvora/features/tasks/presentation/screens/task_list_screen.dart';

class HomeScreen extends ConsumerWidget {
	const HomeScreen({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final horizontalPadding = AppResponsive.pagePadding(context);
		final maxWidth = AppResponsive.maxContentWidth(context);
		final titleScale = AppResponsive.titleScale(context);

		final List<Task> tasks = ref.watch(tasksProvider).maybeWhen(
			data: (items) => items,
			orElse: () => const <Task>[],
		);
		final completion = ProductivityAnalyzer.calculateCompletionRate(tasks);
		final completed = tasks.where((task) => task.isCompleted).length;
		final pending = tasks.length - completed;
		final subtitle = tasks.isEmpty
			? 'No tasks yet. Start planning your day.'
			: '$pending active • $completed completed';

		return Scaffold(
			body: FadeSlideIn(
				child: Align(
					alignment: Alignment.topCenter,
					child: ConstrainedBox(
						constraints: BoxConstraints(maxWidth: maxWidth),
						child: CustomScrollView(
							slivers: [
					SliverAppBar(
						floating: true,
						elevation: 0,
						backgroundColor: Colors.transparent,
						title: const Text('Tasks'),
						bottom: PreferredSize(
							preferredSize: const Size.fromHeight(138),
							child: Padding(
								padding: EdgeInsets.fromLTRB(
									horizontalPadding,
									0,
									horizontalPadding,
									AppSpacing.lg,
								),
								child: Container(
									width: double.infinity,
									padding: const EdgeInsets.all(AppSpacing.lg),
									decoration: BoxDecoration(
										color: AppColors.surface,
										border: Border.all(color: AppColors.border),
										borderRadius: BorderRadius.circular(AppRadius.xl),
										boxShadow: [
											BoxShadow(
												color: Colors.black.withValues(alpha: 0.04),
												blurRadius: 10,
												offset: const Offset(0, 4),
											),
										],
									),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											const Text(
												'Today',
												style: AppTypography.labelLarge,
											),
											const SizedBox(height: AppSpacing.xs),
											Text(
												'Focus Plan',
												style: AppTypography.displaySmall.copyWith(
													fontSize: 28 * titleScale,
												),
											),
											const SizedBox(height: AppSpacing.xs),
											Text(
												subtitle,
												style: AppTypography.bodySmall.copyWith(
													color: AppColors.textSecondary,
												),
											),
											const SizedBox(height: AppSpacing.md),
											ClipRRect(
												borderRadius: BorderRadius.circular(AppRadius.full),
												child: LinearProgressIndicator(
													value: completion,
													minHeight: 6,
													backgroundColor: AppColors.surfaceSecondary,
													valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
												),
											),
										],
									),
								),
							),
						),
					),
					const SliverToBoxAdapter(
						child: TaskListScreen(),
					),
				],
						),
					),
				),
			),
			floatingActionButton: FloatingActionButton.extended(
				backgroundColor: AppColors.surface,
				foregroundColor: AppColors.textPrimary,
				elevation: AppElevation.md,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(AppRadius.xl),
					side: const BorderSide(color: AppColors.border),
				),
				onPressed: () async {
					await Navigator.of(context).push(
						AppPageRoute<void>(
							builder: (_) => const CreateTaskScreen(),
						),
					);
				},
				icon: const Icon(Icons.add, color: AppColors.primary),
				label: const Text('New Task'),
			),
		);
	}
}
