import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/database/sqlite_datasource_base.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/data/datasources/task_datasource.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SQLiteTaskDataSource extends SqliteDatasourceBase
    implements TaskDataSource {
  SQLiteTaskDataSource({
    super.databaseFactory,
    super.databasePath,
  });

  @override
  String get databaseName => 'nuvora_tasks.db';

  @override
  int get databaseVersion => 3;

  @override
  String get tableName => 'tasks';

  @override
  Future<void> onCreateSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
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
      'CREATE INDEX idx_tasks_created_at ON $tableName(created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_deleted_created ON $tableName(deleted_at, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_active_created ON $tableName(created_at DESC) WHERE deleted_at IS NULL',
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
        'ALTER TABLE $tableName ADD COLUMN updated_at INTEGER',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN deleted_at INTEGER',
      );
      await db.execute(
        'UPDATE $tableName SET updated_at = created_at WHERE updated_at IS NULL',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_deleted_created ON $tableName(deleted_at, created_at DESC)',
      );
    }

    if (oldVersion < 3) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_active_created ON $tableName(created_at DESC) WHERE deleted_at IS NULL',
      );
    }
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
    final database = await db;
    final rows = await database.query(
      tableName,
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    return rows.map(_taskFromMap).toList(growable: false);
  }

  @override
  Future<void> createTask(Task task) async {
    final database = await db;
    logger.debug('createTask', task.id);
    try {
      await database.insert(
        tableName,
        _taskToMap(task),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw TaskAlreadyExistsException(task.id);
      }
      rethrow;
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    final database = await db;
    logger.debug('updateTask', task.id);
    final taskToUpdate = task.copyWith(updatedAt: DateTime.now());
    final updated = await database.update(
      tableName,
      _taskToMap(taskToUpdate),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[task.id],
    );

    if (updated == 0) {
      throw TaskNotFoundException(task.id);
    }
  }

  @override
  Future<void> updateTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    final database = await db;
    final updated = await database.update(
      tableName,
      <String, Object?>{
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[taskId],
    );

    if (updated == 0) {
      throw TaskNotFoundException(taskId);
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final database = await db;
    logger.debug('deleteTask (soft)', taskId);
    final deleted = await database.update(
      tableName,
      <String, Object?>{
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[taskId],
    );

    if (deleted == 0) {
      throw TaskNotFoundException(taskId);
    }
  }
}