import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/notes/application/controllers/note_controller.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/domain/repositories/note_repository.dart';
import 'package:nuvora/features/notes/presentation/screens/create_note_screen.dart';

class _FakeRepo implements NoteRepository {
  bool throwCreate;
  bool throwUpdate;
  Note? lastCreated;
  Note? lastUpdated;
  Completer<void>? createCompleter;

  _FakeRepo({
    this.throwCreate = false,
    this.throwUpdate = false,
    this.createCompleter,
  });

  @override
  Future<void> createNote(Note note) async {
    if (createCompleter != null) await createCompleter!.future;
    if (throwCreate) throw Exception('create fail');
    lastCreated = note;
  }

  @override
  Future<void> deleteNote(String noteId) async {}

  @override
  Future<List<Note>> getNotes() async => [];

  @override
  Future<List<Note>> getActiveNotes() async => [];

  @override
  Future<List<Note>> getArchivedNotes() async => [];

  @override
  Future<List<Note>> searchNotes(String query) async => [];

  @override
  Future<void> updateNote(Note note) async {
    if (throwUpdate) throw Exception('update fail');
    lastUpdated = note;
  }
}

Widget _app(NoteController controller, {Note? initial}) {
  return ProviderScope(
    overrides: [
      noteControllerProvider.overrideWithValue(controller),
      notesProvider.overrideWith((_) async => []),
      activeNotesProvider.overrideWith((_) async => []),
      archivedNotesProvider.overrideWith((_) async => []),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CreateNoteScreen(initialNote: initial),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validates title and content required', (tester) async {
    final c = NoteController(repository: _FakeRepo());
    await tester.pumpWidget(_app(c));
    await _open(tester);

    await tester.tap(find.text('Create Note'));
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Content is required'), findsOneWidget);
  });

  testWidgets('creates note on valid form submit', (tester) async {
    final repo = _FakeRepo();
    final c = NoteController(repository: repo);
    await tester.pumpWidget(_app(c));
    await _open(tester);

    await tester.enterText(find.byType(TextFormField).first, 'My note');
    await tester.enterText(find.byType(TextFormField).last, 'My content');
    await tester.tap(find.text('Create Note'));
    await tester.pumpAndSettle();

    expect(repo.lastCreated, isNotNull);
    expect(repo.lastCreated!.title, 'My note');
    expect(repo.lastCreated!.content, 'My content');
  });

  testWidgets('updates note in edit mode', (tester) async {
    final repo = _FakeRepo();
    final c = NoteController(repository: repo);
    final initial = Note(
      id: 'n1',
      title: 'Old',
      content: 'Old content',
      createdAt: DateTime(2026, 6, 15),
      isPinned: false,
    );

    await tester.pumpWidget(_app(c, initial: initial));
    await _open(tester);

    await tester.enterText(find.byType(TextFormField).first, 'New title');
    await tester.enterText(find.byType(TextFormField).last, 'New body');
    await tester.tap(find.text('Update Note'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdated, isNotNull);
    expect(repo.lastUpdated!.id, 'n1');
    expect(repo.lastUpdated!.createdAt, initial.createdAt);
    expect(repo.lastUpdated!.isPinned, initial.isPinned);
    expect(repo.lastUpdated!.archived, initial.archived);
    expect(repo.lastUpdated!.deletedAt, initial.deletedAt);
    expect(repo.lastUpdated!.title, 'New title');
    expect(repo.lastUpdated!.content, 'New body');
  });

  testWidgets('edit mode preloads existing title and content', (tester) async {
    final repo = _FakeRepo();
    final c = NoteController(repository: repo);
    final initial = Note(
      id: 'n2',
      title: 'Existing title',
      content: 'Existing content',
      createdAt: DateTime(2026, 6, 15),
      isPinned: false,
    );

    await tester.pumpWidget(_app(c, initial: initial));
    await _open(tester);

    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.text('Update Note'), findsOneWidget);
    expect(find.text('Existing title'), findsOneWidget);
    expect(find.text('Existing content'), findsOneWidget);
  });

  testWidgets('shows snackbar on create failure', (tester) async {
    final c = NoteController(repository: _FakeRepo(throwCreate: true));
    await tester.pumpWidget(_app(c));
    await _open(tester);

    await tester.enterText(find.byType(TextFormField).first, 'My note');
    await tester.enterText(find.byType(TextFormField).last, 'My content');
    await tester.tap(find.text('Create Note'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not save note'), findsOneWidget);
  });

  testWidgets('shows snackbar on update failure in edit mode', (tester) async {
    final initial = Note(
      id: 'n3',
      title: 'Existing',
      content: 'Existing content',
      createdAt: DateTime(2026, 6, 15),
      isPinned: false,
    );
    final c = NoteController(repository: _FakeRepo(throwUpdate: true));
    await tester.pumpWidget(_app(c, initial: initial));
    await _open(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Updated');
    await tester.enterText(find.byType(TextFormField).last, 'Updated content');
    await tester.tap(find.text('Update Note'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not update note'), findsOneWidget);
    expect(find.byType(CreateNoteScreen), findsOneWidget);
  });

  testWidgets('disables button while save is in progress', (tester) async {
    final completer = Completer<void>();
    final c = NoteController(repository: _FakeRepo(createCompleter: completer));

    await tester.pumpWidget(_app(c));
    await _open(tester);

    await tester.enterText(find.byType(TextFormField).first, 'X');
    await tester.enterText(find.byType(TextFormField).last, 'Y');

    await tester.tap(find.text('Create Note'));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
    expect(button.onPressed, isNull);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('allows toggling isPinned during note creation and saves it', (tester) async {
    final repo = _FakeRepo();
    final c = NoteController(repository: repo);

    await tester.pumpWidget(_app(c));
    await _open(tester);

    expect(find.byTooltip('Pin note'), findsOneWidget);

    await tester.tap(find.byTooltip('Pin note'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Unpin note'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Pinned from start');
    await tester.enterText(find.byType(TextFormField).last, 'Content here');
    await tester.tap(find.text('Create Note'));
    await tester.pumpAndSettle();

    expect(repo.lastCreated, isNotNull);
    expect(repo.lastCreated!.isPinned, isTrue);
  });

  testWidgets('allows archiving and unarchiving in edit mode and preserves isPinned', (tester) async {
    final repo = _FakeRepo();
    final c = NoteController(repository: repo);
    final initial = Note(
      id: 'arch-edit',
      title: 'Active note',
      content: 'Some details',
      createdAt: DateTime(2026, 6, 15),
      isPinned: true,
      archived: false,
    );

    await tester.pumpWidget(_app(c, initial: initial));
    await _open(tester);

    expect(find.byTooltip('Archive note'), findsOneWidget);

    await tester.tap(find.byTooltip('Archive note'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Unarchive note'), findsOneWidget);

    await tester.tap(find.text('Update Note'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdated, isNotNull);
    expect(repo.lastUpdated!.id, 'arch-edit');
    expect(repo.lastUpdated!.archived, isTrue);
    expect(repo.lastUpdated!.isPinned, isTrue);
  });
}
