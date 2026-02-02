import 'dart:async';
import 'package:mow_events/features/category/data/data_sources/category_backend.dart';
import 'package:mow_events/features/category/data/models/category_model.dart';
import 'package:mow_events/features/category/domin/repositories/categories_repository.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesBackend backend;

  CategoriesRepositoryImpl({required this.backend});

  Future<T> _safe<T>(
    Future<T> future, {
    required String timeoutMsg,
    Duration duration = const Duration(seconds: 15),
  }) {
    return future.timeout(
      duration,
      onTimeout: () => throw TimeoutException(timeoutMsg),
    );
  }

  @override
  Future<List<CategoryModel>> getAll() =>
      _safe(backend.index(), timeoutMsg: 'Fetching categories timed out');

  @override
  Future<CategoryModel> create(Map<String, dynamic> data) =>
      _safe(backend.store(data), timeoutMsg: 'Creating category timed out');

  @override
  Future<CategoryModel> getById(int id) => _safe(
    backend.show(id),
    timeoutMsg: 'Fetching category details timed out',
  );

  @override
  Future<CategoryModel> update(int id, Map<String, dynamic> data) => _safe(
    backend.update(id, data),
    timeoutMsg: 'Updating category timed out',
  );

  @override
  Future<void> delete(List<int> ids) =>
      _safe(backend.delete(ids), timeoutMsg: 'Deleting categories timed out');
}
