import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/reminder_type.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/reminders/data/datasources/sqlite_reminder_datasource.dart';
import 'package:nuvora/features/reminders/domain/entities/reminder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _dbCounter = 0;
int _seq = 0;

SQLiteReminderDataSource _buildDS() {
  final path = 'file:reminder_test_${_dbCounter++}?mode=memory&cache=shared';
  return SQLiteReminderDataSource(
    databaseFactory: databaseFactoryFfi,
    databasePath: path,
  );
}

Reminder _reminder({
  String? id,
  String title = 'Reminder',
  String? description,
  DateTime? scheduledAt,
  ReminderType type = ReminderType.task,
  bool isActive = true,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool archived = false,
  String? relatedItemId,
}) {
  final now = createdAt ?? DateTime.now();
  return Reminder(
    id: id ?? 'rem-${_seq++}',
    title: title,
    description: description,
    scheduledAt: scheduledAt ?? now.add(const Duration(hours: 1)),
    type: type,
    isActive: isActive,
    createdAt: now,
    updatedAt: updatedAt,
    archived: archived,
    relatedItemId: relatedItemId,
  );
}

Future<SQLiteReminderDataSource> _buildMigratedDS() async {
  final path = 'reminder_migration_${_dbCounter++}.db';
  await databaseFactoryFfi.deleteDatabase(path);
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE reminders (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            scheduled_at INTEGER NOT NULL,
            reminder_type TEXT NOT NULL,
            is_active INTEGER NOT NULL,
            related_item_id TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    ),
  );

  final now = DateTime(2026, 8, 20, 10).millisecondsSinceEpoch;
  await db.insert('reminders', {
    'id': 'legacy-rem',
    'title': 'Legacy reminder',
    'description': 'v1 row',
    'scheduled_at': now + 3600000,
    'reminder_type': 'task',
    'is_active': 1,
    'related_item_id': 'task-1',
    'created_at': now,
    'updated_at': now,
  });
  await db.close();

  return SQLiteReminderDataSource(
    databaseFactory: databaseFactoryFfi,
    databasePath: path,
  );
}

