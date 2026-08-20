import 'package:nuvora/core/constants/reminder_type.dart';
import 'package:nuvora/core/database/sqlite_datasource_base.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/reminders/data/datasources/reminder_local_datasource.dart';
import 'package:nuvora/features/reminders/domain/entities/reminder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SQLiteReminderDataSource extends SqliteDatasourceBase
    implements ReminderDataSource {
  SQLiteReminderDataSource({
    super.databaseFactory,
    super.databasePath,
  });

  @override
  String get databaseName => 'nuvora_reminders.db';

  @override
  int get databaseVersion => 2;

  @override
  String get tableName => 'reminders';

  @override
  Future<void> onCreateSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        scheduled_at INTEGER NOT NULL,
        reminder_type TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        related_item_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_reminders_active_scheduled '
      'ON $tableName(scheduled_at ASC) WHERE deleted_at IS NULL AND is_active = 1',
    );
    await db.execute(
      'CREATE INDEX idx_reminders_deleted_scheduled '
      'ON $tableName(deleted_at, scheduled_at ASC)',
    );
    await db.execute(
      'CREATE INDEX idx_reminders_related_item '
      'ON $tableName(related_item_id, scheduled_at ASC)',
    );
  }

  @override
  Future<void> onUpgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN deleted_at INTEGER',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_reminders_active_scheduled '
        'ON $tableName(scheduled_at ASC) WHERE deleted_at IS NULL AND is_active = 1',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_reminders_deleted_scheduled '
        'ON $tableName(deleted_at, scheduled_at ASC)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_reminders_related_item '
        'ON $tableName(related_item_id, scheduled_at ASC)',
      );
    }
  }

  Map<String, Object?> _reminderToMap(Reminder reminder) {
    return <String, Object?>{
      'id': reminder.id,
      'title': reminder.title,
      'description': reminder.description,
      'scheduled_at': reminder.scheduledAt.millisecondsSinceEpoch,
      'reminder_type': reminder.type.name,
      'is_active': reminder.isActive ? 1 : 0,
      'related_item_id': reminder.relatedItemId,
      'created_at': reminder.createdAt.millisecondsSinceEpoch,
      'updated_at': reminder.updatedAt.millisecondsSinceEpoch,
      'archived': reminder.archived ? 1 : 0,
      'deleted_at': reminder.deletedAt?.millisecondsSinceEpoch,
    };
  }

  Reminder _reminderFromMap(Map<String, Object?> map) {
    return Reminder(
      id: map['id']! as String,
      title: map['title']! as String,
      description: map['description'] as String?,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(map['scheduled_at']! as int),
      type: ReminderType.values.byName(map['reminder_type']! as String),
      isActive: (map['is_active']! as int) == 1,
      relatedItemId: map['related_item_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      archived: (map['archived'] as int? ?? 0) == 1,
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['deleted_at']! as int),
    );
  }

  @override
  Future<List<Reminder>> getReminders({
    DateTime? from,
    DateTime? to,
  }) async {
    final database = await db;
    final clauses = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    if (from != null) {
      clauses.add('scheduled_at >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      clauses.add('scheduled_at <= ?');
      args.add(to.millisecondsSinceEpoch);
    }

    final rows = await database.query(
      tableName,
      where: clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(_reminderFromMap).toList(growable: false);
  }

  @override
  Future<Reminder?> getReminderById(String reminderId) async {
    final database = await db;
    final rows = await database.query(
      tableName,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[reminderId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _reminderFromMap(rows.first);
  }

  @override
  Future<void> createReminder(Reminder reminder) async {
    final database = await db;
    logger.debug('createReminder', reminder.id);
    try {
      await database.insert(
        tableName,
        _reminderToMap(reminder),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw ReminderAlreadyExistsException(reminder.id);
      }
      rethrow;
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    final database = await db;
    logger.debug('updateReminder', reminder.id);
    final normalized = reminder.copyWith(updatedAt: DateTime.now());
    final updated = await database.update(
      tableName,
      _reminderToMap(normalized),
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[reminder.id],
    );

    if (updated == 0) {
      throw ReminderNotFoundException(reminder.id);
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    final database = await db;
    logger.debug('deleteReminder (soft)', reminderId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final deleted = await database.update(
      tableName,
      <String, Object?>{
        'deleted_at': now,
        'updated_at': now,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[reminderId],
    );

    if (deleted == 0) {
      throw ReminderNotFoundException(reminderId);
    }
  }

  @override
  Future<void> setReminderActive({
    required String reminderId,
    required bool isActive,
  }) async {
    final database = await db;
    final updated = await database.update(
      tableName,
      <String, Object?>{
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[reminderId],
    );

    if (updated == 0) {
      throw ReminderNotFoundException(reminderId);
    }
  }
}