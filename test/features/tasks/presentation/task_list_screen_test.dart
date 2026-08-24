import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/tasks/application/controllers/category_controller.dart';
import 'package:nuvora/features/tasks/application/controllers/category_provider.dart';
import 'package:nuvora/features/tasks/application/controllers/task_controller.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/category_repository.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';
import 'package:nuvora/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:nuvora/features/tasks/presentation/screens/task_list_screen.dart';
import 'package:nuvora/features/tasks/presentation/widgets/task_item.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------
class _FakeRepo implements TaskRepository {
  final List<Task> tasks;
  bool deleteShouldThrow;
  bool completionShouldThrow;
  bool updateShouldThrow;
  String? lastDeletedId;
  Task? lastUpdated;
  ({String taskId, bool isCompleted})? lastCompletion;

  _FakeRepo({
    List<Task>? tasks,
    this.deleteShouldThrow = false,
    this.completionShouldThrow = false,
    this.updateShouldThrow = false,
  }) : tasks = tasks ?? [];

  @override
  Future<List<Task>> getTasks() async => List.unmodifiable(tasks);

  @override
  Future<List<Task>> getActiveTasks() async {
    return tasks.where((task) => !task.archived).toList(growable: false);
  }

  @override
  Future<List<Task>> getArchivedTasks() async {
    return tasks.where((task) => task.archived).toList(growable: false);
  }

  @override
  Future<void> createTask(Task task) async {}

  @override
  Future<void> updateTask(Task task) async {
    if (updateShouldThrow) throw TaskNotFoundException(task.id);
    lastUpdated = task;
  }

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

class _FakeCategoryRepo implements CategoryRepository {
  _FakeCategoryRepo({List<Category>? initial}) : categories = initial ?? <Category>[];

  final List<Category> categories;

  @override
  Future<void> createCategory(Category category) async {}

  @override
  Future<List<Category>> getCategories() async => List.unmodifiable(categories);
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
  _FakeCategoryRepo? categoryRepo,
}) =>
    ProviderScope(
      overrides: [
        tasksProvider.overrideWith((_) => Future.value(tasks)),
        activeTasksProvider.overrideWith(
          (_) => Future.value(
            tasks.where((task) => !task.archived).toList(growable: false),
          ),
        ),
        archivedTasksProvider.overrideWith(
          (_) => Future.value(
            tasks.where((task) => task.archived).toList(growable: false),
          ),
        ),
        taskControllerProvider.overrideWithValue(controller),
        categoryControllerProvider.overrideWithValue(
          CategoryController(repository: categoryRepo ?? _FakeCategoryRepo()),
        ),
        categoriesProvider.overrideWith(
          (ref) async =>
              (categoryRepo ?? _FakeCategoryRepo()).getCategories(),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TaskListScreen()),
      ),
    );

Widget _buildError(Object err) => ProviderScope(
      overrides: [
        tasksProvider.overrideWith((_) => Future.error(err)),
        activeTasksProvider.overrideWith((_) => Future.error(err)),
        archivedTasksProvider.overrideWith((_) => Future.error(err)),
        taskControllerProvider.overrideWithValue(
          TaskController(repository: _FakeRepo()),
        ),
        categoryControllerProvider.overrideWithValue(
          CategoryController(repository: _FakeCategoryRepo()),
        ),
        categoriesProvider.overrideWith((ref) async => const <Category>[]),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TaskListScreen()),
      ),
    );

