import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';

void main() {
  final now = DateTime(2026, 6, 15, 10, 0);

  Note buildNote({
    String id = 'note-1',
    String title = 'Title',
    String content = 'Content',
    DateTime? createdAt,
    DateTime? updatedAt,
    bool isPinned = false,
    bool archived = false,
    DateTime? deletedAt,
  }) =>
      Note(
        id: id,
        title: title,
        content: content,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt,
        isPinned: isPinned,
        archived: archived,
        deletedAt: deletedAt,
      );

  group('Note defaults', () {
    test('updatedAt defaults to createdAt', () {
      final note = buildNote();
      expect(note.updatedAt, note.createdAt);
    });

    test('archived defaults to false', () {
      final note = buildNote();
      expect(note.archived, isFalse);
    });

    test('deletedAt defaults to null', () {
      final note = buildNote();
      expect(note.deletedAt, isNull);
    });
  });

  group('copyWith', () {
    test('creates immutable updated copy', () {
      final original = buildNote(title: 'A');
      final copy = original.copyWith(title: 'B');
      expect(original.title, 'A');
      expect(copy.title, 'B');
    });

    test('preserves unspecified fields', () {
      final original = buildNote(
        content: 'Body',
        isPinned: true,
        archived: true,
      );
      final copy = original.copyWith(title: 'Changed');

      expect(copy.id, original.id);
      expect(copy.content, 'Body');
      expect(copy.isPinned, isTrue);
      expect(copy.archived, isTrue);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
    });

    test('supports soft delete and archive updates', () {
      final deletedAt = now.add(const Duration(days: 1));
      final note = buildNote();
      final copy = note.copyWith(archived: true, deletedAt: deletedAt);

      expect(copy.archived, isTrue);
      expect(copy.deletedAt, deletedAt);
    });

    test('supports pin toggle', () {
      final note = buildNote(isPinned: false);
      final copy = note.copyWith(isPinned: true);
      expect(copy.isPinned, isTrue);
    });
  });
}
