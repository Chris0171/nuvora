import 'package:nuvora/features/tasks/domain/entities/category.dart';

abstract class CategoryRepository {
	Future<List<Category>> getCategories();
	Future<void> createCategory(Category category);
}
