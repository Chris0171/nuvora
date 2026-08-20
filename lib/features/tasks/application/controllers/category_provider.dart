import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/tasks/application/controllers/category_controller.dart';
import 'package:nuvora/features/tasks/data/datasources/category_datasource.dart';
import 'package:nuvora/features/tasks/data/datasources/sqlite_category_datasource.dart';
import 'package:nuvora/features/tasks/data/repositories/category_repository_impl.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';
import 'package:nuvora/features/tasks/domain/repositories/category_repository.dart';

final categoryDataSourceProvider = Provider<CategoryDataSource>((ref) {
	return SQLiteCategoryDataSource();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
	return CategoryRepositoryImpl(
		dataSource: ref.read(categoryDataSourceProvider),
	);
});

final categoryControllerProvider = Provider<CategoryController>((ref) {
	return CategoryController(repository: ref.read(categoryRepositoryProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
	return ref.read(categoryControllerProvider).loadCategories();
});
