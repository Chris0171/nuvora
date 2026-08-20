import 'package:nuvora/features/tasks/domain/entities/category.dart';
import 'package:nuvora/features/tasks/domain/repositories/category_repository.dart';

class CategoryController {
	CategoryController({required this.repository});

	final CategoryRepository repository;

	Future<List<Category>> loadCategories() async {
		return repository.getCategories();
	}

	Future<void> createCategory(Category category) async {
		await repository.createCategory(category);
	}
}
