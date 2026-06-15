import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/tasks/application/controllers/task_controller.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';
import 'package:nuvora/features/tasks/presentation/screens/task_list_screen.dart';
import 'package:nuvora/features/tasks/presentation/widgets/task_item.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------
class _FakeRepo implements TaskRepository {
  final List<Task> tasks;
  bool deleteShouldThrow;
  bool completionShouldThrow;
  String? lastDeletedId;
  ({String taskId, bool isCompleted})? lastCompletion;

  _FakeRepo({
    List<Task>? tasks,
    this.deleteShouldThrow = false,
    this.completionShouldThrow = false,
  }) : tasks = tasks ?? [];

  @override
  Future<List<Task>> getTasks() async => List.unmodifiable(tasks);

  @override
  Future<void> createTask(Task task) async {}

  @override
  Future<void> updateTask(Task task) async {}

  @override
  Future<void> updateTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    if (completionShouldThrow) throw TaskNotFoundException(taskId);
    lastCompletion = (taskId: taskId, isCompleted: isCompleted);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    if (deleteShouldThrow) throw TaskNotFoundException(taskId);
    lastDeletedId = taskId;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Task _makeTask({String id = 'tid-1', String title = 'Task Alpha'}) => Task(
      id: id,
      title: title,
      createdAt: DateTime(2026, 6, 14),
      isCompleted: false,
      priority: Priority.medium,
      repeatType: RepeatType.none,
    );

Widget _buildSubject({
  required List<Task> tasks,
  required TaskController controller,
}) =>
    ProviderScope(
      overrides: [
        tasksProvider.overrideWith((_) => Future.value(tasks)),
        taskControllerProvider.overrideWithValue(controller),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TaskListScreen()),
      ),
    );

Widget _buildError(Object err) => ProviderScope(
      overrides: [
        tasksProvider.overrideWith((_) => Future.error(err)),
        taskControllerProvider.overrideWithValue(
          TaskController(repository: _FakeRepo()),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TaskListScreen()),
      ),
    );

Widget _buildLoading() => ProviderScope(
      overrides: [
        tasksProvider.overrideWith((_) => Completer<List<Task>>().future),
        taskControllerProvider.overrideWithValue(
          TaskController(repository: _FakeRepo()),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TaskListScreen()),
      ),
    );

// ---------------------------------------------------------------------------
void main() {
  group('TaskListScreen', () {
    testWidgets('shows CircularProgressIndicator while loading',
        (tester) async {
      await tester.pumpWidget(_buildLoading());
      await tester.pump(); // single frame – future still pending
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty-state text when no tasks', (tester) async {
      final repo = _FakeRepo(tasks: []);
      final controller = TaskController(repository: repo);
      await tester.pumpWidget(_buildSubject(tasks: [], controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('No hay tareas todavia.'), findsOneWidget);
    });

    testWidgets('renders one TaskItem per task', (tester) async {
      final tasks = [_makeTask(id: '1'), _makeTask(id: '2'), _makeTask(id: '3')];
      final controller = TaskController(repository: _FakeRepo(tasks: tasks));
      await tester.pumpWidget(_buildSubject(tasks: tasks, controller: controller));
      await tester.pumpAndSettle();
      expect(find.byType(TaskItem), findsNWidgets(3));
    });

    testWidgets('renders task titles', (tester) async {
      final tasks = [
        _makeTask(id: 'a', title: 'Alpha Task'),
        _makeTask(id: 'b', title: 'Beta Task'),
      ];
      final controller = TaskController(repository: _FakeRepo(tasks: tasks));
      await tester.pumpWidget(_buildSubject(tasks: tasks, controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Alpha Task'), findsOneWidget);
      expect(find.text('Beta Task'), findsOneWidget);
    });

    testWidgets('TaskItems use ValueKey with task id', (tester) async {
      final tasks = [_makeTask(id: 'unique-key-42')];
      final controller = TaskController(repository: _FakeRepo(tasks: tasks));
      await tester.pumpWidget(_buildSubject(tasks: tasks, controller: controller));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('unique-key-42')), findsOneWidget);
    });

    testWidgets('shows error widget when provider throws', (tester) async {
      await tester.pumpWidget(_buildError(Exception('DB error')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets('calls deleteTask on controller when delete icon tapped',
        (tester) async {
      final task = _makeTask(id: 'del-target');
      final repo = _FakeRepo(tasks: [task]);
      final controller = TaskController(repository: repo);
      await tester
          .pumpWidget(_buildSubject(tasks: [task], controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump();

      expect(repo.lastDeletedId, 'del-target');
    });

    testWidgets('calls updateTaskCompletion on controller when checkbox toggled',
        (tester) async {
      final task = _makeTask(id: 'comp-target');
      final repo = _FakeRepo(tasks: [task]);
      final controller = TaskController(repository: repo);
      await tester
          .pumpWidget(_buildSubject(tasks: [task], controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.pump();

      expect(repo.lastCompletion?.taskId, 'comp-target');
      expect(repo.lastCompletion?.isCompleted, isTrue);
    });

    testWidgets('shows SnackBar when deleteTask throws', (tester) async {
      final task = _makeTask(id: 'err-del');
      final repo = _FakeRepo(tasks: [task], deleteShouldThrow: true);
      final controller = TaskController(repository: repo);
      await tester
          .pumpWidget(_buildSubject(tasks: [task], controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump();

      expect(find.text('No se pudo eliminar la tarea.'), findsOneWidget);
    });

    testWidgets('shows SnackBar when updateTaskCompletion throws',
        (tester) async {
      final task = _makeTask(id: 'err-comp');
      final repo = _FakeRepo(tasks: [task], completionShouldThrow: true);
      final controller = TaskController(repository: repo);
      await tester
          .pumpWidget(_buildSubject(tasks: [task], controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.pump();

      expect(
          find.text('No se pudo actualizar la tarea.'), findsOneWidget);
    });
  });
}
