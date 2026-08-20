import 'package:nuvora/core/database/sqlite_datasource_base.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/tasks/data/datasources/category_datasource.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SQLiteCategoryDataSource extends SqliteDatasourceBase
		implements CategoryDataSource {
	SQLiteCategoryDataSource({
		super.databaseFactory,
		super.databasePath,
	});

	@override
	String get databaseName => 'nuvora_categories.db';

	@override
	int get databaseVersion => 1;

	@override
	String get tableName => 'categories';

	@override
	Future<void> onCreateSchema(Database db, int version) async {
		await db.execute('''
			CREATE TABLE $tableName (
				id TEXT PRIMARY KEY,
				name TEXT NOT NULL
			)
		''');
		await db.execute(
			'CREATE UNIQUE INDEX idx_categories_name_nocase ON $tableName(name COLLATE NOCASE)',
		);
	}

	@override
	Future<void> onUpgradeSchema(Database db, int oldVersion, int newVersion) async {
		// No migrations required yet.
	}

	Map<String, Object?> _categoryToMap(Category category) {
		return <String, Object?>{
			'id': category.id,
			'name': category.name,
		};
	}

	Category _categoryFromMap(Map<String, Object?> map) {
		return Category(
			id: map['id']! as String,
			name: map['name']! as String,
		);
	}

	@override
	Future<List<Category>> getCategories() async {
		final database = await db;
		final rows = await database.query(
			tableName,
			orderBy: 'name COLLATE NOCASE ASC',
		);
		return rows.map(_categoryFromMap).toList(growable: false);
	}

	@override
	Future<void> createCategory(Category category) async {
		final database = await db;
		try {
			await database.insert(
				tableName,
				_categoryToMap(category),
				conflictAlgorithm: ConflictAlgorithm.abort,
			);
		} on DatabaseException catch (e) {
			if (e.isUniqueConstraintError()) {
				throw CategoryAlreadyExistsException(category.name);
			}
			rethrow;
		}
	}
}
