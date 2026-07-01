import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:nuvora/features/tasks/presentation/screens/task_list_screen.dart';

class HomeScreen extends StatelessWidget {
	const HomeScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: CustomScrollView(
				slivers: [
					SliverAppBar(
						floating: true,
						elevation: 0,
						backgroundColor: Colors.transparent,
						title: const Text('Tasks'),
						bottom: PreferredSize(
							preferredSize: const Size.fromHeight(98),
							child: Padding(
								padding: const EdgeInsets.fromLTRB(
									AppSpacing.lg,
									0,
									AppSpacing.lg,
									AppSpacing.lg,
								),
								child: Container(
									width: double.infinity,
									padding: const EdgeInsets.all(AppSpacing.lg),
									decoration: BoxDecoration(
										gradient: const LinearGradient(
											colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
										),
										borderRadius: BorderRadius.circular(AppRadius.xl),
									),
									child: Row(
										children: [
											const Icon(
												Icons.today_outlined,
												color: AppColors.primary,
											),
											const SizedBox(width: AppSpacing.md),
											Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													const Text('Today', style: AppTypography.headlineMedium),
													Text(
														'Plan priorities and keep momentum',
														style: AppTypography.bodySmall.copyWith(
															color: AppColors.textSecondary,
														),
													),
												],
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
			floatingActionButton: FloatingActionButton.extended(
				backgroundColor: AppColors.primary,
				foregroundColor: Colors.white,
				elevation: AppElevation.lg,
				onPressed: () async {
					await Navigator.of(context).push(
						MaterialPageRoute<void>(
							builder: (_) => const CreateTaskScreen(),
						),
					);
				},
				icon: const Icon(Icons.add),
				label: const Text('New Task'),
			),
		);
	}
}
