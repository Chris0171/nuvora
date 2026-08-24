import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/notes/data/datasources/note_local_datasource.dart';
import 'package:nuvora/features/notes/data/repositories/note_repository_impl.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';

class _FakeNoteDataSource implements NoteDataSource {
  final List<Note> notes;
  Note? lastCreated;
  Note? lastUpdated;
  String? lastDeleted;
  String? lastSearch;
  int createCalls = 0;
  int updateCalls = 0;

  _FakeNoteDataSource({List<Note>? notes}) : notes = notes ?? [];

  @override
  Future<void> createNote(Note note) async {
    createCalls += 1;
    lastCreated = note;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    lastDeleted = noteId;
  }

  @override
  Future<List<Note>> getNotes() async => List.unmodifiable(notes);

  @override
  Future<List<Note>> searchNotes(String query) async {
    lastSearch = query;
    return notes;
  }

  @override
  Future<void> updateNote(Note note) async {
    updateCalls += 1;
    lastUpdated = note;
  }
}

final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

Note _note({
  String id = 'legacy',
  String title = 'Title',
  String content = 'Body',
}) =>
    Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime(2026, 6, 15),
      isPinned: false,
    );

void main() {
  late _FakeNoteDataSource ds;
  late NoteRepositoryImpl repo;

  setUp(() {
    ds = _FakeNoteDataSource(notes: [_note(id: '1')]);
    repo = NoteRepositoryImpl(dataSource: ds);
  });

  test('getNotes delegates datasource', () async {
    final result = await repo.getNotes();
    expect(result, hasLength(1));
  });

  test('searchNotes delegates datasource', () async {
    await repo.searchNotes('hello');
    expect(ds.lastSearch, 'hello');
  });

  test('createNote replaces legacy id with uuid', () async {
    await repo.createNote(_note(id: '1718351234567890'));
    expect(ds.lastCreated, isNotNull);
    expect(ds.lastCreated!.id, matches(_uuidRegex));
  });

  test('createNote keeps valid id', () async {
    const id = 'custom-id-1';
    await repo.createNote(_note(id: id));
    expect(ds.lastCreated!.id, id);
  });

  test('createNote validates non-empty title', () async {
    await expectLater(
      repo.createNote(_note(title: '  ')),
      throwsA(isA<NoteValidationException>()),
    );
  });

  test('createNote validates non-empty content', () async {
    await expectLater(
      repo.createNote(_note(content: ' ')),
      throwsA(isA<NoteValidationException>()),
    );
  });

  test('updateNote stamps updatedAt', () async {
    final original = _note(id: 'u1');
    await repo.updateNote(original);
    expect(ds.lastUpdated, isNotNull);
    expect(
      ds.lastUpdated!.updatedAt.isAtSameMomentAs(original.updatedAt),
      isFalse,
    );
  });

  test('updateNote validates content', () async {
    await expectLater(
      repo.updateNote(_note(id: 'x', content: '')),
      throwsA(isA<NoteValidationException>()),
    );
  });

  test('updateNote preserves id and createdAt', () async {
    final original = _note(id: 'persist-id');

    await repo.updateNote(original.copyWith(title: 'Updated', content: 'Updated body'));

    expect(ds.lastUpdated, isNotNull);
    expect(ds.lastUpdated!.id, 'persist-id');
    expect(ds.lastUpdated!.createdAt, original.createdAt);
  });

  test('updateNote keeps non-form fields untouched', () async {
    final original = _note(id: 'flags').copyWith(
      isPinned: true,
      archived: true,
      deletedAt: DateTime(2026, 6, 20),
    );

    await repo.updateNote(original.copyWith(title: 'Changed', content: 'Changed body'));

    expect(ds.lastUpdated, isNotNull);
    expect(ds.lastUpdated!.isPinned, isTrue);
    expect(ds.lastUpdated!.archived, isTrue);
    expect(ds.lastUpdated!.deletedAt, original.deletedAt);
  });

  test('updateNote does not create a new note', () async {
    await repo.updateNote(_note(id: 'no-create', title: 'A', content: 'B'));
    expect(ds.updateCalls, 1);
    expect(ds.createCalls, 0);
  });

  test('deleteNote delegates id', () async {
    await repo.deleteNote('del-1');
    expect(ds.lastDeleted, 'del-1');
  });
}
