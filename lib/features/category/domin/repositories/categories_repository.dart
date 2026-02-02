import 'package:mow_events/features/category/data/models/category_model.dart';

abstract class CategoriesRepository {
  Future<List<CategoryModel>> getAll();
  Future<CategoryModel> create(Map<String, dynamic> data);
  Future<CategoryModel> getById(int id);
  Future<CategoryModel> update(int id, Map<String, dynamic> data);
  Future<void> delete(List<int> ids);
}
