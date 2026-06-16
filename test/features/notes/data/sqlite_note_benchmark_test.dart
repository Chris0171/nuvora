import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/notes/data/datasources/sqlite_note_datasource.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _dbSeq = 0;
final List<Database> _openHandles = [];

Future<SQLiteNoteDataSource> _prepopulate({
  required int total,
  int softDeleted = 0,
}) async {
  final path = 'file:note_bench_${_dbSeq++}?mode=memory&cache=shared';

  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE notes (
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
          'CREATE INDEX idx_notes_active_updated ON notes(updated_at DESC) WHERE deleted_at IS NULL',
        );
      },
    ),
  );

  final now = DateTime.now().millisecondsSinceEpoch;
  await db.transaction((txn) async {
    final batch = txn.batch();
    for (int i = 0; i < total; i++) {
      batch.insert('notes', {
        'id': 'n-$i',
        'title': 'Title $i',
        'content': 'Content for note $i',
        'created_at': now + i,
        'updated_at': now + i,
        'is_pinned': 0,
        'archived': 0,
        'deleted_at': i < softDeleted ? now - 1 : null,
      });
    }
    await batch.commit(noResult: true);
  });

  _openHandles.add(db);

  return SQLiteNoteDataSource(
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

  group('SQLiteNoteDataSource benchmark', () {
    test('getNotes on 10k active notes under 2s', () async {
      final ds = await _prepopulate(total: 10000);
      final sw = Stopwatch()..start();
      final notes = await ds.getNotes();
      sw.stop();

      expect(notes, hasLength(10000));
      expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('searchNotes on 10k notes under 2s', () async {
      final ds = await _prepopulate(total: 10000);
      final sw = Stopwatch()..start();
      final notes = await ds.searchNotes('note 9999');
      sw.stop();

      expect(notes, isNotEmpty);
      expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('getNotes with all soft-deleted under 500ms', () async {
      final ds = await _prepopulate(total: 10000, softDeleted: 10000);
      final sw = Stopwatch()..start();
      final notes = await ds.getNotes();
      sw.stop();

      expect(notes, isEmpty);
      expect(sw.elapsed, lessThan(const Duration(milliseconds: 500)));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
