import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/application/controllers/category_controller.dart';
import 'package:nuvora/features/tasks/application/controllers/category_provider.dart';
import 'package:nuvora/features/tasks/application/controllers/task_controller.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/category_repository.dart';
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

class _FakeCategoryRepo implements CategoryRepository {
  _FakeCategoryRepo({List<Category>? initial}) : categories = initial ?? <Category>[];

  final List<Category> categories;

  @override
  Future<void> createCategory(Category category) async {
    categories.add(
      Category(
        id: category.id.isEmpty ? 'cat-${categories.length + 1}' : category.id,
        name: category.name,
      ),
    );
  }

  @override
  Future<List<Category>> getCategories() async => List.unmodifiable(categories);
}

Task _makeTask({
  String id = 'task-id-1',
  String title = 'Task title',
  String? description = 'Task description',
  Priority priority = Priority.medium,
  RepeatType repeatType = RepeatType.none,
  DateTime? dueDate,
  bool isCompleted = false,
}) =>
    Task(
      id: id,
      title: title,
      description: description,
      createdAt: DateTime(2026, 7, 1, 10, 0),
      updatedAt: DateTime(2026, 7, 1, 10, 0),
      dueDate: dueDate,
      isCompleted: isCompleted,
      priority: priority,
      repeatType: repeatType,
    );

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

Widget _buildSubject({
  required Task task,
  required TaskController controller,
  _FakeCategoryRepo? categoryRepo,
}) =>
    ProviderScope(
      overrides: [
        taskControllerProvider.overrideWithValue(controller),
        tasksProvider.overrideWith((_) async => <Task>[task]),
        categoryControllerProvider.overrideWithValue(
          CategoryController(repository: categoryRepo ?? _FakeCategoryRepo()),
        ),
        categoriesProvider.overrideWith(
          (ref) async => (categoryRepo ?? _FakeCategoryRepo()).getCategories(),
        ),
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
      expect(find.byKey(const ValueKey('task-detail-repeat-label')), findsOneWidget);
      expect(find.text('No repeat'), findsOneWidget);
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
		expect(find.byKey(const ValueKey('task-edit-repeat-field')), findsOneWidget);
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

      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repo.updateCalls, 1);
      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.title, 'Updated title');
      expect(repo.lastUpdated!.description, 'Updated description');
      expect(repo.lastUpdated!.priority, Priority.high);
      expect(repo.lastUpdated!.repeatType, RepeatType.none);

      expect(find.text('Task Detail'), findsOneWidget);
      expect(find.text('Updated title'), findsOneWidget);
      expect(find.text('Updated description'), findsOneWidget);
      expect(find.text('Priority: High'), findsOneWidget);
    });

    testWidgets('shows repeat value in detail when task is recurring',
      (tester) async {
      final repo = _FakeRepo();
      final task = _makeTask(repeatType: RepeatType.weekly);
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('task-detail-repeat-label')), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
    });

    testWidgets('edits repeat and persists updated value', (tester) async {
      final repo = _FakeRepo();
      final task = _makeTask(repeatType: RepeatType.none);
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('task-edit-repeat-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.repeatType, RepeatType.monthly);
      expect(find.text('Monthly'), findsOneWidget);
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
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      expect(repo.updateCalls, 0);
      expect(repo.lastUpdated, isNull);
    });

    testWidgets('shows no due date when task has no due date', (tester) async {
      final repo = _FakeRepo();
      final task = _makeTask(dueDate: null);
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Due date'), findsOneWidget);
      expect(find.text('No due date'), findsOneWidget);
      expect(find.text('Overdue'), findsNothing);
    });

    testWidgets('shows category name when category exists', (tester) async {
      final repo = _FakeRepo();
      final categories = _FakeCategoryRepo(
        initial: [const Category(id: 'work', name: 'Work')],
      );
      final task = _makeTask().copyWith(categoryId: 'work');
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(
        _buildSubject(task: task, controller: controller, categoryRepo: categories),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('task-detail-category-label')), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('shows formatted future due date', (tester) async {
      final repo = _FakeRepo();
      final future = DateTime.now().add(const Duration(days: 3));
      final task = _makeTask(dueDate: DateTime(future.year, future.month, future.day));
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('task-detail-due-date-label')), findsOneWidget);
      expect(find.text('Overdue'), findsNothing);
    });

    testWidgets('shows overdue indicator for past due date', (tester) async {
      final repo = _FakeRepo();
      final past = DateTime.now().subtract(const Duration(days: 2));
      final task = _makeTask(dueDate: DateTime(past.year, past.month, past.day));
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('edit mode shows existing due date and can change it',
        (tester) async {
      final repo = _FakeRepo();
      final initialDueDate = DateTime(2026, 1, 1);
      final task = _makeTask(dueDate: initialDueDate);
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('task-edit-due-date-label')), findsOneWidget);

      final selectDateButton = find.byKey(const ValueKey('task-edit-select-date-button'));
      await tester.ensureVisible(selectDateButton);
      await tester.tap(selectDateButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.dueDate, isNotNull);
      expect(_dateOnly(repo.lastUpdated!.dueDate!), isNot(_dateOnly(initialDueDate)));
    });

    testWidgets('edit mode can clear due date and save null', (tester) async {
      final repo = _FakeRepo();
      final task = _makeTask(dueDate: DateTime(2026, 1, 1));
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(task: task, controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final clearDateButton = find.byKey(const ValueKey('task-edit-clear-date-button'));
      await tester.ensureVisible(clearDateButton);
      await tester.tap(clearDateButton);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.dueDate, isNull);
      expect(find.text('No due date'), findsOneWidget);
    });

    testWidgets('edit mode shows existing category and can change it',
        (tester) async {
      final repo = _FakeRepo();
      final categories = _FakeCategoryRepo(
        initial: const [
          Category(id: 'work', name: 'Work'),
          Category(id: 'personal', name: 'Personal'),
        ],
      );
      final task = _makeTask().copyWith(categoryId: 'work');
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(
        _buildSubject(task: task, controller: controller, categoryRepo: categories),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('task-edit-category-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.categoryId, 'personal');
    });

    testWidgets('edit mode can remove category and save null', (tester) async {
      final repo = _FakeRepo();
      final categories = _FakeCategoryRepo(
        initial: const [Category(id: 'work', name: 'Work')],
      );
      final task = _makeTask().copyWith(categoryId: 'work');
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(
        _buildSubject(task: task, controller: controller, categoryRepo: categories),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('task-edit-category-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No category'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.categoryId, isNull);
      expect(find.text('No category'), findsOneWidget);
    });
  });
}
