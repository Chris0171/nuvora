import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/tasks/application/controllers/task_controller.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';
import 'package:nuvora/features/tasks/presentation/screens/create_task_screen.dart';

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------
class _FakeRepo implements TaskRepository {
  bool shouldThrow;
  Task? lastCreated;
  Completer<void>? createCompleter;

  _FakeRepo({this.shouldThrow = false, this.createCompleter});

  @override
  Future<void> createTask(Task task) async {
    if (createCompleter != null) await createCompleter!.future;
    if (shouldThrow) throw Exception('Storage full');
    lastCreated = task;
  }

  @override
  Future<List<Task>> getTasks() async => [];

  @override
  Future<void> updateTask(Task task) async {}

  @override
  Future<void> updateTaskCompletion(
      {required String taskId, required bool isCompleted}) async {}

  @override
  Future<void> deleteTask(String taskId) async {}
}

// ---------------------------------------------------------------------------
// Widget builder – uses a parent route so navigation-back can be verified.
// ---------------------------------------------------------------------------
Widget _buildSubject(TaskController controller) => ProviderScope(
      overrides: [
        taskControllerProvider.overrideWithValue(controller),
        tasksProvider.overrideWith((_) async => []),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) => const CreateTaskScreen(),
                ),
              ),
              child: const Text('Go to Create'),
            ),
          ),
        ),
      ),
    );

// Navigate to CreateTaskScreen from the parent.
Future<void> _navigateToCreate(WidgetTester tester) async {
  await tester.tap(find.text('Go to Create'));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
void main() {
  group('CreateTaskScreen', () {
    testWidgets('renders title and description fields', (tester) async {
      final controller = TaskController(repository: _FakeRepo());
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Titulo'), findsOneWidget);
      expect(find.text('Descripcion'), findsOneWidget);
    });

    testWidgets('shows validation error when title is empty', (tester) async {
      final controller = TaskController(repository: _FakeRepo());
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      // Tap save without entering a title.
      await tester.tap(find.text('Guardar tarea'));
      await tester.pumpAndSettle();

      expect(find.text('El titulo es obligatorio'), findsOneWidget);
    });

    testWidgets('calls createTask with correct title', (tester) async {
      final repo = _FakeRepo();
      final controller = TaskController(repository: repo);
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.enterText(
          find.byType(TextFormField).first, 'My new task');
      await tester.tap(find.text('Guardar tarea'));
      await tester.pumpAndSettle();

      expect(repo.lastCreated?.title, 'My new task');
    });

    testWidgets('navigates back after successful save', (tester) async {
      final controller = TaskController(repository: _FakeRepo());
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Test');
      await tester.tap(find.text('Guardar tarea'));
      await tester.pumpAndSettle();

      // Should be back on the parent screen.
      expect(find.text('Go to Create'), findsOneWidget);
      expect(find.text('Guardar tarea'), findsNothing);
    });

    testWidgets('shows SnackBar and stays on screen when createTask throws',
        (tester) async {
      final controller = TaskController(repository: _FakeRepo(shouldThrow: true));
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Bad task');
      await tester.tap(find.text('Guardar tarea'));
      await tester.pump();
      await tester.pump();

      expect(find.text('No se pudo guardar la tarea.'), findsOneWidget);
      // Still on CreateTaskScreen – save button is visible.
      expect(find.text('Guardar tarea'), findsOneWidget);
    });

    testWidgets('button is disabled while save is in progress', (tester) async {
      final completer = Completer<void>();
      final controller =
          TaskController(repository: _FakeRepo(createCompleter: completer));
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Slow task');
      await tester.tap(find.text('Guardar tarea'));
      await tester.pump(); // triggers setState(_isSaving = true)

      // Button onPressed should be null while saving.
      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(button.onPressed, isNull);

      // Clean up – complete so no pending timers remain.
      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('button re-enables after save error', (tester) async {
      final controller = TaskController(repository: _FakeRepo(shouldThrow: true));
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Failing');
      await tester.tap(find.text('Guardar tarea'));
      await tester.pump();
      await tester.pump(); // finally block fires

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(button.onPressed, isNotNull);
    });
  });
}
