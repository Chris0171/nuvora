import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/tasks/data/datasources/sqlite_category_datasource.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _dbCounter = 0;

SQLiteCategoryDataSource _buildDS() {
  final uniquePath =
      'file:test_categories_${_dbCounter++}?mode=memory&cache=shared';
  return SQLiteCategoryDataSource(
    databaseFactory: databaseFactoryFfi,
    databasePath: uniquePath,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late SQLiteCategoryDataSource ds;

  setUp(() {
    ds = _buildDS();
  });

  test('persists and returns created categories', () async {
    await ds.createCategory(const Category(id: 'work', name: 'Work'));
    await ds.createCategory(const Category(id: 'personal', name: 'Personal'));

    final categories = await ds.getCategories();

    expect(categories, hasLength(2));
    expect(categories.map((c) => c.id), containsAll(<String>['work', 'personal']));
  });

  test('rejects duplicate names case-insensitively', () async {
    await ds.createCategory(const Category(id: 'c1', name: 'Work'));

    await expectLater(
      ds.createCategory(const Category(id: 'c2', name: 'work')),
      throwsA(isA<CategoryAlreadyExistsException>()),
    );
  });
}
