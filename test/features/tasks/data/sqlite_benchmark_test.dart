import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/tasks/data/datasources/sqlite_task_datasource.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Shared counter so every helper call gets a unique in-memory DB.
int _dbSeq = 0;
// Holds raw DB handles open so shared-memory data survives when the
// datasource opens a second connection to the same URI.
final List<Database> _openHandles = [];

/// Creates a new in-memory database pre-populated with [count] tasks.
///
/// Inserts are done inside a single SQLite transaction with a batch, so
/// the benchmark measures query performance independently of insert cost.
Future<SQLiteTaskDataSource> _prepopulate({
  required int total,
  int softDeleted = 0,
}) async {
  final path = 'file:bench_${_dbSeq++}?mode=memory&cache=shared';

  // --------------------------------------------------------------------------
  // 1. Populate the database directly via raw sqflite for maximum speed.
  // --------------------------------------------------------------------------
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      // Must match _databaseVersion=3 in SQLiteTaskDataSource so sqflite's
      // singleInstance logic reuses this handle without re-running onCreate.
      version: 3,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE tasks (
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
          'CREATE INDEX idx_tasks_active_created '
          'ON tasks(created_at DESC) WHERE deleted_at IS NULL',
        );
      },
    ),
  );

  final int now = DateTime.now().millisecondsSinceEpoch;

  await db.transaction((txn) async {
    final batch = txn.batch();
    for (int i = 0; i < total; i++) {
      batch.insert('tasks', {
        'id': 'bench-$i',
        'title': 'Task $i',
        'description': null,
        'created_at': now + i,
        'updated_at': now + i,
        'due_date': null,
        'is_completed': 0,
        'priority': 'medium',
        'category_id': null,
        'repeat_type': 'none',
        'archived': 0,
        // The first `softDeleted` rows are soft-deleted.
        'deleted_at': i < softDeleted ? now - 1 : null,
      });
    }
    await batch.commit(noResult: true);
  });

  // Keep the handle alive: in-memory shared DBs are destroyed when the last
  // connection closes.  SQLiteTaskDataSource will receive the same connection
  // via sqflite's singleInstance behaviour.
  _openHandles.add(db);

  // --------------------------------------------------------------------------
  // 2. Return a datasource pointed at the same path.
  // --------------------------------------------------------------------------
  return SQLiteTaskDataSource(
    databaseFactory: databaseFactoryFfi,
    databasePath: path,
  );
}

// ---------------------------------------------------------------------------
void main() {
  setUpAll(sqfliteFfiInit);

  tearDownAll(() async {
    for (final db in _openHandles) {
      if (db.isOpen) await db.close();
    }
    _openHandles.clear();
  });

  group('SQLite performance benchmarks', () {
    // -----------------------------------------------------------------------
    test('getTasks – 10 000 active tasks completes under 2 s', () async {
      const int total = 10000;
      final ds = await _prepopulate(total: total);

      final sw = Stopwatch()..start();
      final tasks = await ds.getTasks();
      sw.stop();

      expect(tasks, hasLength(total),
          reason: 'All $total active tasks should be returned');
      expect(
        sw.elapsed,
        lessThan(const Duration(seconds: 2)),
        reason: 'Query on 10 000 tasks with partial index must be under 2 s',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    // -----------------------------------------------------------------------
    test(
        'getTasks – 10 000 tasks (5 000 soft-deleted) '
        'returns 5 000 active under 2 s', () async {
      const int total = 10000;
      const int softDeleted = 5000;
      final ds = await _prepopulate(total: total, softDeleted: softDeleted);

      final sw = Stopwatch()..start();
      final tasks = await ds.getTasks();
      sw.stop();

      expect(tasks, hasLength(total - softDeleted),
          reason: 'Only active tasks should be returned');
      expect(
        sw.elapsed,
        lessThan(const Duration(seconds: 2)),
        reason: 'Index on deleted_at IS NULL should keep query fast',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    // -----------------------------------------------------------------------
    test('getTasks – 10 000 all-soft-deleted returns empty under 500 ms',
        () async {
      const int total = 10000;
      final ds = await _prepopulate(total: total, softDeleted: total);

      final sw = Stopwatch()..start();
      final tasks = await ds.getTasks();
      sw.stop();

      expect(tasks, isEmpty);
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 500)),
        reason: 'Index should reject all rows quickly when all are deleted',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    // -----------------------------------------------------------------------
    test('single createTask completes under 100 ms', () async {
      final ds = await _prepopulate(total: 0);
      final task = Task(
        id: 'single-bench',
        title: 'Bench task',
        createdAt: DateTime.now(),
        isCompleted: false,
        priority: Priority.medium,
        repeatType: RepeatType.none,
      );

      final sw = Stopwatch()..start();
      await ds.createTask(task);
      sw.stop();

      // The real assertion: a single write shouldn't block the UI thread.
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 100)),
      );
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
