import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/notes/application/controllers/note_controller.dart';
import 'package:nuvora/features/notes/data/datasources/note_local_datasource.dart';
import 'package:nuvora/features/notes/data/datasources/sqlite_note_datasource.dart';
import 'package:nuvora/features/notes/data/repositories/note_repository_impl.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/domain/repositories/note_repository.dart';

final noteDataSourceProvider = Provider<NoteDataSource>((ref) {
	return SQLiteNoteDataSource();
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
	return NoteRepositoryImpl(dataSource: ref.read(noteDataSourceProvider));
});

final noteControllerProvider = Provider<NoteController>((ref) {
	return NoteController(repository: ref.read(noteRepositoryProvider));
});

final noteSearchQueryProvider = StateProvider<String>((ref) {
	return '';
});

final notesProvider = FutureProvider<List<Note>>((ref) async {
	final query = ref.watch(noteSearchQueryProvider);
	if (query.trim().isEmpty) {
		return ref.read(noteControllerProvider).loadNotes();
	}

	return ref.read(noteControllerProvider).searchNotes(query);
});
