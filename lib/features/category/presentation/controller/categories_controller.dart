import 'package:get/get.dart';
import 'package:mow_events/core/utils/local_storage/UserStorage/user_storage.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/category/data/models/category_model.dart';
import 'package:mow_events/features/category/domin/repositories/categories_repository.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

class CategoriesController extends GetxController {
  final CategoriesRepository repository;

  CategoriesController({required this.repository});

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final userStorage = UserStorage();

  @override
  void onInit() {
    super.onInit();
    final currentUser = AuthService.currentUser!;

    if (currentUser.isAdmin || currentUser.department?.isManager == true) {
      loadCategories();
    } else {
      _loadCategoriesForRegularUser();
    }
  }

  void _loadCategoriesForRegularUser() {
    final cached = userStorage.categories;
    if (cached != null && cached.isNotEmpty) {
      categories.assignAll(
        cached.map((e) => CategoryModel.fromJson(e)).toList(),
      );
    } else {
      categories.assignAll([
        CategoryModel(
          id: 0,
          name: "عام",
          color: "#cccccc",
          description: "Default category for regular users",
        ),
      ]);
    }
  }

  Future<void> loadCategories() async {
    final currentUser = AuthService.currentUser!;
    if (!(currentUser.isAdmin || currentUser.department?.isManager == true)) {
      return;
    }

    final cached = userStorage.categories;
    if (cached != null && cached.isNotEmpty) {
      categories.assignAll(
        cached.map((e) => CategoryModel.fromJson(e)).toList(),
      );
    }

    await fetchCategories();
  }

  Future<void> fetchCategories() async {
    final currentUser = AuthService.currentUser!;
    if (!(currentUser.isAdmin || currentUser.department?.isManager == true))
      return;
    if (!InternetGuard.ensureOnline()) {
      return; // نكتفي بالكاش
    }
    try {
      isLoading.value = true;
      final data = await repository.getAll();
      categories.assignAll(data);

      await userStorage.saveCategories(
        categories.map((e) => e.toJson()).toList(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    if (!InternetGuard.ensureOnline()) {
      return;
    }
    try {
      final newCategory = await repository.create(category.toJson());
      categories.add(newCategory);

      await userStorage.saveCategories(
        categories.map((e) => e.toJson()).toList(),
      );

      Get.back();
      final addEventCtrl = Get.find<AddEventController>();
      addEventCtrl.selectedCategoryId.value = newCategory.id;

      Get.snackbar("نجاح", "تم إضافة الفئة بنجاح");
    } catch (e) {
      Get.snackbar("خطأ", "فشل إضافة الفئة");
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (!InternetGuard.ensureOnline()) {
      return;
    }
    try {
      final updated = await repository.update(category.id!, category.toJson());
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) categories[index] = updated;

      await userStorage.saveCategories(
        categories.map((e) => e.toJson()).toList(),
      );

      Get.back();
      Get.snackbar("نجاح", "تم تحديث الفئة بنجاح");
    } catch (e) {
      Get.snackbar("خطأ", "فشل تحديث الفئة");
    }
  }

  Future<void> deleteCategories(List<int> ids) async {
    if (!InternetGuard.ensureOnline()) {
      return;
    }
    try {
      await repository.delete(ids);
      categories.removeWhere((c) => ids.contains(c.id));

      await userStorage.saveCategories(
        categories.map((e) => e.toJson()).toList(),
      );

      final homeController = Get.find<HomeController>();
      await homeController.refreshAllEvents();

      Get.snackbar("نجاح", "تم حذف الفئات بنجاح");
    } catch (e) {
      Get.snackbar("خطأ", "فشل حذف الفئات");
    }
  }
}
