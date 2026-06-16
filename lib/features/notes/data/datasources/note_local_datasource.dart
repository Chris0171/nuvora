import 'package:nuvora/features/notes/domain/entities/note.dart';

abstract class NoteDataSource {
	Future<List<Note>> getNotes();
	Future<List<Note>> searchNotes(String query);
	Future<void> createNote(Note note);
	Future<void> updateNote(Note note);
	Future<void> deleteNote(String noteId);
}
