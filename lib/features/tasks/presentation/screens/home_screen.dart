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
						title: Text(
							'Tasks',
							style: AppTypography.displaySmall,
						),
					),
					const SliverToBoxAdapter(
						child: TaskListScreen(),
					),
				],
			),
			floatingActionButton: FloatingActionButton.extended(
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
