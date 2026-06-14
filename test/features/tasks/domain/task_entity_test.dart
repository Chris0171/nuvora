import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

void main() {
  final DateTime now = DateTime(2026, 6, 14, 10, 0, 0);

  Task buildTask({
    String id = 'test-uuid-1234',
    String title = 'Write unit tests',
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    bool isCompleted = false,
    Priority priority = Priority.medium,
    String? categoryId,
    RepeatType repeatType = RepeatType.none,
    bool archived = false,
    DateTime? deletedAt,
  }) =>
      Task(
        id: id,
        title: title,
        description: description,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt,
        dueDate: dueDate,
        isCompleted: isCompleted,
        priority: priority,
        categoryId: categoryId,
        repeatType: repeatType,
        archived: archived,
        deletedAt: deletedAt,
      );

  group('Task entity – construction defaults', () {
    test('updatedAt defaults to createdAt when not provided', () {
      final task = buildTask();
      expect(task.updatedAt, task.createdAt);
    });

    test('updatedAt uses provided value when given', () {
      final later = now.add(const Duration(hours: 1));
      final task = buildTask(updatedAt: later);
      expect(task.updatedAt, later);
    });

    test('archived defaults to false', () {
      final task = buildTask();
      expect(task.archived, isFalse);
    });

    test('deletedAt defaults to null', () {
      final task = buildTask();
      expect(task.deletedAt, isNull);
    });

    test('description defaults to null', () {
      final task = buildTask();
      expect(task.description, isNull);
    });

    test('isCompleted defaults to false', () {
      final task = buildTask();
      expect(task.isCompleted, isFalse);
    });
  });

  group('Task entity – copyWith', () {
    test('returns a new instance with changed title', () {
      final original = buildTask(title: 'Original');
      final copy = original.copyWith(title: 'Updated');
      expect(copy.title, 'Updated');
      expect(original.title, 'Original'); // immutable
    });

    test('preserves all unchanged fields', () {
      final dueDate = now.add(const Duration(days: 1));
      final original = buildTask(
        description: 'desc',
        dueDate: dueDate,
        isCompleted: true,
        priority: Priority.high,
        categoryId: 'cat-1',
        repeatType: RepeatType.daily,
        archived: true,
      );
      final copy = original.copyWith(title: 'New title');

      expect(copy.id, original.id);
      expect(copy.description, original.description);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
      expect(copy.dueDate, original.dueDate);
      expect(copy.isCompleted, original.isCompleted);
      expect(copy.priority, original.priority);
      expect(copy.categoryId, original.categoryId);
      expect(copy.repeatType, original.repeatType);
      expect(copy.archived, original.archived);
    });

    test('copyWith can update updatedAt independently', () {
      final later = now.add(const Duration(hours: 2));
      final original = buildTask();
      final copy = original.copyWith(updatedAt: later);
      expect(copy.updatedAt, later);
      expect(copy.createdAt, original.createdAt);
    });

    test('copyWith can mark as completed', () {
      final task = buildTask(isCompleted: false);
      final completed = task.copyWith(isCompleted: true);
      expect(completed.isCompleted, isTrue);
    });

    test('copyWith can soft-delete (set deletedAt)', () {
      final task = buildTask();
      final deleted = task.copyWith(deletedAt: now);
      expect(deleted.deletedAt, now);
      expect(task.deletedAt, isNull); // original unchanged
    });

    test('copyWith with all fields changes every field', () {
      final original = buildTask();
      final newDate = now.add(const Duration(days: 7));
      final copy = original.copyWith(
        id: 'new-id',
        title: 'New',
        description: 'New desc',
        createdAt: newDate,
        updatedAt: newDate,
        dueDate: newDate,
        isCompleted: true,
        priority: Priority.urgent,
        categoryId: 'new-cat',
        repeatType: RepeatType.weekly,
        archived: true,
        deletedAt: newDate,
      );

      expect(copy.id, 'new-id');
      expect(copy.title, 'New');
      expect(copy.description, 'New desc');
      expect(copy.createdAt, newDate);
      expect(copy.updatedAt, newDate);
      expect(copy.dueDate, newDate);
      expect(copy.isCompleted, isTrue);
      expect(copy.priority, Priority.urgent);
      expect(copy.categoryId, 'new-cat');
      expect(copy.repeatType, RepeatType.weekly);
      expect(copy.archived, isTrue);
      expect(copy.deletedAt, newDate);
    });
  });

  group('Task entity – field types', () {
    test('stores all Priority values', () {
      for (final p in Priority.values) {
        final task = buildTask(priority: p);
        expect(task.priority, p);
      }
    });

    test('stores all RepeatType values', () {
      for (final r in RepeatType.values) {
        final task = buildTask(repeatType: r);
        expect(task.repeatType, r);
      }
    });
  });
}
