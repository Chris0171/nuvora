import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/application/controllers/task_controller.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/repositories/task_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository – records calls for assertion.
// ---------------------------------------------------------------------------
class _FakeTaskRepository implements TaskRepository {
  final List<Task> storedTasks = [];
  String? lastDeletedId;
  ({String taskId, bool isCompleted})? lastCompletionUpdate;
  Exception? throwOnCreate;
  Exception? throwOnUpdate;
  Exception? throwOnDelete;

  @override
  Future<List<Task>> getTasks() async => List.unmodifiable(storedTasks);

  @override
  Future<void> createTask(Task task) async {
    if (throwOnCreate != null) throw throwOnCreate!;
    storedTasks.add(task);
  }

  @override
  Future<void> updateTask(Task task) async {
    if (throwOnUpdate != null) throw throwOnUpdate!;
    final index = storedTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) storedTasks[index] = task;
  }

  @override
  Future<void> updateTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    lastCompletionUpdate = (taskId: taskId, isCompleted: isCompleted);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    if (throwOnDelete != null) throw throwOnDelete!;
    lastDeletedId = taskId;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Task _makeTask({
  String id = 'uuid-abc-123',
  String title = 'Test task',
}) =>
    Task(
      id: id,
      title: title,
      createdAt: DateTime(2026, 6, 14),
      isCompleted: false,
      priority: Priority.medium,
      repeatType: RepeatType.none,
    );

void main() {
  late _FakeTaskRepository fakeRepo;
  late TaskController controller;

  setUp(() {
    fakeRepo = _FakeTaskRepository();
    controller = TaskController(repository: fakeRepo);
  });

  // -------------------------------------------------------------------------
  group('loadTasks', () {
    test('returns tasks from repository', () async {
      final task = _makeTask();
      fakeRepo.storedTasks.add(task);

      final result = await controller.loadTasks();

      expect(result, hasLength(1));
      expect(result.first.id, task.id);
    });

    test('returns empty list when repository is empty', () async {
      final result = await controller.loadTasks();
      expect(result, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  group('createTask', () {
    test('delegates to repository', () async {
      final task = _makeTask();
      await controller.createTask(task);
      expect(fakeRepo.storedTasks, hasLength(1));
    });

    test('propagates repository exceptions', () async {
      fakeRepo.throwOnCreate = Exception('DB full');
      await expectLater(
        controller.createTask(_makeTask()),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('updateTask', () {
    test('delegates to repository', () async {
      final original = _makeTask();
      fakeRepo.storedTasks.add(original);
      final updated = original.copyWith(title: 'Updated title');

      await controller.updateTask(updated);

      expect(fakeRepo.storedTasks.first.title, 'Updated title');
    });

    test('propagates repository exceptions', () async {
      fakeRepo.throwOnUpdate = Exception('write error');
      await expectLater(
        controller.updateTask(_makeTask()),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('deleteTask', () {
    test('delegates taskId to repository', () async {
      await controller.deleteTask('task-id-42');
      expect(fakeRepo.lastDeletedId, 'task-id-42');
    });

    test('propagates repository exceptions', () async {
      fakeRepo.throwOnDelete = Exception('not found');
      await expectLater(
        controller.deleteTask('missing'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('markTaskAsCompleted', () {
    test('calls updateTaskCompletion with correct params (complete)', () async {
      await controller.markTaskAsCompleted(
        taskId: 'tid-1',
        isCompleted: true,
      );
      expect(fakeRepo.lastCompletionUpdate?.taskId, 'tid-1');
      expect(fakeRepo.lastCompletionUpdate?.isCompleted, isTrue);
    });

    test('calls updateTaskCompletion with correct params (undo)', () async {
      await controller.markTaskAsCompleted(
        taskId: 'tid-2',
        isCompleted: false,
      );
      expect(fakeRepo.lastCompletionUpdate?.isCompleted, isFalse);
    });
  });
}
