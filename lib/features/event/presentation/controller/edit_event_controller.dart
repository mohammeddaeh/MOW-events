import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/utils/helpers/event_date_time_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/department.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/core/utils/validator/event_validator.dart';
import 'package:mow_events/features/category/data/models/category_model.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

class EditEventController extends GetxController {
  final HomeController homeController;

  EditEventController({required this.homeController});

  late EventModel event;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();

  final selectedStartDate = DateTime.now().obs;
  final selectedEndDate = DateTime.now().obs;
  final selectedStartTime = const TimeOfDay(hour: 9, minute: 0).obs;
  final selectedEndTime = const TimeOfDay(hour: 10, minute: 0).obs;

  final members = <int>[].obs;
  final selectedCategoryId = RxnInt();
  var isLoading = false.obs;
  var membersLoaded = false.obs;

  UserEntity get currentUser => AuthService.currentUser!.toEntity();

  bool get showCategorySection => showMembersSection;

  /// عرض الفئة والأعضاء للأحداث المضمنة لكل من الأدمن والمنجر
  bool get showMembersSection =>
      (currentUser.isAdmin || currentUser.department?.isManager == true) &&
      event.isPublic == 0 &&
      event.isPrivate == 0;

  List<UserEntity> get selectableMembers {
    if (!currentUser.isAdmin && currentUser.department?.isManager != true) {
      return [];
    }
    if (currentUser.isAdmin) return homeController.users;
    final deptId = currentUser.department?.id;
    return homeController.users
        .where((u) => u.department?.id == deptId)
        .toList();
  }

  Map<Department, List<UserEntity>> get membersGroupedByDepartment {
    final Map<Department, List<UserEntity>> map = {};
    for (final user in selectableMembers) {
      final dept = user.department;
      if (dept == null) continue;
      Department? keyDept;
      for (final existing in map.keys) {
        if (existing.id == dept.id) {
          keyDept = existing;
          break;
        }
      }
      if (keyDept == null) {
        map[dept] = [user];
      } else {
        map[keyDept]!.add(user);
      }
    }
    return map;
  }

  final Map<int, RxBool> _deptExpanded = {};
  RxBool deptExpandedRx(Department dept) =>
      _deptExpanded.putIfAbsent(dept.id, () => false.obs);
  void toggleDeptExpanded(Department dept) {
    final rx = _deptExpanded.putIfAbsent(dept.id, () => false.obs);
    rx.value = !rx.value;
  }

  bool isDepartmentFullySelected(Department dept) {
    final users = membersGroupedByDepartment[dept];
    if (users == null || users.isEmpty) return false;
    return users.every((u) => members.contains(u.id));
  }

  void toggleDepartmentSelection(Department dept) {
    final users = membersGroupedByDepartment[dept];
    if (users == null || users.isEmpty) return;
    final allSelected = isDepartmentFullySelected(dept);
    final list = List<int>.from(members);
    if (allSelected) {
      for (final u in users) list.remove(u.id);
    } else {
      for (final u in users) {
        if (!list.contains(u.id)) list.add(u.id);
      }
    }
    members.assignAll(list);
  }

  void toggleMember(int id) {
    final list = List<int>.from(members);
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    members.assignAll(list);
  }

  @override
  void onInit() {
    super.onInit();
    event = Get.arguments as EventModel;
    _fillForm();
  }

  @override
  void onReady() {
    super.onReady();
    if (showMembersSection) _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (membersLoaded.value) return;
    try {
      await homeController.loadUsers(
        departmentId: currentUser.isAdmin ? null : currentUser.department?.id,
      );
      final ids = await homeController.eventRepo.getEventMembers(event.id);
      final allowedIds = selectableMembers.map((u) => u.id).toSet();
      members.assignAll(ids.where((id) => allowedIds.contains(id)).toList());
      _expandFirstDepartmentWithMembers();
    } catch (_) {}
    membersLoaded.value = true;
  }

  void _expandFirstDepartmentWithMembers() {
    for (final entry in membersGroupedByDepartment.entries) {
      final dept = entry.key;
      final users = entry.value;
      if (users.any((u) => members.contains(u.id))) {
        final rx = _deptExpanded.putIfAbsent(dept.id, () => true.obs);
        rx.value = true;
        break;
      }
    }
  }

  void _fillForm() {
    nameController.text = event.name;
    descriptionController.text = event.description;
    locationController.text = event.location;
    selectedCategoryId.value = event.category?.id;

    final start = event.startDateTimeSafe ?? DateTime.now();
    final end =
        event.endDateTimeSafe ?? DateTime.now().add(const Duration(hours: 1));

    selectedStartDate.value = DateTime(start.year, start.month, start.day);
    selectedEndDate.value = DateTime(end.year, end.month, end.day);

    selectedStartTime.value = TimeOfDay(hour: start.hour, minute: start.minute);
    selectedEndTime.value = TimeOfDay(hour: end.hour, minute: end.minute);

    startTimeController.text =
        '${selectedStartTime.value.hour.toString().padLeft(2, '0')}:${selectedStartTime.value.minute.toString().padLeft(2, '0')}';
    endTimeController.text =
        '${selectedEndTime.value.hour.toString().padLeft(2, '0')}:${selectedEndTime.value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> updateEvent() async {
    if (!validate()) return;

    CategoryModel? category = event.category;
    if (showCategorySection && selectedCategoryId.value != null) {
      final list = Get.find<CategoriesController>().categories
          .where((c) => c.id == selectedCategoryId.value)
          .toList();
      category = list.isNotEmpty ? list.first : event.category;
    }

    // إرسال أعضاء معتمدين فقط (من قسم المنجر) لتجنب خطأ "invalid" من الـ API
    final allowedIds = selectableMembers.map((u) => u.id).toSet();
    final validMembers = showMembersSection
        ? members.where((id) => allowedIds.contains(id)).toList()
        : event.members;

    final updatedEvent = event.copyWith(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      location: locationController.text.trim(),
      category: category,
      startDate: EventDateTimeHelper.formatDate(selectedStartDate.value),
      startTime: EventDateTimeHelper.formatTimeHhMm(selectedStartTime.value),
      endDate: EventDateTimeHelper.formatDate(selectedEndDate.value),
      endTime: EventDateTimeHelper.formatTimeHhMm(selectedEndTime.value),
      members: validMembers,
    );

    isLoading.value = true;
    try {
      await homeController.updateEvent(updatedEvent.id, updatedEvent);
      Get.back();
    } catch (e) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.errorOccurred,
        message: ErrorHandler.getErrorMessage(e),
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool validate() {
    try {
      if (showCategorySection && selectedCategoryId.value == null) {
        throw Exception(AppTexts.selectCategory);
      }
      if (showMembersSection && members.isEmpty) {
        throw Exception(AppTexts.chooseMembersForTheEvent);
      }
      EventValidator.validateRequiredFields(
        name: nameController.text,
        location: locationController.text,
        description: descriptionController.text,
        startDate: selectedStartDate.value,
        endDate: selectedEndDate.value,
        startTime: selectedStartTime.value,
        endTime: selectedEndTime.value,
      );

      EventValidator.validateDateTimeLogic(
        startDate: selectedStartDate.value,
        endDate: selectedEndDate.value,
        startTime: selectedStartTime.value,
        endTime: selectedEndTime.value,
      );

      return true;
    } catch (e) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.error,
        message: e.toString(),
      );
      return false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.onClose();
  }
}
