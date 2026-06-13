import 'dart:io';

import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/data/datasources/task_datasource.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SQLiteTaskDataSource implements TaskDataSource {
  static const String _databaseName = 'nuvora_tasks.db';
  static const int _databaseVersion = 2;
  static const String _tableName = 'tasks';

  Database? _database;
  DatabaseFactory? _databaseFactory;

  Future<DatabaseFactory> get _resolvedFactory async {
    if (_databaseFactory != null) {
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
    if (_database != null) {
      return _database!;
    }

    final factory = await _resolvedFactory;
    final dbPath = await factory.getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    _database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tableName (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              due_date INTEGER,
              is_completed INTEGER NOT NULL,
              priority TEXT NOT NULL,
              category_id TEXT,
              repeat_type TEXT NOT NULL,
              archived INTEGER NOT NULL DEFAULT 0,
              deleted_at INTEGER
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_tasks_created_at ON $_tableName(created_at DESC)',
          );
          await db.execute(
            'CREATE INDEX idx_tasks_deleted_created ON $_tableName(deleted_at, created_at DESC)',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN updated_at INTEGER',
            );
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute(
              'ALTER TABLE $_tableName ADD COLUMN deleted_at INTEGER',
            );
            await db.execute(
              'UPDATE $_tableName SET updated_at = created_at WHERE updated_at IS NULL',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_tasks_deleted_created ON $_tableName(deleted_at, created_at DESC)',
            );
          }
        },
      ),
    );

    return _database!;
  }

  Map<String, Object?> _taskToMap(Task task) {
    return <String, Object?>{
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'created_at': task.createdAt.millisecondsSinceEpoch,
      'updated_at': task.updatedAt.millisecondsSinceEpoch,
      'due_date': task.dueDate?.millisecondsSinceEpoch,
      'is_completed': task.isCompleted ? 1 : 0,
      'priority': task.priority.name,
      'category_id': task.categoryId,
      'repeat_type': task.repeatType.name,
      'archived': task.archived ? 1 : 0,
      'deleted_at': task.deletedAt?.millisecondsSinceEpoch,
    };
  }

  Task _taskFromMap(Map<String, Object?> map) {
    return Task(
      id: map['id']! as String,
      title: map['title']! as String,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
        updatedAt: map['updated_at'] == null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int)
          : DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      dueDate: map['due_date'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['due_date']! as int),
      isCompleted: (map['is_completed']! as int) == 1,
      priority: Priority.values.byName(map['priority']! as String),
      categoryId: map['category_id'] as String?,
      repeatType: RepeatType.values.byName(map['repeat_type']! as String),
        archived: (map['archived'] as int? ?? 0) == 1,
        deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['deleted_at']! as int),
    );
  }

  @override
  Future<List<Task>> getTasks() async {
    final db = await _db;
    final rows = await db.query(
      _tableName,
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    return rows.map(_taskFromMap).toList(growable: false);
  }

  @override
  Future<void> createTask(Task task) async {
    final db = await _db;
    await db.insert(
      _tableName,
      _taskToMap(task),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateTask(Task task) async {
    final db = await _db;
    final taskToUpdate = task.copyWith(updatedAt: DateTime.now());
    final updated = await db.update(
      _tableName,
      _taskToMap(taskToUpdate),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[task.id],
    );

    if (updated == 0) {
      throw StateError('Task not found for update: ${task.id}');
    }
  }

  @override
  Future<void> updateTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    final db = await _db;
    final updated = await db.update(
      _tableName,
      <String, Object?>{
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[taskId],
    );

    if (updated == 0) {
      throw StateError('Task not found for update: $taskId');
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final db = await _db;
    final deleted = await db.update(
      _tableName,
      <String, Object?>{
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[taskId],
    );

    if (deleted == 0) {
      throw StateError('Task not found for delete: $taskId');
    }
  }
}