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
  Future<List<Note>> getActiveNotes() async =>
      notes.where((n) => !n.archived).toList();

  @override
  Future<List<Note>> getArchivedNotes() async =>
      notes.where((n) => n.archived).toList();

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

Note _note({
  String id = 'n1',
  String title = 'Title',
  String content = 'Body',
  bool isPinned = false,
}) =>
    Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime(2026, 6, 15),
      isPinned: isPinned,
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

  test('togglePin toggles isPinned and delegates to repository', () async {
    final unpinned = _note(id: 'pin-1', isPinned: false);
    await controller.togglePin(unpinned);
    expect(repo.lastUpdated?.id, 'pin-1');
    expect(repo.lastUpdated?.isPinned, isTrue);

    final pinned = _note(id: 'pin-2', isPinned: true);
    await controller.togglePin(pinned);
    expect(repo.lastUpdated?.id, 'pin-2');
    expect(repo.lastUpdated?.isPinned, isFalse);
  });

  test('archiveNote sets archived true and delegates to repository', () async {
    final note = _note(id: 'arch-1', isPinned: true);
    await controller.archiveNote(note);
    expect(repo.lastUpdated?.id, 'arch-1');
    expect(repo.lastUpdated?.archived, isTrue);
    expect(repo.lastUpdated?.isPinned, isTrue);
  });

  test('unarchiveNote sets archived false and delegates to repository', () async {
    final note = _note(id: 'unarch-1', isPinned: false).copyWith(archived: true);
    await controller.unarchiveNote(note);
    expect(repo.lastUpdated?.id, 'unarch-1');
    expect(repo.lastUpdated?.archived, isFalse);
  });

  test('toggleArchive toggles archived state', () async {
    final active = _note(id: 't-1');
    await controller.toggleArchive(active);
    expect(repo.lastUpdated?.id, 't-1');
    expect(repo.lastUpdated?.archived, isTrue);

    final archived = _note(id: 't-2').copyWith(archived: true);
    await controller.toggleArchive(archived);
    expect(repo.lastUpdated?.id, 't-2');
    expect(repo.lastUpdated?.archived, isFalse);
  });

  test('loadActiveNotes returns non-archived notes', () async {
    repo.notes.add(_note(id: '3').copyWith(archived: true));
    final result = await controller.loadActiveNotes();
    expect(result, hasLength(2));
    expect(result.every((n) => !n.archived), isTrue);
  });

  test('loadArchivedNotes returns archived notes', () async {
    repo.notes.add(_note(id: '3').copyWith(archived: true));
    final result = await controller.loadArchivedNotes();
    expect(result, hasLength(1));
    expect(result.first.id, '3');
    expect(result.first.archived, isTrue);
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
