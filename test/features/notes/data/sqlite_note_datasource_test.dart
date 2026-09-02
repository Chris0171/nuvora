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

    test('create then update persists title/content and keeps id/createdAt', () async {
      final createdAt = DateTime(2026, 6, 15, 10, 0, 0);
      final initial = _note(
        id: 'persist-update',
        title: 'Mi nota',
        content: 'Texto original',
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      await ds.createNote(initial);

      final updated = initial.copyWith(
        title: 'Mi nota modificada',
        content: 'Texto nuevo',
      );
      await ds.updateNote(updated);

      final notes = await ds.getNotes();
      expect(notes, hasLength(1));
      expect(notes.first.id, 'persist-update');
      expect(notes.first.title, 'Mi nota modificada');
      expect(notes.first.content, 'Texto nuevo');
      expect(notes.first.createdAt, createdAt);
      expect(
        notes.first.updatedAt.isAfter(createdAt) ||
          notes.first.updatedAt.isAtSameMomentAs(createdAt),
        isTrue,
      );
    });

    test('pin and unpin persist isPinned correctly across reads', () async {
      final note = _note(id: 'pin-test', title: 'Note', content: 'Body', isPinned: false);
      await ds.createNote(note);

      // Pin
      await ds.updateNote(note.copyWith(isPinned: true));
      var retrieved = await ds.getNotes();
      expect(retrieved.first.id, 'pin-test');
      expect(retrieved.first.isPinned, isTrue);

      // Unpin
      await ds.updateNote(retrieved.first.copyWith(isPinned: false));
      retrieved = await ds.getNotes();
      expect(retrieved.first.id, 'pin-test');
      expect(retrieved.first.isPinned, isFalse);
    });

    test('archive and unarchive persist archived correctly across reads', () async {
      final note = _note(id: 'arch-test', title: 'Note', content: 'Body', archived: false, isPinned: true);
      await ds.createNote(note);

      // Archive
      await ds.updateNote(note.copyWith(archived: true));
      var active = await ds.getActiveNotes();
      var archived = await ds.getArchivedNotes();
      expect(active, isEmpty);
      expect(archived, hasLength(1));
      expect(archived.first.id, 'arch-test');
      expect(archived.first.archived, isTrue);
      expect(archived.first.isPinned, isTrue);

      // Unarchive
      await ds.updateNote(archived.first.copyWith(archived: false));
      active = await ds.getActiveNotes();
      archived = await ds.getArchivedNotes();
      expect(active, hasLength(1));
      expect(active.first.id, 'arch-test');
      expect(active.first.archived, isFalse);
      expect(active.first.isPinned, isTrue);
      expect(archived, isEmpty);
    });
  });

  group('active vs archived queries', () {
    test('getActiveNotes and getArchivedNotes separate notes correctly', () async {
      await ds.createNote(_note(id: 'act-1', title: 'Active 1', archived: false));
      await ds.createNote(_note(id: 'act-2', title: 'Active 2', archived: false));
      await ds.createNote(_note(id: 'arch-1', title: 'Archived 1', archived: true));

      final active = await ds.getActiveNotes();
      final archived = await ds.getArchivedNotes();

      expect(active.map((n) => n.id).toList(), ['act-2', 'act-1']);
      expect(archived.map((n) => n.id).toList(), ['arch-1']);
    });

    test('searchNotes only searches active notes', () async {
      await ds.createNote(_note(id: 'act', title: 'Shopping Active', content: 'apples', archived: false));
      await ds.createNote(_note(id: 'arch', title: 'Shopping Archived', content: 'bananas', archived: true));

      final result = await ds.searchNotes('shopping');
      expect(result, hasLength(1));
      expect(result.first.id, 'act');
    });

    test('reopening datasource preserves notes state (active, pinned, archived)', () async {
      final sharedPath = 'file:shared_note_reopen_${_dbCounter++}?mode=memory&cache=shared';
      final ds1 = SQLiteNoteDataSource(
        databaseFactory: databaseFactoryFfi,
        databasePath: sharedPath,
      );

      final n1 = _note(id: 'r-1', title: 'N1', content: 'C1', isPinned: true, archived: false);
      final n2 = _note(id: 'r-2', title: 'N2', content: 'C2', isPinned: false, archived: true);
      await ds1.createNote(n1);
      await ds1.createNote(n2);

      final ds2 = SQLiteNoteDataSource(
        databaseFactory: databaseFactoryFfi,
        databasePath: sharedPath,
      );

      final active = await ds2.getActiveNotes();
      final archived = await ds2.getArchivedNotes();

      expect(active, hasLength(1));
      expect(active.first.id, 'r-1');
      expect(active.first.isPinned, isTrue);

      expect(archived, hasLength(1));
      expect(archived.first.id, 'r-2');
      expect(archived.first.archived, isTrue);
    });
  });

  group('soft delete', () {
    test('deleteNote hides note from getNotes, getActiveNotes, and getArchivedNotes', () async {
      await ds.createNote(_note(id: '1', archived: false));
      await ds.createNote(_note(id: '2', archived: true));

      await ds.deleteNote('1');
      await ds.deleteNote('2');

      expect(await ds.getNotes(), isEmpty);
      expect(await ds.getActiveNotes(), isEmpty);
      expect(await ds.getArchivedNotes(), isEmpty);
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
