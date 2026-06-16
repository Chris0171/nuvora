import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/domain/repositories/note_repository.dart';

class NoteController {
	NoteController({required this.repository});

	final NoteRepository repository;

	Future<List<Note>> loadNotes() async {
		return repository.getNotes();
	}

	Future<List<Note>> searchNotes(String query) async {
		return repository.searchNotes(query);
	}

	Future<void> createNote(Note note) async {
		await repository.createNote(note);
	}

	Future<void> updateNote(Note note) async {
		await repository.updateNote(note);
	}

	Future<void> deleteNote(String noteId) async {
		await repository.deleteNote(noteId);
	}
}
