import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/notes/application/controllers/note_controller.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/domain/repositories/note_repository.dart';
import 'package:nuvora/features/notes/presentation/screens/create_note_screen.dart';
import 'package:nuvora/features/notes/presentation/screens/notes_screen.dart';

class _FakeRepo implements NoteRepository {
  final List<Note> notes;
  String? lastDeleted;
  String? lastSearch;
  bool throwDelete;
  bool throwUpdate;

  _FakeRepo(this.notes, {this.throwDelete = false, this.throwUpdate = false});

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
  Future<List<Note>> getActiveNotes() async =>
      notes.where((n) => !n.archived).toList();

  @override
  Future<List<Note>> getArchivedNotes() async =>
      notes.where((n) => n.archived).toList();

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
  Future<void> updateNote(Note note) async {
    if (throwUpdate) throw Exception('update fail');
    final index = notes.indexWhere((item) => item.id == note.id);
    if (index != -1) {
      notes[index] = note;
    }
  }
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
      notesProvider.overrideWith((_) async => notes.where((n) => !n.archived).toList()),
      activeNotesProvider.overrideWith((_) async => notes.where((n) => !n.archived).toList()),
      archivedNotesProvider.overrideWith((_) async => notes.where((n) => n.archived).toList()),
    ],
    child: const MaterialApp(home: NotesScreen()),
  );
}

Widget _appLive({required NoteController controller}) {
  return ProviderScope(
    overrides: [
      noteControllerProvider.overrideWithValue(controller),
    ],
    child: const MaterialApp(home: NotesScreen()),
  );
}

