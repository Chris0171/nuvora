import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/tasks/data/datasources/category_datasource.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';
import 'package:nuvora/features/tasks/domain/repositories/category_repository.dart';
import 'package:uuid/uuid.dart';

class CategoryRepositoryImpl implements CategoryRepository {
	CategoryRepositoryImpl({required this.dataSource});

	final CategoryDataSource dataSource;
	static const Uuid _uuid = Uuid();

	@override
	Future<List<Category>> getCategories() async {
		return dataSource.getCategories();
	}

	@override
	Future<void> createCategory(Category category) async {
		final trimmedName = category.name.trim();
		if (trimmedName.isEmpty) {
			throw const CategoryValidationException('Category name is required');
		}

		final newId = category.id.trim().isEmpty ? _uuid.v4() : category.id;
		await dataSource.createCategory(
			Category(
				id: newId,
				name: trimmedName,
			),
		);
	}
}
