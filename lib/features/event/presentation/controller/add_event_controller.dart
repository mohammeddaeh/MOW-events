import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
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
  CategoriesController? categoriesController;

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

  final nameError = Rxn<String>();
  final locationError = Rxn<String>();
  final descriptionError = Rxn<String>();
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
      if (strategy.showMembers(this)) _expandFirstDepartment();
    });
    ever(visibility, (_) {
      updateVisibilityFlags();
      if (strategy.showMembers(this)) _expandFirstDepartment();
    });
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
    if (!currentUser.isAdmin && currentUser.department?.isManager != true)
      return [];

    return strategy.getSelectableMembers(currentUser, homeController.users);
  }

  void toggleMember(int id) {
    if (!canSelectMembers) return;
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
    nameError.value = null;
    locationError.value = null;
    descriptionError.value = null;

    final name = nameController.text.trim();
    final location = locationController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) nameError.value = AppTexts.eventNameRequired;
    if (location.isEmpty) locationError.value = AppTexts.locationRequired;
    if (description.isEmpty) descriptionError.value = AppTexts.descriptionRequired;

    if (nameError.value != null || locationError.value != null || descriptionError.value != null) {
      return false;
    }

    try {
      EventValidator.validateRequiredFields(
        name: name,
        location: location,
        description: description,
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
      final message = e is Exception
          ? e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')
          : e is ArgumentError
              ? (e.message.isEmpty ? e.toString() : e.message)
              : e.toString();
      AppSnackBars.errorSnackBar(
        title: AppTexts.errorOccurred,
        message: message.trim().isEmpty ? AppTexts.theProfileHasNotBeenUpdated : message,
        duration: 4,
      );
      return false;
    }
  }

  Map<Department, List<UserEntity>> get membersGroupedByDepartment {
    final Map<Department, List<UserEntity>> map = {};

    for (final user in selectableMembers) {
      final dept = user.department;
      if (dept == null) continue;

      // Use department id equality to avoid duplicate Department instances
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

  bool isDeptExpanded(Department dept) {
    return _deptExpanded[dept.id]?.value ?? false;
  }

  void toggleDeptExpanded(Department dept) {
    final rx = _deptExpanded.putIfAbsent(dept.id, () => false.obs);
    rx.value = !rx.value;
  }

  /// Return the RxBool for a department so widgets can observe it directly.
  RxBool deptExpandedRx(Department dept) {
    return _deptExpanded.putIfAbsent(dept.id, () => false.obs);
  }

  bool isDepartmentFullySelected(Department dept) {
    final users = membersGroupedByDepartment[dept];
    if (users == null || users.isEmpty) return false;
    return users.every((u) => members.contains(u.id));
  }

  void _expandFirstDepartment() {
    final grouped = membersGroupedByDepartment;
    if (grouped.isNotEmpty) {
      final firstDept = grouped.keys.first;
      final rx = _deptExpanded.putIfAbsent(firstDept.id, () => true.obs);
      rx.value = true;
    }
  }

  void toggleDepartmentSelection(Department dept) {
    final users = membersGroupedByDepartment[dept];
    if (users == null || users.isEmpty) return;

    final allSelected = isDepartmentFullySelected(dept);
    if (allSelected) {
      // remove all
      for (final u in users) {
        members.remove(u.id);
      }
    } else {
      // add all
      for (final u in users) {
        if (!members.contains(u.id)) members.add(u.id);
      }
    }
  }
}
