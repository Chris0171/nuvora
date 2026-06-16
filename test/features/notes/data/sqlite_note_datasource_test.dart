import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/notes/data/datasources/sqlite_note_datasource.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _dbCounter = 0;

SQLiteNoteDataSource _buildDS() {
  final path = 'file:note_test_${_dbCounter++}?mode=memory&cache=shared';
  return SQLiteNoteDataSource(
    databaseFactory: databaseFactoryFfi,
    databasePath: path,
  );
}

int _seq = 0;

Note _note({
  String? id,
  String title = 'Title',
  String content = 'Body',
  bool isPinned = false,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool archived = false,
}) =>
    Note(
      id: id ?? 'n-${_seq++}',
      title: title,
      content: content,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      isPinned: isPinned,
      archived: archived,
    );

void main() {
  setUpAll(sqfliteFfiInit);

  late SQLiteNoteDataSource ds;

  setUp(() {
    _seq = 0;
    ds = _buildDS();
  });

  group('create + getNotes', () {
    test('round-trip persists note', () async {
      final n = _note(title: 'Buy milk', content: 'Remember lactose-free');
      await ds.createNote(n);
      final notes = await ds.getNotes();
      expect(notes, hasLength(1));
      expect(notes.first.title, 'Buy milk');
      expect(notes.first.content, 'Remember lactose-free');
    });

    test('returns notes sorted by updatedAt DESC', () async {
      final base = DateTime(2026, 6, 15, 10, 0, 0);
      await ds.createNote(_note(id: 'a', updatedAt: base));
      await ds.createNote(_note(id: 'b', updatedAt: base.add(const Duration(seconds: 1))));
      await ds.createNote(_note(id: 'c', updatedAt: base.add(const Duration(seconds: 2))));

      final notes = await ds.getNotes();
      expect(notes.first.id, 'c');
      expect(notes[1].id, 'b');
      expect(notes[2].id, 'a');
    });

    test('duplicate id throws NoteAlreadyExistsException', () async {
      await ds.createNote(_note(id: 'dup'));
      await expectLater(
        ds.createNote(_note(id: 'dup')),
        throwsA(isA<NoteAlreadyExistsException>()),
      );
    });
  });

  group('searchNotes', () {
    test('searches by title', () async {
      await ds.createNote(_note(id: '1', title: 'Shopping list', content: 'eggs'));
      await ds.createNote(_note(id: '2', title: 'Work', content: 'meeting'));

      final result = await ds.searchNotes('shop');
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('searches by content', () async {
      await ds.createNote(_note(id: '1', title: 'One', content: 'TensorFlow notes'));
      await ds.createNote(_note(id: '2', title: 'Two', content: 'Gardening'));

      final result = await ds.searchNotes('tensor');
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('is case-insensitive', () async {
      await ds.createNote(_note(id: '1', title: 'API Guide', content: 'rest'));
      final result = await ds.searchNotes('api');
      expect(result, hasLength(1));
    });

    test('empty query returns full list', () async {
      await ds.createNote(_note(id: '1'));
      await ds.createNote(_note(id: '2'));
      final result = await ds.searchNotes('   ');
      expect(result, hasLength(2));
    });
  });

  group('updateNote', () {
    test('updates existing note', () async {
      await ds.createNote(_note(id: '1', title: 'Old'));
      await ds.updateNote(_note(id: '1', title: 'New'));
      final result = await ds.getNotes();
      expect(result.first.title, 'New');
    });

    test('throws NoteNotFoundException for unknown id', () async {
      await expectLater(
        ds.updateNote(_note(id: 'ghost')),
        throwsA(isA<NoteNotFoundException>()),
      );
    });
  });

  group('soft delete', () {
    test('deleteNote hides note from getNotes', () async {
      await ds.createNote(_note(id: '1'));
      await ds.deleteNote('1');
      expect(await ds.getNotes(), isEmpty);
    });

    test('deleteNote hides note from search', () async {
      await ds.createNote(_note(id: '1', title: 'Searchable'));
      await ds.deleteNote('1');
      expect(await ds.searchNotes('search'), isEmpty);
    });

    test('double delete throws NoteNotFoundException', () async {
      await ds.createNote(_note(id: '1'));
      await ds.deleteNote('1');
      await expectLater(
        ds.deleteNote('1'),
        throwsA(isA<NoteNotFoundException>()),
      );
    });
  });
}