void main() {
  setUpAll(sqfliteFfiInit);

  late SQLiteReminderDataSource ds;

  setUp(() {
    _seq = 0;
    ds = _buildDS();
  });

  group('createReminder + getReminders', () {
    test('round-trip persists reminder', () async {
      final reminder = _reminder(title: 'Dentist', description: 'Bring insurance');
      await ds.createReminder(reminder);

      final reminders = await ds.getReminders();
      expect(reminders, hasLength(1));
      expect(reminders.first.title, 'Dentist');
      expect(reminders.first.description, 'Bring insurance');
    });

    test('returns reminders sorted by scheduled_at ASC', () async {
      final base = DateTime(2026, 8, 20, 8, 0);
      await ds.createReminder(_reminder(id: 'c', scheduledAt: base.add(const Duration(hours: 3))));
      await ds.createReminder(_reminder(id: 'a', scheduledAt: base.add(const Duration(hours: 1))));
      await ds.createReminder(_reminder(id: 'b', scheduledAt: base.add(const Duration(hours: 2))));

      final reminders = await ds.getReminders();
      expect(reminders[0].id, 'a');
      expect(reminders[1].id, 'b');
      expect(reminders[2].id, 'c');
    });

    test('duplicate id throws ReminderAlreadyExistsException', () async {
      await ds.createReminder(_reminder(id: 'dup'));
      await expectLater(
        ds.createReminder(_reminder(id: 'dup')),
        throwsA(isA<ReminderAlreadyExistsException>()),
      );
    });
  });

  group('getReminderById', () {
    test('returns reminder when it exists', () async {
      await ds.createReminder(_reminder(id: 'lookup'));
      final reminder = await ds.getReminderById('lookup');
      expect(reminder?.id, 'lookup');
    });

    test('returns null for unknown id', () async {
      expect(await ds.getReminderById('missing'), isNull);
    });
  });

  group('updateReminder', () {
    test('updates title and description', () async {
      final reminder = _reminder(id: 'upd-1', title: 'Old');
      await ds.createReminder(reminder);
      await ds.updateReminder(
        reminder.copyWith(title: 'New', description: 'Updated body'),
      );

      final result = await ds.getReminderById('upd-1');
      expect(result?.title, 'New');
      expect(result?.description, 'Updated body');
    });

    test('throws ReminderNotFoundException for unknown id', () async {
      await expectLater(
        ds.updateReminder(_reminder(id: 'ghost')),
        throwsA(isA<ReminderNotFoundException>()),
      );
    });
  });

  group('soft delete', () {
    test('deleteReminder hides reminder from getReminders', () async {
      await ds.createReminder(_reminder(id: 'soft-1'));
      await ds.deleteReminder('soft-1');

      expect(await ds.getReminders(), isEmpty);
    });

    test('deleteReminder sets deleted_at and updated_at', () async {
      await ds.createReminder(_reminder(id: 'soft-2'));
      await ds.deleteReminder('soft-2');

      final database = await ds.db;
      final rows = await database.query(
        ds.tableName,
        where: 'id = ?',
        whereArgs: <Object?>['soft-2'],
      );

      expect(rows.single['deleted_at'], isNotNull);
      expect(rows.single['updated_at'], isNotNull);
    });

    test('double delete throws ReminderNotFoundException', () async {
      await ds.createReminder(_reminder(id: 'soft-3'));
      await ds.deleteReminder('soft-3');
      await expectLater(
        ds.deleteReminder('soft-3'),
        throwsA(isA<ReminderNotFoundException>()),
      );
    });
  });

  group('setReminderActive', () {
    test('deactivates existing reminder', () async {
      await ds.createReminder(_reminder(id: 'active-1', isActive: true));
      await ds.setReminderActive(reminderId: 'active-1', isActive: false);

      final reminder = await ds.getReminderById('active-1');
      expect(reminder?.isActive, isFalse);
    });

    test('reactivates existing reminder', () async {
      await ds.createReminder(_reminder(id: 'active-2', isActive: false));
      await ds.setReminderActive(reminderId: 'active-2', isActive: true);

      final reminder = await ds.getReminderById('active-2');
      expect(reminder?.isActive, isTrue);
    });

    test('throws ReminderNotFoundException for unknown id', () async {
      await expectLater(
        ds.setReminderActive(reminderId: 'ghost', isActive: true),
        throwsA(isA<ReminderNotFoundException>()),
      );
    });
  });

  group('date queries', () {
    test('filters reminders by range', () async {
      final base = DateTime(2026, 8, 20, 8, 0);
      await ds.createReminder(_reminder(id: 'r1', scheduledAt: base));
      await ds.createReminder(_reminder(id: 'r2', scheduledAt: base.add(const Duration(days: 1))));
      await ds.createReminder(_reminder(id: 'r3', scheduledAt: base.add(const Duration(days: 2))));

      final result = await ds.getReminders(
        from: base.add(const Duration(hours: 12)),
        to: base.add(const Duration(days: 1, hours: 12)),
      );

      expect(result, hasLength(1));
      expect(result.single.id, 'r2');
    });

    test('excludes soft-deleted reminders from ranged query', () async {
      final scheduledAt = DateTime(2026, 8, 22, 9, 0);
      await ds.createReminder(_reminder(id: 'range-del', scheduledAt: scheduledAt));
      await ds.deleteReminder('range-del');

      final result = await ds.getReminders(
        from: scheduledAt.subtract(const Duration(hours: 1)),
        to: scheduledAt.add(const Duration(hours: 1)),
      );

      expect(result, isEmpty);
    });
  });

  group('migration', () {
    test('upgrades v1 schema and preserves rows', () async {
      final migrated = await _buildMigratedDS();
      final reminders = await migrated.getReminders();
      expect(reminders, hasLength(1));
      expect(reminders.single.title, 'Legacy reminder');
      expect(reminders.single.archived, isFalse);
      expect(reminders.single.deletedAt, isNull);

      final database = await migrated.db;
      final columns = await database.rawQuery('PRAGMA table_info(reminders)');
      final columnNames = columns.map((row) => row['name']).toSet();
      expect(columnNames, contains('archived'));
      expect(columnNames, contains('deleted_at'));
    });
  });
}