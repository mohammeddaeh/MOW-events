import 'package:mow_events/core/utils/http/api_endpoints.dart';
import 'package:mow_events/features/category/data/models/category_model.dart';

import '../../../../core/utils/helpers/http_helper.dart';

class CategoriesBackend {
  Future<List<CategoryModel>> index() async {
    final res = await HttpHelper.get(ApiEndpoints.categoriesIndex);
    final items = (res['data']['categories']['items'] as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
    return items;
  }

  Future<CategoryModel> store(Map<String, dynamic> data) async {
    final res = await HttpHelper.post(ApiEndpoints.categoriesStore, data);

    return CategoryModel.fromJson(res['data']['result']);
  }

  Future<CategoryModel> show(int id) async {
    final res = await HttpHelper.get(ApiEndpoints.categoriesShow(id));
    return CategoryModel.fromJson(res['data']['result']);
  }

  Future<CategoryModel> update(int id, Map<String, dynamic> data) async {
    final res = await HttpHelper.post(ApiEndpoints.categoriesUpdate(id), data);
    return CategoryModel.fromJson(res['data']['result']);
  }

  Future<void> delete(List<int> ids) async {
    final query = ids.map((id) => 'ids[]=$id').join('&');
    await HttpHelper.delete('${ApiEndpoints.categoriesDelete}?$query');
  }
}
