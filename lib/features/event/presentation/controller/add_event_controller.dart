// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/event_validator.dart';
import 'package:mow_events/features/auth/data/models/department.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';
import 'package:mow_events/features/event/domin/entities/reminder_entity.dart';

import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/role/admin_event_role.dart';
import 'package:mow_events/features/event/presentation/role/event_role.dart';
import 'package:mow_events/features/event/presentation/role/manager_event_role.dart';
import 'package:mow_events/features/event/presentation/role/user_event_role.dart';

enum AdminEventType { private, public, included }

enum EventVisibility { private, public, included }

class AddEventController extends GetxController {
  final HomeController homeController = Get.find();

  late final UserEntity currentUser;
  late final EventBuilderBase strategy;
  CategoriesController? categoriesController; // ✅ nullable

  final adminEventType = AdminEventType.private.obs;
  final visibility = EventVisibility.private.obs;

  final selectedCategoryId = RxnInt();
  final members = <int>[].obs;
  final reminders = <ReminderEntity>[].obs;
  final userCurrentInMembers = false.obs;

  final isPublic = 0.obs;
  final isPrivate = 1.obs;
  final isLoading = false.obs;

  final selectedStartDate = Rxn<DateTime>();
  final selectedEndDate = Rxn<DateTime>();
  final selectedStartTime = Rxn<TimeOfDay>();
  final selectedEndTime = Rxn<TimeOfDay>();

  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    currentUser = AuthService.currentUser!.toEntity();
    if (currentUser.isAdmin || currentUser.department?.isManager == true) {
      if (Get.isRegistered<CategoriesController>()) {
        categoriesController = Get.find<CategoriesController>();
      }
    }
    strategy = currentUser.isAdmin
        ? AdminEventBuilder()
        : currentUser.department?.isManager == true
        ? ManagerEventBuilder()
        : UserEventBuilder();

    strategy.applyDefaults(this);
    if (currentUser.isAdmin || currentUser.department?.isManager == true) {
      homeController.loadUsers();
    }
    updateVisibilityFlags();

    ever(adminEventType, (type) {
      if (type != AdminEventType.included) {
        userCurrentInMembers.value = false;
      }
      updateVisibilityFlags();
    });
    ever(visibility, (_) => updateVisibilityFlags());
  }

  final showCategoryRx = false.obs;
  final showMembersRx = false.obs;
  final showAttendanceRx = false.obs;
  final showAdminTypeRx = false.obs;
  bool get showCategory => showCategoryRx.value;
  bool get showMembers => showMembersRx.value;
  bool get showAttendance => showAttendanceRx.value;
  bool get showAdminType => showAdminTypeRx.value;
  bool get canSelectMembers => showMembers;
  void updateVisibilityFlags() {
    if (currentUser.isAdmin) {
      showAdminTypeRx.value = strategy.showAdminType(this);
      showCategoryRx.value = strategy.showCategory(this);
      showMembersRx.value = strategy.showMembers(this);
      showAttendanceRx.value = strategy.showAttendance(this);
    } else if (currentUser.department?.isManager == true) {
      showAdminTypeRx.value = false;
      showCategoryRx.value = strategy.showCategory(this);
      showMembersRx.value = strategy.showMembers(this);
      showAttendanceRx.value = strategy.showAttendance(this);
    } else {
      showAdminTypeRx.value = false;
      showCategoryRx.value = false;
      showMembersRx.value = false;
      showAttendanceRx.value = false;
    }
  }

  List<UserEntity> get selectableMembers {
    // إذا المستخدم عادي → ارجع قائمة فارغة
    if (!currentUser.isAdmin && currentUser.department?.isManager != true)
      return [];

    return strategy.getSelectableMembers(currentUser, homeController.users);
  }

  void toggleMember(int id) {
    if (!canSelectMembers) return; // حماية إضافية
    members.contains(id) ? members.remove(id) : members.add(id);
  }

  Future<void> submit() async {
    if (!validate()) return;
    isLoading.value = true;
    await homeController.createEvent(strategy.build(this));
    isLoading.value = false;
    Get.back();
  }

  bool validate() {
    try {
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
        startDate: selectedStartDate.value!,
        endDate: selectedEndDate.value!,
        startTime: selectedStartTime.value!,
        endTime: selectedEndTime.value!,
      );

      strategy.validate(this);
      return true;
    } catch (e) {
      Get.snackbar(AppTexts.error, e.toString());
      return false;
    }
  }

  Map<Department, List<UserEntity>> get membersGroupedByDepartment {
    final Map<Department, List<UserEntity>> map = {};

    for (final user in selectableMembers) {
      final dept = user.department;
      if (dept == null) continue;

      map.putIfAbsent(dept, () => []);
      map[dept]!.add(user);
    }

    return map;
  }
}
