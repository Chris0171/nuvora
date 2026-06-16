import 'dart:io';

import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/core/utils/app_logger.dart';
import 'package:nuvora/features/notes/data/datasources/note_local_datasource.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SQLiteNoteDataSource implements NoteDataSource {
  SQLiteNoteDataSource({
    DatabaseFactory? databaseFactory,
    String? databasePath,
  })  : _injectedFactory = databaseFactory,
        _injectedPath = databasePath;

  static const String _databaseName = 'nuvora_notes.db';
  static const int _databaseVersion = 2;
  static const String _tableName = 'notes';

  final DatabaseFactory? _injectedFactory;
  final String? _injectedPath;

  Database? _database;
  Future<Database>? _openingDatabase;
  DatabaseFactory? _databaseFactory;
  static final AppLogger _log = AppLogger('SQLiteNoteDataSource');

  Future<DatabaseFactory> get _resolvedFactory async {
    if (_databaseFactory != null) return _databaseFactory!;

    if (_injectedFactory != null) {
      _databaseFactory = _injectedFactory;
      return _databaseFactory!;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      _databaseFactory = databaseFactory;
    } else {
      sqfliteFfiInit();
      _databaseFactory = databaseFactoryFfi;
    }

    return _databaseFactory!;
  }

  Future<Database> get _db async {
    if (_database != null) return _database!;
    if (_openingDatabase != null) return _openingDatabase!;

    _openingDatabase = _openDatabase();
    try {
      _database = await _openingDatabase!;
      return _database!;
    } finally {
      _openingDatabase = null;
    }
  }

  Future<Database> _openDatabase() async {
    final factory = await _resolvedFactory;
    final path =
        _injectedPath ?? p.join(await factory.getDatabasesPath(), _databaseName);

    _log.info('Opening database', path);
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tableName (
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
            'CREATE INDEX idx_notes_active_updated ON $_tableName(updated_at DESC) WHERE deleted_at IS NULL',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN deleted_at INTEGER',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_notes_active_updated ON $_tableName(updated_at DESC) WHERE deleted_at IS NULL',
            );
          }
        },
      ),
    );
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
    final db = await _db;
    final rows = await db.query(
      _tableName,
      where: 'deleted_at IS NULL',
      orderBy: 'updated_at DESC',
    );
    return rows.map(_noteFromMap).toList(growable: false);
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final String cleanedQuery = query.trim();
    if (cleanedQuery.isEmpty) return getNotes();

    final db = await _db;
    final String pattern = '%$cleanedQuery%';
    final rows = await db.query(
      _tableName,
      where:
          'deleted_at IS NULL AND (title LIKE ? COLLATE NOCASE OR content LIKE ? COLLATE NOCASE)',
      whereArgs: <Object?>[pattern, pattern],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_noteFromMap).toList(growable: false);
  }

  @override
  Future<void> createNote(Note note) async {
    final db = await _db;
    _log.debug('createNote', note.id);
    try {
      await db.insert(
        _tableName,
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
    final db = await _db;
    _log.debug('updateNote', note.id);
    final Note noteToUpdate = note.copyWith(updatedAt: DateTime.now());

    final int updated = await db.update(
      _tableName,
      _noteToMap(noteToUpdate),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[note.id],
    );

    if (updated == 0) throw NoteNotFoundException(note.id);
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final db = await _db;
    _log.debug('deleteNote (soft)', noteId);

    final int deleted = await db.update(
      _tableName,
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