Widget _buildLoading() => ProviderScope(
      overrides: [
        tasksProvider.overrideWith((_) => Completer<List<Task>>().future),
        activeTasksProvider.overrideWith((_) => Completer<List<Task>>().future),
        archivedTasksProvider.overrideWith((_) => Completer<List<Task>>().future),
        taskControllerProvider.overrideWithValue(
          TaskController(repository: _FakeRepo()),
        ),
        categoryControllerProvider.overrideWithValue(
          CategoryController(repository: _FakeCategoryRepo()),
        ),
        categoriesProvider.overrideWith((ref) async => const <Category>[]),
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
      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('can switch to archived tab and see archived tasks only',
      (tester) async {
      final tasks = [
        _makeTask(id: 'active-1', title: 'Active task'),
        _makeTask(id: 'archived-1', title: 'Archived task').copyWith(archived: true),
      ];
      final controller = TaskController(repository: _FakeRepo(tasks: tasks));
      await tester.pumpWidget(_buildSubject(tasks: tasks, controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Active task'), findsOneWidget);
      expect(find.text('Archived task'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('tasks-filter-archived')));
      await tester.pumpAndSettle();

      expect(find.text('Archived task'), findsOneWidget);
      expect(find.text('Active task'), findsNothing);
    });

    testWidgets('archived empty state is shown in archived tab', (tester) async {
      final tasks = [_makeTask(id: 'active-1', title: 'Active task')];
      final controller = TaskController(repository: _FakeRepo(tasks: tasks));
      await tester.pumpWidget(_buildSubject(tasks: tasks, controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tasks-filter-archived')));
      await tester.pumpAndSettle();

      expect(find.text('No archived tasks'), findsOneWidget);
      expect(find.text('Archive tasks to see them here'), findsOneWidget);
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
      expect(find.text('Error loading tasks'), findsOneWidget);
    });

    testWidgets('calls deleteTask on controller when delete icon tapped',
        (tester) async {
      final task = _makeTask(id: 'del-target');
      final repo = _FakeRepo(tasks: [task]);
      final controller = TaskController(repository: repo);
      await tester
          .pumpWidget(_buildSubject(tasks: [task], controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump();

      expect(repo.lastDeletedId, 'del-target');
    });

    testWidgets('archives active task from list action', (tester) async {
      final task = _makeTask(id: 'arch-target');
      final repo = _FakeRepo(tasks: [task]);
      final controller = TaskController(repository: repo);
      await tester.pumpWidget(_buildSubject(tasks: [task], controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pump();

      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.archived, isTrue);
      expect(repo.lastUpdated!.deletedAt, isNull);
    });

    testWidgets('unarchives task from archived tab action', (tester) async {
      final task = _makeTask(id: 'unarch-target').copyWith(archived: true);
      final repo = _FakeRepo(tasks: [task]);
      final controller = TaskController(repository: repo);
      await tester.pumpWidget(_buildSubject(tasks: [task], controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tasks-filter-archived')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.unarchive_outlined));
      await tester.pump();

      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.archived, isFalse);
    });

    testWidgets('shows SnackBar when archive update fails', (tester) async {
      final task = _makeTask(id: 'archive-fail');
      final repo = _FakeRepo(tasks: [task], updateShouldThrow: true);
      final controller = TaskController(repository: repo);
      await tester.pumpWidget(_buildSubject(tasks: [task], controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pump();
      await tester.pump();

      expect(find.text('Could not archive task'), findsOneWidget);
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

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump();

      expect(find.text('Could not delete task'), findsOneWidget);
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
          find.text('Could not update task'), findsOneWidget);
    });

    testWidgets('opens TaskDetailScreen when tapping a task item',
        (tester) async {
      final task = _makeTask(id: 'open-detail', title: 'Open detail task');
      final repo = _FakeRepo(tasks: [task]);
      final controller = TaskController(repository: repo);
      await tester.pumpWidget(_buildSubject(tasks: [task], controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open detail task'));
      await tester.pumpAndSettle();

      expect(find.byType(TaskDetailScreen), findsOneWidget);
      expect(find.text('Task Detail'), findsOneWidget);
      expect(find.text('Open detail task'), findsOneWidget);
    });

    testWidgets('shows category name in TaskItem when category exists',
        (tester) async {
      final task = _makeTask(id: 'cat-task', title: 'Categorized task')
          .copyWith(categoryId: 'work');
      final repo = _FakeRepo(tasks: [task]);
      final categoryRepo = _FakeCategoryRepo(
        initial: const [Category(id: 'work', name: 'Work')],
      );
      final controller = TaskController(repository: repo);
      await tester.pumpWidget(
        _buildSubject(
          tasks: [task],
          controller: controller,
          categoryRepo: categoryRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);
    });
  });
}
