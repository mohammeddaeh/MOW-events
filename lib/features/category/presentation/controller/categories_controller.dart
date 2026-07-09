import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/local_storage/UserStorage/user_storage.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/presentation/controller/user_access_controller.dart';
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
  final UserAccessController accessController = Get.find();
  Worker? _accessWorker;

  EventFormController? get _eventFormControllerOrNull {
    if (!Get.isRegistered<EventFormController>()) {
      return null;
    }

    return Get.find<EventFormController>();
  }

  @override
  void onInit() {
    super.onInit();
    final currentUser = AuthService.currentUser!;
    if (currentUser.isAdmin || currentUser.department?.isManager == true) {
      _loadCachedCategories();
      if (accessController.canUseProtectedFeatures) {
        WidgetsBinding.instance.addPostFrameCallback((_) => fetchCategories());
      }
      _accessWorker = ever<UserAccessState>(
        accessController.state,
        _onAccessStateChanged,
      );
    } else {
      _loadCategoriesForRegularUser();
    }
  }

  @override
  void onClose() {
    _accessWorker?.dispose();
    super.onClose();
  }

  Future<void> _onAccessStateChanged(UserAccessState state) async {
    if (state != UserAccessState.active) {
      return;
    }
    await fetchCategories();
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

    _loadCachedCategories();
    await fetchCategories();
  }

  void _loadCachedCategories() {
    final cached = userStorage.categories;
    if (cached != null && cached.isNotEmpty) {
      categories.assignAll(
        cached.map((e) => CategoryModel.fromJson(e)).toList(),
      );
    }
  }

  Future<void> fetchCategories() async {
    if (!accessController.canUseProtectedFeatures) return;
    if (isLoading.value) return;
    if (!InternetGuard.ensureOnline()) return;

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

  Map<String, String?> validateCategoryData({
    required String name,
    required String description,
    required String colorHex,
  }) {
    final errors = <String, String?>{};
    if (name.trim().isEmpty) errors['name'] = AppTexts.requiredField;
    if (description.trim().isEmpty) {
      errors['description'] = AppTexts.requiredField;
    }
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(colorHex)) {
      errors['color'] = AppTexts.requiredField;
    }
    return errors;
  }

  Map<String, List<String>>? validateDuplicateNameAndColor({
    required String name,
    required String colorHex,
    int? excludeId,
  }) {
    final nameTrim = name.trim().toLowerCase();
    final colorLower = colorHex.trim().toLowerCase();
    final nameTaken = categories.any((c) {
      if (excludeId != null && c.id == excludeId) return false;
      return c.name.trim().toLowerCase() == nameTrim;
    });
    final colorTaken = categories.any((c) {
      if (excludeId != null && c.id == excludeId) return false;
      return (c.color.trim().toLowerCase()) == colorLower;
    });
    if (!nameTaken && !colorTaken) return null;
    final err = <String, List<String>>{};
    if (nameTaken) err['name'] = [AppTexts.nameAlreadyTaken];
    if (colorTaken) err['color'] = [AppTexts.colorAlreadyTaken];
    return err;
  }

  Future<Map<String, List<String>>?> addCategory(CategoryModel category) async {
    if (!accessController.canUseProtectedFeatures) {
      return {
        'general': [AppTexts.warningTitle],
      };
    }
    if (!InternetGuard.ensureOnline()) {
      return {
        'general': [AppTexts.noInternet],
      };
    }
    try {
      final newCategory = await repository.create(category.toJson());
      categories.add(newCategory);
      await userStorage.saveCategories(
        categories.map((e) => e.toJson()).toList(),
      );

      _eventFormControllerOrNull?.selectedCategoryId.value = newCategory.id;

      return null;
    } catch (e) {
      return _parseServerErrors(e.toString(), AppTexts.failedToAddCategory);
    }
  }

  Future<Map<String, List<String>>?> updateCategory(
    CategoryModel category,
  ) async {
    if (!accessController.canUseProtectedFeatures) {
      return {
        'general': [AppTexts.warningTitle],
      };
    }
    if (!InternetGuard.ensureOnline()) {
      return {
        'general': [AppTexts.noInternet],
      };
    }
    try {
      final updated = await repository.update(category.id!, category.toJson());
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) categories[index] = updated;
      await userStorage.saveCategories(
        categories.map((e) => e.toJson()).toList(),
      );

      return null;
    } catch (e) {
      return _parseServerErrors(e.toString(), AppTexts.failedToUpdateCategory);
    }
  }

  Map<String, List<String>> _parseServerErrors(
    String errStr,
    String fallbackMessage,
  ) {
    try {
      final jsonErr = errStr.contains('{')
          ? Map<String, dynamic>.from(
              jsonDecode(errStr.replaceAll(RegExp(r"^[^\{]*"), '')),
            )
          : {};
      if (jsonErr.containsKey('error')) {
        final Map<String, dynamic> fieldErrors = Map<String, dynamic>.from(
          jsonErr['error'],
        );
        return fieldErrors.map((k, v) => MapEntry(k, List<String>.from(v)));
      }
    } catch (_) {}
    return {};
  }

  Future<void> deleteCategories(List<int> ids) async {
    if (!accessController.canUseProtectedFeatures) return;
    if (!InternetGuard.ensureOnline()) return;
    try {
      await repository.delete(ids);
      categories.removeWhere((c) => ids.contains(c.id));
      await userStorage.saveCategories(
        categories.map((e) => e.toJson()).toList(),
      );

      final homeController = Get.find<HomeController>();
      await homeController.refreshAllEvents();

      AppSnackBars.successSnackBar(
        title: AppTexts.success,
        message: AppTexts.categoriesDeletedSuccessfully,
      );
    } catch (e) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.error,
        message: AppTexts.failedToDeleteCategories,
      );
    }
  }
}
