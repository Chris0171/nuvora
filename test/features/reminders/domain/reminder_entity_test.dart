import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/reminder_type.dart';
import 'package:nuvora/features/reminders/domain/entities/reminder.dart';

void main() {
  final now = DateTime(2026, 8, 20, 10, 0, 0);

  Reminder buildReminder({
    String id = 'rem-1',
    String title = 'Pay invoice',
    String? description,
    DateTime? scheduledAt,
    String? relatedItemId,
    ReminderType type = ReminderType.task,
    bool isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool archived = false,
    DateTime? deletedAt,
  }) {
    return Reminder(
      id: id,
      title: title,
      description: description,
      scheduledAt: scheduledAt ?? now.add(const Duration(hours: 2)),
      relatedItemId: relatedItemId,
      type: type,
      isActive: isActive,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt,
      archived: archived,
      deletedAt: deletedAt,
    );
  }

  group('Reminder defaults', () {
    test('updatedAt defaults to createdAt', () {
      final reminder = buildReminder();
      expect(reminder.updatedAt, reminder.createdAt);
    });

    test('description defaults to null', () {
      final reminder = buildReminder();
      expect(reminder.description, isNull);
    });

    test('relatedItemId defaults to null', () {
      final reminder = buildReminder();
      expect(reminder.relatedItemId, isNull);
    });

    test('archived defaults to false', () {
      final reminder = buildReminder();
      expect(reminder.archived, isFalse);
    });

    test('deletedAt defaults to null', () {
      final reminder = buildReminder();
      expect(reminder.deletedAt, isNull);
    });
  });

  group('Reminder copyWith', () {
    test('creates immutable updated copy', () {
      final original = buildReminder(title: 'Original');
      final copy = original.copyWith(title: 'Updated');

      expect(original.title, 'Original');
      expect(copy.title, 'Updated');
    });

    test('preserves unspecified fields', () {
      final original = buildReminder(
        description: 'desc',
        relatedItemId: 'task-1',
        type: ReminderType.note,
        isActive: false,
        archived: true,
      );
      final copy = original.copyWith(title: 'New title');

      expect(copy.id, original.id);
      expect(copy.description, 'desc');
      expect(copy.relatedItemId, 'task-1');
      expect(copy.type, ReminderType.note);
      expect(copy.isActive, isFalse);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
      expect(copy.archived, isTrue);
    });

    test('supports soft delete', () {
      final deletedAt = now.add(const Duration(days: 1));
      final reminder = buildReminder();
      final copy = reminder.copyWith(deletedAt: deletedAt);

      expect(copy.deletedAt, deletedAt);
      expect(reminder.deletedAt, isNull);
    });

    test('supports activate/deactivate', () {
      final reminder = buildReminder(isActive: true);
      final copy = reminder.copyWith(isActive: false);
      expect(copy.isActive, isFalse);
    });

    test('can change all fields', () {
      final future = now.add(const Duration(days: 3));
      final copy = buildReminder().copyWith(
        id: 'rem-2',
        title: 'Updated title',
        description: 'Updated description',
        scheduledAt: future,
        relatedItemId: 'note-1',
        type: ReminderType.note,
        isActive: false,
        createdAt: future,
        updatedAt: future,
        archived: true,
        deletedAt: future,
      );

      expect(copy.id, 'rem-2');
      expect(copy.title, 'Updated title');
      expect(copy.description, 'Updated description');
      expect(copy.scheduledAt, future);
      expect(copy.relatedItemId, 'note-1');
      expect(copy.type, ReminderType.note);
      expect(copy.isActive, isFalse);
      expect(copy.createdAt, future);
      expect(copy.updatedAt, future);
      expect(copy.archived, isTrue);
      expect(copy.deletedAt, future);
    });
  });

  group('Reminder enums and timestamps', () {
    test('stores all ReminderType values', () {
      for (final type in ReminderType.values) {
        final reminder = buildReminder(type: type);
        expect(reminder.type, type);
      }
    });

    test('scheduledAt can differ from createdAt', () {
      final scheduledAt = now.add(const Duration(days: 1));
      final reminder = buildReminder(scheduledAt: scheduledAt);
      expect(reminder.scheduledAt, scheduledAt);
      expect(reminder.createdAt, now);
    });
  });
}