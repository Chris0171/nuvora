import 'dart:io';

import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TaskLocalDataSource {
	static const String _databaseName = 'nuvora_tasks.db';
	static const int _databaseVersion = 1;
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
							due_date INTEGER,
							is_completed INTEGER NOT NULL,
							priority TEXT NOT NULL,
							category_id TEXT,
							repeat_type TEXT NOT NULL
						)
					''');
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
			'due_date': task.dueDate?.millisecondsSinceEpoch,
			'is_completed': task.isCompleted ? 1 : 0,
			'priority': task.priority.name,
			'category_id': task.categoryId,
			'repeat_type': task.repeatType.name,
		};
	}

	Task _taskFromMap(Map<String, Object?> map) {
		return Task(
			id: map['id']! as String,
			title: map['title']! as String,
			description: map['description'] as String?,
			createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
			dueDate: map['due_date'] == null
					? null
					: DateTime.fromMillisecondsSinceEpoch(map['due_date']! as int),
			isCompleted: (map['is_completed']! as int) == 1,
			priority: Priority.values.byName(map['priority']! as String),
			categoryId: map['category_id'] as String?,
			repeatType: RepeatType.values.byName(map['repeat_type']! as String),
		);
	}

	Future<List<Task>> getTasks() async {
		final db = await _db;
		final rows = await db.query(_tableName, orderBy: 'created_at DESC');
		return rows.map(_taskFromMap).toList(growable: false);
	}

	Future<void> createTask(Task task) async {
		final db = await _db;
		await db.insert(
			_tableName,
			_taskToMap(task),
			conflictAlgorithm: ConflictAlgorithm.abort,
		);
	}

	Future<void> updateTask(Task task) async {
		final db = await _db;
		final updated = await db.update(
			_tableName,
			_taskToMap(task),
			where: 'id = ?',
			whereArgs: <Object?>[task.id],
		);

		if (updated == 0) {
			throw StateError('Task not found for update: ${task.id}');
		}
	}

	Future<void> deleteTask(String taskId) async {
		final db = await _db;
		await db.delete(
			_tableName,
			where: 'id = ?',
			whereArgs: <Object?>[taskId],
		);
	}
}
