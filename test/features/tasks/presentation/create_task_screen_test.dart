import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/application/controllers/category_controller.dart';
import 'package:nuvora/features/tasks/application/controllers/category_provider.dart';
import 'package:nuvora/features/tasks/application/controllers/task_controller.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/category_repository.dart';
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

// ---------------------------------------------------------------------------
// Widget builder – uses a parent route so navigation-back can be verified.
// ---------------------------------------------------------------------------
Widget _buildSubject(
  TaskController controller, {
  _FakeCategoryRepo? categoryRepo,
}) => ProviderScope(
      overrides: [
        taskControllerProvider.overrideWithValue(controller),
        tasksProvider.overrideWith((_) async => []),
        categoryControllerProvider.overrideWithValue(
          CategoryController(repository: categoryRepo ?? _FakeCategoryRepo()),
        ),
        categoriesProvider.overrideWith(
          (ref) async =>
              (categoryRepo ?? _FakeCategoryRepo()).getCategories(),
        ),
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

Future<void> _tapCreateTask(WidgetTester tester) async {
  final createButton = find.text('Create Task');
  await tester.ensureVisible(createButton);
  await tester.tap(createButton);
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

// ---------------------------------------------------------------------------
void main() {
  group('CreateTaskScreen', () {
    testWidgets('renders title and description fields', (tester) async {
      final controller = TaskController(repository: _FakeRepo());
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('shows validation error when title is empty', (tester) async {
      final controller = TaskController(repository: _FakeRepo());
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      // Tap save without entering a title.
      await _tapCreateTask(tester);
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('calls createTask with correct title', (tester) async {
      final repo = _FakeRepo();
      final controller = TaskController(repository: repo);
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.enterText(
          find.byType(TextFormField).first, 'My new task');
        await _tapCreateTask(tester);
      await tester.pumpAndSettle();

      expect(repo.lastCreated?.title, 'My new task');
    });

    testWidgets('navigates back after successful save', (tester) async {
      final controller = TaskController(repository: _FakeRepo());
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Test');
      await _tapCreateTask(tester);
      await tester.pumpAndSettle();

      // Should be back on the parent screen.
      expect(find.text('Go to Create'), findsOneWidget);
      expect(find.text('Create Task'), findsNothing);
    });

    testWidgets('shows SnackBar and stays on screen when createTask throws',
        (tester) async {
      final controller = TaskController(repository: _FakeRepo(shouldThrow: true));
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Bad task');
      await _tapCreateTask(tester);
      await tester.pump();
      await tester.pump();

      expect(find.text('Could not save task'), findsOneWidget);
      // Still on CreateTaskScreen – save button is visible.
      expect(find.text('Create Task'), findsOneWidget);
    });

    testWidgets('button is disabled while save is in progress', (tester) async {
      final completer = Completer<void>();
      final controller =
          TaskController(repository: _FakeRepo(createCompleter: completer));
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Slow task');
      await _tapCreateTask(tester);
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
      await _tapCreateTask(tester);
      await tester.pump();
      await tester.pump(); // finally block fires

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('allows selecting due date and shows it on screen', (tester) async {
      final controller = TaskController(repository: _FakeRepo());
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      expect(find.text('No due date'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('create-task-select-date-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('No due date'), findsNothing);
      expect(find.byKey(const ValueKey('create-task-due-date-label')), findsOneWidget);
    });

    testWidgets('creates task with selected due date', (tester) async {
      final repo = _FakeRepo();
      final controller = TaskController(repository: repo);
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Task with due date');
      await tester.tap(find.byKey(const ValueKey('create-task-select-date-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await _tapCreateTask(tester);
      await tester.pumpAndSettle();

      expect(repo.lastCreated, isNotNull);
      expect(repo.lastCreated!.dueDate, isNotNull);
      expect(_dateOnly(repo.lastCreated!.dueDate!), _dateOnly(DateTime.now()));
    });

    testWidgets('shows category selector and assigns selected category',
        (tester) async {
      final repo = _FakeRepo();
      final categories = _FakeCategoryRepo(
        initial: [
          const Category(id: 'work', name: 'Work'),
          const Category(id: 'personal', name: 'Personal'),
        ],
      );
      final controller = TaskController(repository: repo);

      await tester.pumpWidget(_buildSubject(controller, categoryRepo: categories));
      await _navigateToCreate(tester);

      expect(find.byKey(const ValueKey('create-task-category-selector')), findsOneWidget);
      expect(find.text('No category'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('create-task-category-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Task with category');
      await _tapCreateTask(tester);
      await tester.pumpAndSettle();

      expect(repo.lastCreated, isNotNull);
      expect(repo.lastCreated!.categoryId, 'work');
    });

    testWidgets('defaults repeat selector to no repeat', (tester) async {
      final controller = TaskController(repository: _FakeRepo());
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      expect(find.byKey(const ValueKey('create-task-repeat-field')), findsOneWidget);
      expect(find.text('No repeat'), findsOneWidget);
    });

    testWidgets('creates task with selected repeat type', (tester) async {
      final repo = _FakeRepo();
      final controller = TaskController(repository: repo);
      await tester.pumpWidget(_buildSubject(controller));
      await _navigateToCreate(tester);

      await tester.tap(find.byKey(const ValueKey('create-task-repeat-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Recurring task');
      await _tapCreateTask(tester);
      await tester.pumpAndSettle();

      expect(repo.lastCreated, isNotNull);
      expect(repo.lastCreated!.repeatType, RepeatType.weekly);
    });
  });
}
