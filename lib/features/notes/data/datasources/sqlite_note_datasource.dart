import 'package:nuvora/core/database/sqlite_datasource_base.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/notes/data/datasources/note_local_datasource.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SQLiteNoteDataSource extends SqliteDatasourceBase
    implements NoteDataSource {
  SQLiteNoteDataSource({
    super.databaseFactory,
    super.databasePath,
  });

  @override
  String get databaseName => 'nuvora_notes.db';

  @override
  int get databaseVersion => 2;

  @override
  String get tableName => 'notes';

  @override
  Future<void> onCreateSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_pinned INTEGER NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_notes_active_updated ON $tableName(updated_at DESC) WHERE deleted_at IS NULL',
    );
  }

  @override
  Future<void> onUpgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN deleted_at INTEGER',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_active_updated ON $tableName(updated_at DESC) WHERE deleted_at IS NULL',
      );
    }
  }

  Map<String, Object?> _noteToMap(Note note) {
    return <String, Object?>{
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'created_at': note.createdAt.millisecondsSinceEpoch,
      'updated_at': note.updatedAt.millisecondsSinceEpoch,
      'is_pinned': note.isPinned ? 1 : 0,
      'archived': note.archived ? 1 : 0,
      'deleted_at': note.deletedAt?.millisecondsSinceEpoch,
    };
  }

  Note _noteFromMap(Map<String, Object?> map) {
    return Note(
      id: map['id']! as String,
      title: map['title']! as String,
      content: map['content']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      isPinned: (map['is_pinned']! as int) == 1,
      archived: (map['archived'] as int? ?? 0) == 1,
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['deleted_at']! as int),
    );
  }

  @override
  Future<List<Note>> getNotes() async {
    final database = await db;
    final rows = await database.query(
      tableName,
      where: 'deleted_at IS NULL',
      orderBy: 'updated_at DESC',
    );
    return rows.map(_noteFromMap).toList(growable: false);
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final String cleanedQuery = query.trim();
    if (cleanedQuery.isEmpty) return getNotes();

    final database = await db;
    final String pattern = '%$cleanedQuery%';
    final rows = await database.query(
      tableName,
      where:
          'deleted_at IS NULL AND (title LIKE ? COLLATE NOCASE OR content LIKE ? COLLATE NOCASE)',
      whereArgs: <Object?>[pattern, pattern],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_noteFromMap).toList(growable: false);
  }

  @override
  Future<void> createNote(Note note) async {
    final database = await db;
    logger.debug('createNote', note.id);
    try {
      await database.insert(
        tableName,
        _noteToMap(note),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw NoteAlreadyExistsException(note.id);
      }
      rethrow;
    }
  }

  @override
  Future<void> updateNote(Note note) async {
    final database = await db;
    logger.debug('updateNote', note.id);
    final Note noteToUpdate = note.copyWith(updatedAt: DateTime.now());

    final int updated = await database.update(
      tableName,
      _noteToMap(noteToUpdate),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[note.id],
    );

    if (updated == 0) throw NoteNotFoundException(note.id);
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final database = await db;
    logger.debug('deleteNote (soft)', noteId);

    final int deleted = await database.update(
      tableName,
      <String, Object?>{
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[noteId],
    );

    if (deleted == 0) throw NoteNotFoundException(noteId);
  }
}
