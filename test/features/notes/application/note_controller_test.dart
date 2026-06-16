import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/notes/application/controllers/note_controller.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/domain/repositories/note_repository.dart';

class _FakeNoteRepository implements NoteRepository {
  final List<Note> notes;
  String? lastDeletedId;
  String? lastSearchQuery;
  Note? lastCreated;
  Note? lastUpdated;

  Exception? throwOnCreate;
  Exception? throwOnUpdate;
  Exception? throwOnDelete;

  _FakeNoteRepository({List<Note>? notes}) : notes = notes ?? [];

  @override
  Future<void> createNote(Note note) async {
    if (throwOnCreate != null) throw throwOnCreate!;
    lastCreated = note;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    if (throwOnDelete != null) throw throwOnDelete!;
    lastDeletedId = noteId;
  }

  @override
  Future<List<Note>> getNotes() async => List.unmodifiable(notes);

  @override
  Future<List<Note>> searchNotes(String query) async {
    lastSearchQuery = query;
    return notes
        .where((n) =>
            n.title.toLowerCase().contains(query.toLowerCase()) ||
            n.content.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<void> updateNote(Note note) async {
    if (throwOnUpdate != null) throw throwOnUpdate!;
    lastUpdated = note;
  }
}

Note _note({String id = 'n1', String title = 'Title', String content = 'Body'}) =>
    Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime(2026, 6, 15),
      isPinned: false,
    );

void main() {
  late _FakeNoteRepository repo;
  late NoteController controller;

  setUp(() {
    repo = _FakeNoteRepository(notes: [
      _note(id: '1', title: 'Alpha', content: 'Work items'),
      _note(id: '2', title: 'Beta', content: 'Personal notes'),
    ]);
    controller = NoteController(repository: repo);
  });

  test('loadNotes returns repository data', () async {
    final result = await controller.loadNotes();
    expect(result, hasLength(2));
  });

  test('searchNotes delegates query', () async {
    final result = await controller.searchNotes('alpha');
    expect(repo.lastSearchQuery, 'alpha');
    expect(result, hasLength(1));
  });

  test('createNote delegates', () async {
    final n = _note(id: '3');
    await controller.createNote(n);
    expect(repo.lastCreated, isNotNull);
    expect(repo.lastCreated!.id, '3');
  });

  test('updateNote delegates', () async {
    final n = _note(id: '4');
    await controller.updateNote(n);
    expect(repo.lastUpdated?.id, '4');
  });

  test('deleteNote delegates id', () async {
    await controller.deleteNote('to-delete');
    expect(repo.lastDeletedId, 'to-delete');
  });

  test('propagates create errors', () async {
    repo.throwOnCreate = Exception('fail create');
    await expectLater(controller.createNote(_note()), throwsException);
  });

  test('propagates update errors', () async {
    repo.throwOnUpdate = Exception('fail update');
    await expectLater(controller.updateNote(_note()), throwsException);
  });

  test('propagates delete errors', () async {
    repo.throwOnDelete = Exception('fail delete');
    await expectLater(controller.deleteNote('x'), throwsException);
  });
}
