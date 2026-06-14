import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/data/datasources/task_datasource.dart';
import 'package:nuvora/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

// ---------------------------------------------------------------------------
// Fake datasource – records every call for assertion.
// ---------------------------------------------------------------------------
class _FakeTaskDataSource implements TaskDataSource {
  final List<Task> stored = [];
  Task? lastUpdated;
  ({String taskId, bool isCompleted})? lastCompletion;
  String? lastDeleted;

  @override
  Future<List<Task>> getTasks() async => List.unmodifiable(stored);

  @override
  Future<void> createTask(Task task) async => stored.add(task);

  @override
  Future<void> updateTask(Task task) async {
    lastUpdated = task;
  }

  @override
  Future<void> updateTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    lastCompletion = (taskId: taskId, isCompleted: isCompleted);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    lastDeleted = taskId;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Task _makeTask({String id = 'uuid-abc', String title = 'Task'}) => Task(
      id: id,
      title: title,
      createdAt: DateTime(2026, 6, 14),
      isCompleted: false,
      priority: Priority.medium,
      repeatType: RepeatType.none,
    );

// UUID v4 regex
final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

void main() {
  late _FakeTaskDataSource fakeDS;
  late TaskRepositoryImpl repo;

  setUp(() {
    fakeDS = _FakeTaskDataSource();
    repo = TaskRepositoryImpl(dataSource: fakeDS);
  });

  // -------------------------------------------------------------------------
  group('getTasks', () {
    test('delegates to datasource', () async {
      fakeDS.stored.add(_makeTask());
      final tasks = await repo.getTasks();
      expect(tasks, hasLength(1));
    });
  });

  // -------------------------------------------------------------------------
  group('createTask – ID normalisation', () {
    test('preserves a valid UUID id', () async {
      const validUuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
      await repo.createTask(_makeTask(id: validUuid));
      expect(fakeDS.stored.first.id, validUuid);
    });

    test('replaces empty id with a UUID v4', () async {
      await repo.createTask(_makeTask(id: ''));
      expect(fakeDS.stored.first.id, matches(_uuidRegex));
    });

    test('replaces pure-digit (timestamp) id with UUID v4', () async {
      await repo.createTask(_makeTask(id: '1718351234567890'));
      expect(fakeDS.stored.first.id, matches(_uuidRegex));
      expect(fakeDS.stored.first.id, isNot('1718351234567890'));
    });

    test('replaces 10-digit timestamp id with UUID v4', () async {
      await repo.createTask(_makeTask(id: '1718351234'));
      expect(fakeDS.stored.first.id, matches(_uuidRegex));
    });

    test('preserves id with letters (not a pure timestamp)', () async {
      const mixedId = 'abc-123';
      await repo.createTask(_makeTask(id: mixedId));
      expect(fakeDS.stored.first.id, mixedId);
    });

    test('sets updatedAt to now on create', () async {
      final before = DateTime.now().subtract(const Duration(milliseconds: 50));
      await repo.createTask(_makeTask());
      final after = DateTime.now().add(const Duration(milliseconds: 50));
      expect(fakeDS.stored.first.updatedAt.isAfter(before), isTrue);
      expect(fakeDS.stored.first.updatedAt.isBefore(after), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  group('updateTask', () {
    test('stamps updatedAt when delegating to datasource', () async {
      final task = _makeTask();
      final before = DateTime.now().subtract(const Duration(milliseconds: 50));
      await repo.updateTask(task);
      final after = DateTime.now().add(const Duration(milliseconds: 50));
      expect(fakeDS.lastUpdated, isNotNull);
      expect(fakeDS.lastUpdated!.updatedAt.isAfter(before), isTrue);
      expect(fakeDS.lastUpdated!.updatedAt.isBefore(after), isTrue);
    });

    test('updatedAt is later than original', () async {
      final original = _makeTask();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.updateTask(original);
      expect(
        fakeDS.lastUpdated!.updatedAt.isAfter(original.updatedAt) ||
            fakeDS.lastUpdated!.updatedAt == original.updatedAt,
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  group('updateTaskCompletion', () {
    test('delegates to datasource with correct params', () async {
      await repo.updateTaskCompletion(taskId: 'tid', isCompleted: true);
      expect(fakeDS.lastCompletion?.taskId, 'tid');
      expect(fakeDS.lastCompletion?.isCompleted, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  group('deleteTask', () {
    test('delegates taskId to datasource', () async {
      await repo.deleteTask('del-id');
      expect(fakeDS.lastDeleted, 'del-id');
    });
  });
}
