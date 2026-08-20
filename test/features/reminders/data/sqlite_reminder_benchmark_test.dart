import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/reminders/data/datasources/sqlite_reminder_datasource.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _dbSeq = 0;
final List<Database> _openHandles = [];

Future<SQLiteReminderDataSource> _prepopulate({
  required int total,
  int softDeleted = 0,
}) async {
  final path = 'file:reminder_bench_${_dbSeq++}?mode=memory&cache=shared';
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 2,
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
            updated_at INTEGER NOT NULL,
            archived INTEGER NOT NULL DEFAULT 0,
            deleted_at INTEGER
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_reminders_active_scheduled '
          'ON reminders(scheduled_at ASC) WHERE deleted_at IS NULL AND is_active = 1',
        );
        await db.execute(
          'CREATE INDEX idx_reminders_deleted_scheduled '
          'ON reminders(deleted_at, scheduled_at ASC)',
        );
      },
    ),
  );

  final now = DateTime.now().millisecondsSinceEpoch;
  await db.transaction((txn) async {
    final batch = txn.batch();
    for (int i = 0; i < total; i++) {
      batch.insert('reminders', {
        'id': 'rem-$i',
        'title': 'Reminder $i',
        'description': i.isEven ? 'Description $i' : null,
        'scheduled_at': now + (i * 60000),
        'reminder_type': i.isEven ? 'task' : 'note',
        'is_active': i % 3 == 0 ? 0 : 1,
        'related_item_id': i.isEven ? 'item-$i' : null,
        'created_at': now,
        'updated_at': now,
        'archived': 0,
        'deleted_at': i < softDeleted ? now - 1 : null,
      });
    }
    await batch.commit(noResult: true);
  });

  _openHandles.add(db);

  return SQLiteReminderDataSource(
    databaseFactory: databaseFactoryFfi,
    databasePath: path,
  );
}

void main() {
  setUpAll(sqfliteFfiInit);

  tearDownAll(() async {
    for (final db in _openHandles) {
      if (db.isOpen) await db.close();
    }
    _openHandles.clear();
  });

  group('SQLiteReminderDataSource benchmark', () {
    test('getReminders on 10k reminders under 2s', () async {
      final ds = await _prepopulate(total: 10000);
      final sw = Stopwatch()..start();
      final reminders = await ds.getReminders();
      sw.stop();

      expect(reminders, hasLength(10000));
      expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('date range query on 10k reminders under 1s', () async {
      final ds = await _prepopulate(total: 10000);
      final now = DateTime.now();
      final sw = Stopwatch()..start();
      final reminders = await ds.getReminders(
        from: now.add(const Duration(minutes: 1000)),
        to: now.add(const Duration(minutes: 2000)),
      );
      sw.stop();

      expect(reminders, isNotEmpty);
      expect(sw.elapsed, lessThan(const Duration(seconds: 1)));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('getReminders with all soft-deleted returns empty under 500ms', () async {
      final ds = await _prepopulate(total: 10000, softDeleted: 10000);
      final sw = Stopwatch()..start();
      final reminders = await ds.getReminders();
      sw.stop();

      expect(reminders, isEmpty);
      expect(sw.elapsed, lessThan(const Duration(milliseconds: 500)));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}