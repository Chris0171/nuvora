import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/application/controllers/task_controller.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';
import 'package:nuvora/features/tasks/presentation/screens/task_detail_screen.dart';

class _FakeRepo implements TaskRepository {
  Task? lastUpdated;
  int updateCalls = 0;

  @override
  Future<void> createTask(Task task) async {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<List<Task>> getTasks() async => const <Task>[];

  @override
  Future<void> updateTask(Task task) async {
    updateCalls += 1;
    lastUpdated = task;
  }

  @override
  Future<void> updateTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {}
}

Task _makeTask({
  String id = 'task-id-1',
  String title = 'Task title',
  String? description = 'Task description',
  Priority priority = Priority.medium,
}) =>
    Task(
      id: id,
      title: title,
      description: description,
      createdAt: DateTime(2026, 7, 1, 10, 0),
      updatedAt: DateTime(2026, 7, 1, 10, 0),
      isCompleted: false,
      priority: priority,
      repeatType: RepeatType.none,
    );

Widget _buildSubject({required Task task, required TaskController controller}) =>
    ProviderScope(
      overrides: [
        taskControllerProvider.overrideWithValue(controller),
        tasksProvider.overrideWith((_) async => <Task>[task]),
      ],
      child: MaterialApp(home: TaskDetailScreen(task: task)),
    );

void main() {
  group('TaskDetailScreen', () {
    testWidgets('shows task title, description, priority and completion state',
        (tester) async {
      final repo = _FakeRepo();
      final task = _makeTask();
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Task Detail'), findsOneWidget);
      expect(find.text('Task title'), findsOneWidget);
      expect(find.text('Task description'), findsOneWidget);
      expect(find.text('Priority: Medium'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchTile.value, isFalse);
    });

    testWidgets('enters edit mode from Edit action', (tester) async {
      final repo = _FakeRepo();
      final task = _makeTask();
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Task'), findsOneWidget);
      expect(find.byKey(const ValueKey('task-edit-title-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-edit-description-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-edit-priority-field')), findsOneWidget);
    });

    testWidgets('saves edited title, description and priority using updateTask',
        (tester) async {
      final repo = _FakeRepo();
      final task = _makeTask();
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('task-edit-title-field')),
        'Updated title',
      );
      await tester.enterText(
        find.byKey(const ValueKey('task-edit-description-field')),
        'Updated description',
      );

      await tester.tap(find.byKey(const ValueKey('task-edit-priority-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repo.updateCalls, 1);
      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.title, 'Updated title');
      expect(repo.lastUpdated!.description, 'Updated description');
      expect(repo.lastUpdated!.priority, Priority.high);

      expect(find.text('Task Detail'), findsOneWidget);
      expect(find.text('Updated title'), findsOneWidget);
      expect(find.text('Updated description'), findsOneWidget);
      expect(find.text('Priority: High'), findsOneWidget);
    });

    testWidgets('validates empty title and does not call updateTask',
        (tester) async {
      final repo = _FakeRepo();
      final task = _makeTask();
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('task-edit-title-field')), '   ');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      expect(repo.updateCalls, 0);
      expect(repo.lastUpdated, isNull);
    });
  });
}
