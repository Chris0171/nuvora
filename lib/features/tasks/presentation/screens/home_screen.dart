import 'package:flutter/material.dart';
import 'package:nuvora/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:nuvora/features/tasks/presentation/screens/task_list_screen.dart';

class HomeScreen extends StatelessWidget {
	const HomeScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Tasks')),
			body: const TaskListScreen(),
			floatingActionButton: FloatingActionButton(
				onPressed: () async {
					await Navigator.of(context).push(
						MaterialPageRoute<void>(
							builder: (_) => const CreateTaskScreen(),
						),
					);
				},
				child: const Icon(Icons.add),
			),
		);
	}
}
