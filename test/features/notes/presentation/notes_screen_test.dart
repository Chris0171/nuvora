import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/notes/application/controllers/note_controller.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/domain/repositories/note_repository.dart';
import 'package:nuvora/features/notes/presentation/screens/notes_screen.dart';

class _FakeRepo implements NoteRepository {
  final List<Note> notes;
  String? lastDeleted;
  String? lastSearch;
  bool throwDelete;

  _FakeRepo(this.notes, {this.throwDelete = false});

  @override
  Future<void> createNote(Note note) async {}

  @override
  Future<void> deleteNote(String noteId) async {
    if (throwDelete) throw Exception('delete fail');
    lastDeleted = noteId;
  }

  @override
  Future<List<Note>> getNotes() async => List.unmodifiable(notes);

  @override
  Future<List<Note>> searchNotes(String query) async {
    lastSearch = query;
    return notes
        .where((n) =>
            n.title.toLowerCase().contains(query.toLowerCase()) ||
            n.content.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<void> updateNote(Note note) async {}
}

Note _note({String id = '1', String title = 'Alpha', String content = 'Body'}) =>
    Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime(2026, 6, 15),
      isPinned: false,
    );

Widget _app({required NoteController controller, required List<Note> notes}) {
  return ProviderScope(
    overrides: [
      noteControllerProvider.overrideWithValue(controller),
      notesProvider.overrideWith((_) async => notes),
    ],
    child: const MaterialApp(home: NotesScreen()),
  );
}

void main() {
  testWidgets('shows empty message', (tester) async {
    final controller = NoteController(repository: _FakeRepo([]));
    await tester.pumpWidget(_app(controller: controller, notes: []));
    await tester.pumpAndSettle();
    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('renders list with ValueKey', (tester) async {
    final notes = [_note(id: '1'), _note(id: '2', title: 'Beta')];
    final controller = NoteController(repository: _FakeRepo(notes));

    await tester.pumpWidget(_app(controller: controller, notes: notes));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('1')), findsOneWidget);
    expect(find.byKey(const ValueKey('2')), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('delete action calls controller', (tester) async {
    final repo = _FakeRepo([_note(id: 'del')]);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_app(controller: controller, notes: repo.notes));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();

    expect(repo.lastDeleted, 'del');
  });

  testWidgets('delete error shows snackbar', (tester) async {
    final repo = _FakeRepo([_note(id: 'del')], throwDelete: true);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_app(controller: controller, notes: repo.notes));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not delete note'), findsOneWidget);
  });

  testWidgets('search field is rendered', (tester) async {
    final controller = NoteController(repository: _FakeRepo([_note()]));
    await tester.pumpWidget(_app(controller: controller, notes: [_note()]));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search notes...'), findsOneWidget);
  });
}
