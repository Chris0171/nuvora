import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/tasks/data/datasources/sqlite_task_datasource.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Each call creates a unique in-memory database so tests are fully isolated.
int _dbCounter = 0;

SQLiteTaskDataSource _buildDS() {
  // sqflite_common_ffi treats paths that start with "file:" with "?mode=memory"
  // as named in-memory databases – a fresh unique name gives full isolation.
  final uniquePath = 'file:test_db_${_dbCounter++}?mode=memory&cache=shared';
  return SQLiteTaskDataSource(
    databaseFactory: databaseFactoryFfi,
    databasePath: uniquePath,
  );
}

int _seq = 0;

Task _makeTask({
  String? id,
  String title = 'Test task',
  bool isCompleted = false,
  bool archived = false,
  DateTime? createdAt,
}) =>
    Task(
      id: id ?? 'task-${_seq++}',
      title: title,
      createdAt: createdAt ?? DateTime.now(),
      isCompleted: isCompleted,
      priority: Priority.medium,
      repeatType: RepeatType.none,
      archived: archived,
    );

// ---------------------------------------------------------------------------
void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  // Each test gets a fresh in-memory database.
  late SQLiteTaskDataSource ds;

  setUp(() {
    _seq = 0;
    ds = _buildDS();
  });

  // -------------------------------------------------------------------------
  group('createTask + getTasks – round trip', () {
    test('created task is returned by getTasks', () async {
      final task = _makeTask(title: 'Buy milk');
      await ds.createTask(task);
      final tasks = await ds.getTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first.title, 'Buy milk');
      expect(tasks.first.id, task.id);
    });

    test('multiple tasks are all returned', () async {
      await ds.createTask(_makeTask(title: 'A'));
      await ds.createTask(_makeTask(title: 'B'));
      await ds.createTask(_makeTask(title: 'C'));
      final tasks = await ds.getTasks();
      expect(tasks, hasLength(3));
    });

    test('all fields survive round-trip', () async {
      final now = DateTime.now();
      final due = now.add(const Duration(days: 1));
      final task = Task(
        id: 'full-task',
        title: 'Full',
        description: 'desc',
        createdAt: now,
        updatedAt: now,
        dueDate: due,
        isCompleted: true,
        priority: Priority.urgent,
        categoryId: 'cat-1',
        repeatType: RepeatType.weekly,
        archived: true,
      );
      await ds.createTask(task);
      final retrieved = (await ds.getTasks()).first;

      expect(retrieved.id, 'full-task');
      expect(retrieved.title, 'Full');
      expect(retrieved.description, 'desc');
      expect(retrieved.isCompleted, isTrue);
      expect(retrieved.priority, Priority.urgent);
      expect(retrieved.categoryId, 'cat-1');
      expect(retrieved.repeatType, RepeatType.weekly);
      expect(retrieved.archived, isTrue);
      expect(
        retrieved.createdAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
      expect(
        retrieved.dueDate?.millisecondsSinceEpoch,
        due.millisecondsSinceEpoch,
      );
    });

    test('getTasks returns tasks ordered by created_at DESC', () async {
      final base = DateTime(2026, 6, 14, 10, 0, 0);
      await ds.createTask(_makeTask(createdAt: base));
      await ds.createTask(_makeTask(createdAt: base.add(const Duration(seconds: 1))));
      await ds.createTask(_makeTask(createdAt: base.add(const Duration(seconds: 2))));

      final tasks = await ds.getTasks();
      expect(
        tasks[0].createdAt.isAfter(tasks[1].createdAt),
        isTrue,
        reason: 'Tasks should be ordered newest first',
      );
      expect(tasks[1].createdAt.isAfter(tasks[2].createdAt), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  group('createTask – duplicate id', () {
    test('throws TaskAlreadyExistsException on duplicate id', () async {
      final task = _makeTask(id: 'dup-id');
      await ds.createTask(task);
      await expectLater(
        ds.createTask(_makeTask(id: 'dup-id')),
        throwsA(isA<TaskAlreadyExistsException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('updateTask', () {
    test('updates title and other fields', () async {
      final task = _makeTask(id: 'upd-1', title: 'Original');
      await ds.createTask(task);

      await ds.updateTask(task.copyWith(title: 'Updated'));

      final tasks = await ds.getTasks();
      expect(tasks.first.title, 'Updated');
    });

    test('throws TaskNotFoundException for unknown id', () async {
      await expectLater(
        ds.updateTask(_makeTask(id: 'ghost')),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('throws TaskNotFoundException for soft-deleted task', () async {
      final task = _makeTask(id: 'del-then-update');
      await ds.createTask(task);
      await ds.deleteTask(task.id);

      await expectLater(
        ds.updateTask(task.copyWith(title: 'Ghost update')),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('updateTaskCompletion', () {
    test('marks task as completed', () async {
      final task = _makeTask(id: 'comp-1', isCompleted: false);
      await ds.createTask(task);
      await ds.updateTaskCompletion(taskId: task.id, isCompleted: true);
      final tasks = await ds.getTasks();
      expect(tasks.first.isCompleted, isTrue);
    });

    test('marks task as incomplete (undo)', () async {
      final task = _makeTask(id: 'comp-2', isCompleted: true);
      await ds.createTask(task);
      await ds.updateTaskCompletion(taskId: task.id, isCompleted: false);
      final tasks = await ds.getTasks();
      expect(tasks.first.isCompleted, isFalse);
    });

    test('throws TaskNotFoundException for unknown id', () async {
      await expectLater(
        ds.updateTaskCompletion(taskId: 'ghost', isCompleted: true),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('throws TaskNotFoundException for soft-deleted task', () async {
      final task = _makeTask(id: 'del-comp');
      await ds.createTask(task);
      await ds.deleteTask(task.id);

      await expectLater(
        ds.updateTaskCompletion(taskId: task.id, isCompleted: true),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('deleteTask – soft delete', () {
    test('deleted task does not appear in getTasks', () async {
      final task = _makeTask(id: 'soft-del-1');
      await ds.createTask(task);
      await ds.deleteTask(task.id);
      final tasks = await ds.getTasks();
      expect(tasks, isEmpty);
    });

    test('non-deleted tasks remain visible after another is deleted', () async {
      final keep = _makeTask(id: 'keep');
      final remove = _makeTask(id: 'remove');
      await ds.createTask(keep);
      await ds.createTask(remove);
      await ds.deleteTask(remove.id);
      final tasks = await ds.getTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first.id, keep.id);
    });

    test('throws TaskNotFoundException for unknown id', () async {
      await expectLater(
        ds.deleteTask('ghost-id'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('throws TaskNotFoundException when deleting already-deleted task', () async {
      final task = _makeTask(id: 'double-del');
      await ds.createTask(task);
      await ds.deleteTask(task.id);

      await expectLater(
        ds.deleteTask(task.id),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('edge cases', () {
    test('null description survives round-trip', () async {
      final task = _makeTask(id: 'no-desc');
      await ds.createTask(task);
      final result = (await ds.getTasks()).first;
      expect(result.description, isNull);
    });

    test('null dueDate survives round-trip', () async {
      final task = _makeTask(id: 'no-due');
      await ds.createTask(task);
      final result = (await ds.getTasks()).first;
      expect(result.dueDate, isNull);
    });

    test('null categoryId survives round-trip', () async {
      final task = _makeTask(id: 'no-cat');
      await ds.createTask(task);
      final result = (await ds.getTasks()).first;
      expect(result.categoryId, isNull);
    });

    test('all Priority values survive round-trip', () async {
      for (final priority in Priority.values) {
        final freshDs = _buildDS();
        final task = Task(
          id: 'p-${priority.name}',
          title: 'task',
          createdAt: DateTime.now(),
          isCompleted: false,
          priority: priority,
          repeatType: RepeatType.none,
        );
        await freshDs.createTask(task);
        final result = (await freshDs.getTasks()).first;
        expect(result.priority, priority);
      }
    });

    test('all RepeatType values survive round-trip', () async {
      for (final repeat in RepeatType.values) {
        final freshDs = _buildDS();
        final task = Task(
          id: 'r-${repeat.name}',
          title: 'task',
          createdAt: DateTime.now(),
          isCompleted: false,
          priority: Priority.low,
          repeatType: repeat,
        );
        await freshDs.createTask(task);
        final result = (await freshDs.getTasks()).first;
        expect(result.repeatType, repeat);
      }
    });
  });

  // -------------------------------------------------------------------------
  group('performance', () {
    test('insert and query 1000 tasks completes in under 5 seconds', () async {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        await ds.createTask(_makeTask(
          id: 'perf-$i',
          createdAt: DateTime.now().add(Duration(seconds: i)),
        ));
      }

      final tasks = await ds.getTasks();
      stopwatch.stop();

      expect(tasks, hasLength(1000));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
        reason: '1000 inserts + 1 query should complete under 5s',
      );
    });

    test('query after 1000 soft-deletes returns empty list efficiently', () async {
      for (int i = 0; i < 100; i++) {
        await ds.createTask(_makeTask(id: 'sdel-$i'));
      }
      for (int i = 0; i < 100; i++) {
        await ds.deleteTask('sdel-$i');
      }

      final stopwatch = Stopwatch()..start();
      final tasks = await ds.getTasks();
      stopwatch.stop();

      expect(tasks, isEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
