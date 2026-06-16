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
  Note? lastCreated;
  Note? lastUpdated;
  Completer<void>? createCompleter;

  _FakeRepo({
    this.throwCreate = false,
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
  Future<List<Note>> searchNotes(String query) async => [];

  @override
  Future<void> updateNote(Note note) async {
    lastUpdated = note;
  }
}

Widget _app(NoteController controller, {Note? initial}) {
  return ProviderScope(
    overrides: [
      noteControllerProvider.overrideWithValue(controller),
      notesProvider.overrideWith((_) async => []),
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

    await tester.tap(find.text('Guardar nota'));
    await tester.pumpAndSettle();

    expect(find.text('El titulo es obligatorio'), findsOneWidget);
    expect(find.text('El contenido es obligatorio'), findsOneWidget);
  });

  testWidgets('creates note on valid form submit', (tester) async {
    final repo = _FakeRepo();
    final c = NoteController(repository: repo);
    await tester.pumpWidget(_app(c));
    await _open(tester);

    await tester.enterText(find.byType(TextFormField).first, 'My note');
    await tester.enterText(find.byType(TextFormField).last, 'My content');
    await tester.tap(find.text('Guardar nota'));
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
    await tester.tap(find.text('Actualizar nota'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdated, isNotNull);
    expect(repo.lastUpdated!.id, 'n1');
    expect(repo.lastUpdated!.title, 'New title');
  });

  testWidgets('shows snackbar on create failure', (tester) async {
    final c = NoteController(repository: _FakeRepo(throwCreate: true));
    await tester.pumpWidget(_app(c));
    await _open(tester);

    await tester.enterText(find.byType(TextFormField).first, 'My note');
    await tester.enterText(find.byType(TextFormField).last, 'My content');
    await tester.tap(find.text('Guardar nota'));
    await tester.pump();
    await tester.pump();

    expect(find.text('No se pudo guardar la nota.'), findsOneWidget);
  });

  testWidgets('disables button while save is in progress', (tester) async {
    final completer = Completer<void>();
    final c = NoteController(repository: _FakeRepo(createCompleter: completer));

    await tester.pumpWidget(_app(c));
    await _open(tester);

    await tester.enterText(find.byType(TextFormField).first, 'X');
    await tester.enterText(find.byType(TextFormField).last, 'Y');

    await tester.tap(find.text('Guardar nota'));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
    expect(button.onPressed, isNull);

    completer.complete();
    await tester.pumpAndSettle();
  });
}
