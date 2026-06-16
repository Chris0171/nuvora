import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/core/utils/app_logger.dart';
import 'package:nuvora/features/notes/data/datasources/note_local_datasource.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/domain/repositories/note_repository.dart';
import 'package:uuid/uuid.dart';

class NoteRepositoryImpl implements NoteRepository {
	NoteRepositoryImpl({required this.dataSource});

	final NoteDataSource dataSource;
	static const Uuid _uuid = Uuid();
	static final AppLogger _log = AppLogger('NoteRepository');

	@override
	Future<List<Note>> getNotes() async {
		return dataSource.getNotes();
	}

	@override
	Future<List<Note>> searchNotes(String query) async {
		return dataSource.searchNotes(query);
	}

	@override
	Future<void> createNote(Note note) async {
		final DateTime now = DateTime.now();
		final bool replaceId = _shouldReplaceId(note.id);
		final String newId = replaceId ? _uuid.v4() : note.id;

		if (replaceId) {
			_log.debug('Replaced legacy id with UUID v4', newId);
		}

		final Note normalized = note.copyWith(
			id: newId,
			updatedAt: now,
		);
		_validate(normalized);

		await dataSource.createNote(normalized);
		_log.debug('Note created', newId);
	}

	@override
	Future<void> updateNote(Note note) async {
		final Note normalized = note.copyWith(updatedAt: DateTime.now());
		_validate(normalized);
		await dataSource.updateNote(normalized);
		_log.debug('Note updated', note.id);
	}

	@override
	Future<void> deleteNote(String noteId) async {
		await dataSource.deleteNote(noteId);
		_log.debug('Note soft-deleted', noteId);
	}

	void _validate(Note note) {
		if (note.title.trim().isEmpty) {
			throw const NoteValidationException('Title cannot be empty');
		}
		if (note.content.trim().isEmpty) {
			throw const NoteValidationException('Content cannot be empty');
		}
	}

	bool _shouldReplaceId(String id) {
		if (id.trim().isEmpty) {
			return true;
		}

		return RegExp(r'^\d{10,}$').hasMatch(id);
	}
}
