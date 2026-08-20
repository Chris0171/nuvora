import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/tasks/data/datasources/category_datasource.dart';
import 'package:nuvora/features/tasks/data/repositories/category_repository_impl.dart';
import 'package:nuvora/features/tasks/domain/entities/category.dart';

class _FakeCategoryDataSource implements CategoryDataSource {
  final List<Category> stored = <Category>[];

  @override
  Future<void> createCategory(Category category) async {
    stored.add(category);
  }

  @override
  Future<List<Category>> getCategories() async => List.unmodifiable(stored);
}

void main() {
  late _FakeCategoryDataSource dataSource;
  late CategoryRepositoryImpl repository;

  setUp(() {
    dataSource = _FakeCategoryDataSource();
    repository = CategoryRepositoryImpl(dataSource: dataSource);
  });

  test('creates a valid category', () async {
    await repository.createCategory(const Category(id: '', name: 'Work'));

    expect(dataSource.stored, hasLength(1));
    expect(dataSource.stored.first.name, 'Work');
    expect(dataSource.stored.first.id, isNotEmpty);
  });

  test('rejects empty category name', () async {
    await expectLater(
      repository.createCategory(const Category(id: '', name: '   ')),
      throwsA(isA<CategoryValidationException>()),
    );
  });
}