Future<void> _tapAction(WidgetTester tester, Finder finder) async {
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
  await tester.pumpAndSettle();
  await tester.tap(finder);
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

    await _tapAction(tester, find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();

    expect(repo.lastDeleted, 'del');
  });

  testWidgets('delete error shows snackbar', (tester) async {
    final repo = _FakeRepo([_note(id: 'del')], throwDelete: true);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_app(controller: controller, notes: repo.notes));
    await tester.pumpAndSettle();

    await _tapAction(tester, find.byIcon(Icons.close));
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

  testWidgets('tapping a note opens CreateNoteScreen in edit mode with prefilled fields',
    (tester) async {
    final repo = _FakeRepo([_note(id: 'edit-1', title: 'Alpha', content: 'Body')]);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateNoteScreen), findsOneWidget);
    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.text('Update Note'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('editing a note saves and shows updated values in NotesScreen',
    (tester) async {
    final original = _note(id: 'edit-2', title: 'Original title', content: 'Original body');
    final repo = _FakeRepo([original]);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Original title'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Updated title');
    await tester.enterText(find.byType(TextFormField).last, 'Updated body');
    await tester.tap(find.text('Update Note'));
    await tester.pumpAndSettle();

    expect(find.byType(NotesScreen), findsOneWidget);
    expect(find.text('Updated title'), findsOneWidget);
    expect(find.text('Updated body'), findsOneWidget);
    expect(find.text('Original title'), findsNothing);
  });

  testWidgets('pinning a note moves it to Pinned notes section', (tester) async {
    final note = _note(id: 'pin-1', title: 'Plan Trip', content: 'Pack clothes');
    final repo = _FakeRepo([note]);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Pinned notes'), findsNothing);
    expect(find.text('Plan Trip'), findsOneWidget);

    await _tapAction(tester, find.byIcon(Icons.push_pin_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Pinned notes'), findsOneWidget);
    expect(repo.notes.first.isPinned, isTrue);
  });

  testWidgets('unpinning a note moves it to Recent notes section', (tester) async {
    final pinnedNote = Note(
      id: 'pinned-1',
      title: 'Important Idea',
      content: 'Critical concept',
      createdAt: DateTime(2026, 6, 15),
      isPinned: true,
    );
    final repo = _FakeRepo([pinnedNote]);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Pinned notes'), findsOneWidget);
    expect(find.text('Important Idea'), findsOneWidget);

    await _tapAction(tester, find.byIcon(Icons.push_pin));
    await tester.pumpAndSettle();

    expect(find.text('Pinned notes'), findsNothing);
    expect(find.text('Recent notes'), findsOneWidget);
    expect(repo.notes.first.isPinned, isFalse);
  });

  testWidgets('pin error shows snackbar feedback', (tester) async {
    final note = _note(id: 'err-pin', title: 'Fail Note');
    final repo = _FakeRepo([note], throwUpdate: true);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    await _tapAction(tester, find.byIcon(Icons.push_pin_outlined));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not pin note'), findsOneWidget);
  });

  testWidgets('can switch between Active Notes and Archived tabs', (tester) async {
    final active = _note(id: 'act-1', title: 'Active Note');
    final archived = _note(id: 'arch-1', title: 'Archived Note').copyWith(archived: true);
    final repo = _FakeRepo([active, archived]);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Active Note'), findsOneWidget);
    expect(find.text('Archived Note'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('notes-filter-archived')));
    await tester.pumpAndSettle();

    expect(find.text('Archived Note'), findsOneWidget);
    expect(find.text('Active Note'), findsNothing);
  });

  testWidgets('shows empty state for Archived tab when no archived notes exist', (tester) async {
    final active = _note(id: 'act-1', title: 'Active Note');
    final repo = _FakeRepo([active]);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notes-filter-archived')));
    await tester.pumpAndSettle();

    expect(find.text('No archived notes'), findsOneWidget);
    expect(find.text('No archived notes yet'), findsOneWidget);
    expect(find.text('Create your first note'), findsNothing);
  });

  testWidgets('archives an active note via archive button', (tester) async {
    final note = _note(id: 'to-arch', title: 'Archive Me');
    final repo = _FakeRepo([note]);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Archive Me'), findsOneWidget);

    await _tapAction(tester, find.byIcon(Icons.archive_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Archive Me'), findsNothing);
    expect(repo.notes.first.archived, isTrue);

    await tester.tap(find.byKey(const ValueKey('notes-filter-archived')));
    await tester.pumpAndSettle();

    expect(find.text('Archive Me'), findsOneWidget);
  });

  testWidgets('unarchives an archived note via unarchive button', (tester) async {
    final note = _note(id: 'to-unarch', title: 'Unarchive Me').copyWith(archived: true);
    final repo = _FakeRepo([note]);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notes-filter-archived')));
    await tester.pumpAndSettle();

    expect(find.text('Unarchive Me'), findsOneWidget);

    await _tapAction(tester, find.byIcon(Icons.unarchive_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Unarchive Me'), findsNothing);
    expect(repo.notes.first.archived, isFalse);

    await tester.tap(find.byKey(const ValueKey('notes-filter-active')));
    await tester.pumpAndSettle();

    expect(find.text('Unarchive Me'), findsOneWidget);
  });

  testWidgets('archive error shows snackbar feedback', (tester) async {
    final note = _note(id: 'err-arch', title: 'Error Note');
    final repo = _FakeRepo([note], throwUpdate: true);
    final controller = NoteController(repository: repo);

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    await _tapAction(tester, find.byIcon(Icons.archive_outlined));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not archive note'), findsOneWidget);
  });

  testWidgets('search clear button clears input and resets search state', (tester) async {
    final notes = [_note(id: '1', title: 'Grocery list')];
    final controller = NoteController(repository: _FakeRepo(notes));

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Groc');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear search'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('Grocery list'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets('search with no matching notes shows empty state with clear search button', (tester) async {
    final notes = [_note(id: '1', title: 'Work items')];
    final controller = NoteController(repository: _FakeRepo(notes));

    await tester.pumpWidget(_appLive(controller: controller));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'NonexistentQuery');
    await tester.pumpAndSettle();

    expect(find.text('No notes found'), findsOneWidget);
    expect(find.text('Try adjusting your search'), findsOneWidget);
    expect(find.text('Clear search'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('Work items'), findsOneWidget);
  });

  testWidgets('error state displays title and retry button', (tester) async {
    final noteController = NoteController(repository: _FakeRepo([]));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteControllerProvider.overrideWithValue(noteController),
          activeNotesProvider.overrideWith((_) => Future.error('Database connection lost')),
        ],
        child: const MaterialApp(home: NotesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Error loading notes'), findsOneWidget);
    expect(find.text('Database connection lost'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
