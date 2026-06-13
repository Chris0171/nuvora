import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/notes/application/controllers/note_controller.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';

final noteControllerProvider = Provider<NoteController>((ref) {
	return const NoteController();
});

final notesProvider = FutureProvider<List<Note>>((ref) async {
	return ref.read(noteControllerProvider).loadNotes();
});
