import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
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

	@override
	void dispose() {
		_titleController.dispose();
		_descriptionController.dispose();
		super.dispose();
	}

	Future<void> _saveTask() async {
		if (!_formKey.currentState!.validate()) {
			return;
		}

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

		await ref.read(taskControllerProvider).createTask(newTask);
		ref.invalidate(tasksProvider);

		if (mounted) {
			Navigator.of(context).pop(true);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Crear tarea')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Form(
					key: _formKey,
					child: Column(
						children: [
							TextFormField(
								controller: _titleController,
								decoration: const InputDecoration(labelText: 'Titulo'),
								validator: (value) {
									if (value == null || value.trim().isEmpty) {
										return 'El titulo es obligatorio';
									}
									return null;
								},
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _descriptionController,
								decoration: const InputDecoration(labelText: 'Descripcion'),
							),
							const SizedBox(height: 20),
							SizedBox(
								width: double.infinity,
								child: ElevatedButton(
									onPressed: _saveTask,
									child: const Text('Guardar tarea'),
								),
							),
						],
					),
				),
			),
		);
	}
}
