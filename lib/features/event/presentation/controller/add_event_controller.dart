import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/helpers/event_date_time_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/event_validator.dart';
import 'package:mow_events/features/auth/data/models/department.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/entities/reminder_entity.dart';

import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/helpers/member_search_helper.dart';
import 'package:mow_events/features/event/presentation/role/admin_event_role.dart';
import 'package:mow_events/features/event/presentation/role/event_role.dart';
import 'package:mow_events/features/event/presentation/role/manager_event_role.dart';
import 'package:mow_events/features/event/presentation/role/user_event_role.dart';

enum AdminEventType { personal, public, included }

enum EventVisibility { personal, public, included }

enum AddEventFormSection {
  basicInfo,
  eventType,
  category,
  dateTime,
  reminders,
  members,
}

enum EventFormMode { create, edit }

class EventFormController extends GetxController {
  final HomeController homeController = Get.find();
  EventFormController({required this.mode, this.initialEvent});

  final EventFormMode mode;
  final EventModel? initialEvent;

  bool get isEditMode => mode == EventFormMode.edit;
  Worker? _adminTypeWorker;
  Worker? _visibilityWorker;

  late final UserEntity currentUser;
  late final EventBuilderBase strategy;
  CategoriesController? categoriesController;
  EventModel? _editingEvent;
  final _prefilledMemberIds = <int>{};

  final adminEventType = AdminEventType.personal.obs;
  final visibility = EventVisibility.personal.obs;

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
  final memberSearchController = TextEditingController();
  final memberSearchFocusNode = FocusNode();

  final nameError = Rxn<String>();
  final locationError = Rxn<String>();
  final descriptionError = Rxn<String>();
  final dateTimeError = Rxn<String>();
  final categoryError = Rxn<String>();
  final remindersError = Rxn<String>();
  final membersError = Rxn<String>();
  final memberSearchQuery = ''.obs;
  final firstErrorSection = Rxn<AddEventFormSection>();

  final Map<AddEventFormSection, GlobalKey> sectionKeys = {
    AddEventFormSection.basicInfo: GlobalKey(),
    AddEventFormSection.eventType: GlobalKey(),
    AddEventFormSection.category: GlobalKey(),
    AddEventFormSection.dateTime: GlobalKey(),
    AddEventFormSection.reminders: GlobalKey(),
    AddEventFormSection.members: GlobalKey(),
  };

  /// يُحدَّث عند التركيز على حقل البحث لضبط الحشو السفلي والتمرير فوق الكيبورد.
  final memberSearchFocused = false.obs;

  void _syncMemberSearchFocus() {
    memberSearchFocused.value = memberSearchFocusNode.hasFocus;
  }

  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();
  final _initialSnapshot = <String, Object?>{};

  @override
  void onInit() {
    super.onInit();

    currentUser = AuthService.currentUser!.toEntity();
    if (currentUser.isAdmin || currentUser.department?.isManager == true) {
      if (Get.isRegistered<CategoriesController>()) {
        categoriesController = Get.find<CategoriesController>();
        categoriesController?.loadCategories();
      }
    }
    strategy = currentUser.isAdmin
        ? AdminEventBuilder()
        : currentUser.department?.isManager == true
        ? ManagerEventBuilder()
        : UserEventBuilder();

    strategy.applyDefaults(this);
    userCurrentInMembers.value = true;
    if (currentUser.isAdmin || currentUser.department?.isManager == true) {
      _loadSelectableUsers();
    }
    updateVisibilityFlags();
    if (isEditMode) {
      _editingEvent = initialEvent ?? (Get.arguments as EventModel?);
      if (_editingEvent != null) {
        _fillFromEvent(_editingEvent!);
        // Recompute dynamic visibility after prefill (admin type / manager visibility)
        // so category/member fields are not cleared based on default create-mode flags.
        updateVisibilityFlags();
        _loadEditEventDetails();
        _loadEditMembers();
      }
    }
    _cleanDynamicState();
    _captureInitialSnapshot();

    _adminTypeWorker = ever<AdminEventType>(adminEventType, (type) {
      _clearRoleErrors();
      updateVisibilityFlags();
      _cleanDynamicState();
    });
    _visibilityWorker = ever<EventVisibility>(visibility, (_) {
      _clearRoleErrors();
      updateVisibilityFlags();
      _cleanDynamicState();
    });

    memberSearchFocusNode.addListener(_syncMemberSearchFocus);
  }

  final showCategoryRx = false.obs;
  final showMembersRx = false.obs;
  final showAttendanceRx = false.obs;
  final showAdminTypeRx = false.obs;
  bool get showCategory => showCategoryRx.value;
  bool get showMembers => showMembersRx.value;
  bool get showAttendance => showAttendanceRx.value;
  bool get showAdminType => showAdminTypeRx.value;
  bool get canSelectMembers => strategy.showMembers(this);
  void updateVisibilityFlags() {
    if (currentUser.isAdmin) {
      showAdminTypeRx.value = strategy.showAdminType(this);
      showCategoryRx.value = strategy.showCategory(this);
      showMembersRx.value = strategy.showMembers(this);
      showAttendanceRx.value = false;
    } else if (currentUser.department?.isManager == true) {
      showAdminTypeRx.value = false;
      showCategoryRx.value = strategy.showCategory(this);
      showMembersRx.value = strategy.showMembers(this);
      showAttendanceRx.value = false;
    } else {
      showAdminTypeRx.value = false;
      showCategoryRx.value = false;
      showMembersRx.value = false;
      showAttendanceRx.value = false;
    }
  }

  List<UserEntity> get selectableMembers {
    if (!currentUser.isAdmin && currentUser.department?.isManager != true) {
      return [];
    }

    return strategy.getSelectableMembers(currentUser, homeController.users);
  }

  bool get hasMemberSearch => memberSearchQuery.value.trim().isNotEmpty;

  /// تسمية توضيحية لنطاق البحث الحالي (اسم/بريد/هاتف).
  String? get memberSearchScopeLabel {
    if (!hasMemberSearch) return null;
    return switch (MemberSearchHelper.classify(memberSearchQuery.value)) {
      MemberSearchMode.empty => null,
      MemberSearchMode.emailAddress => AppTexts.memberSearchScopeEmail,
      MemberSearchMode.phoneDigits => AppTexts.memberSearchScopePhone,
      MemberSearchMode.mixedLocalEmail => AppTexts.memberSearchScopeMixedEmail,
      MemberSearchMode.textNameOrEmail => AppTexts.memberSearchScopeName,
    };
  }

  int get selectedMembersCount => selectedMembers.length;

  void onMemberSearchChanged(String value) {
    memberSearchQuery.value = MemberSearchHelper.normalizeQuery(value);
  }

  void clearMemberSearch({bool unfocus = false}) {
    memberSearchController.clear();
    memberSearchQuery.value = '';
    if (unfocus) {
      memberSearchFocusNode.unfocus();
    }
  }

  void finishMemberSearch() => clearMemberSearch(unfocus: true);

  bool matchesMemberSearch(UserEntity user) {
    return MemberSearchHelper.matches(user, memberSearchQuery.value);
  }

  List<UserEntity> orderUsers(List<UserEntity> users) {
    final list = List<UserEntity>.from(users);
    final managers =
        list
            .where(
              (u) => u.isManager == true || u.department?.isManager == true,
            )
            .toList()
          ..sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );
    final others =
        list
            .where(
              (u) => !(u.isManager == true || u.department?.isManager == true),
            )
            .toList()
          ..sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );
    return [...managers, ...others];
  }

  List<UserEntity> get searchResultMembers {
    final q = memberSearchQuery.value;
    final list = selectableMembers.where(matchesMemberSearch).toList();
    if (q.trim().isEmpty) return orderUsers(list);
    list.sort(
      (a, b) => MemberSearchHelper.compareUsersBySearchRelevance(a, b, q),
    );
    return list;
  }

  List<UserEntity> get selectedMembers {
    final selectedIds = members.toSet();
    return orderUsers(
      selectableMembers.where((user) => selectedIds.contains(user.id)).toList(),
    );
  }

  bool get canManageEventReminders =>
      currentUser.isAdmin || currentUser.department?.isManager == true;

  DateTime? get eventStartDateTimeForReminders {
    final date = selectedStartDate.value;
    final time = selectedStartTime.value;
    if (date == null || time == null) return null;
    return EventDateTimeHelper.combine(
      EventDateTimeHelper.formatDate(date),
      EventDateTimeHelper.formatTimeHhMm(time),
    );
  }

  void addReminder({required ReminderType type, required int value}) {
    final start = eventStartDateTimeForReminders;
    if (start == null) {
      throw Exception(AppTexts.pleaseSelectAStartAndEndDateAndTime);
    }
    final reminder = ReminderEntity.createCustom(
      'new',
      type,
      value,
      start,
      existingReminders: reminders,
    );
    reminders.add(reminder);
    _sortReminders();
  }

  void updateReminder({
    required ReminderEntity original,
    required ReminderType type,
    required int value,
  }) {
    final start = eventStartDateTimeForReminders;
    if (start == null) {
      throw Exception(AppTexts.pleaseSelectAStartAndEndDateAndTime);
    }
    ReminderEntity.validateCustom(
      type: type,
      value: value,
      existingReminders: reminders,
      editingReminderId: original.id,
    );
    final updated = original.copyWith(
      type: type,
      value: value,
      reminderTime: ReminderEntity.calculateTime(start, type, value),
    );
    final index = reminders.indexWhere((r) => r.id == original.id);
    if (index != -1) {
      reminders[index] = updated;
      _sortReminders();
    }
  }

  void removeReminder(ReminderEntity reminder) {
    reminders.removeWhere((r) => r.id == reminder.id);
    reminders.refresh();
  }

  void _sortReminders() {
    reminders.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    reminders.refresh();
  }

  void toggleMember(int id) {
    if (!canSelectMembers) return;
    membersError.value = null;
    members.contains(id) ? members.remove(id) : members.add(id);
  }

  Future<void> submit() async {
    if (!validate()) return;
    isLoading.value = true;
    try {
      final model = strategy.build(this);
      if (isEditMode) {
        final editing = _editingEvent;
        if (editing != null) {
          await homeController.updateEvent(
            editing.id,
            model.copyWith(id: editing.id),
          );
        }
      } else {
        await homeController.createEvent(model);
      }
      Get.back();
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e);
      if (_isDateTimeBackendValidationError(message)) {
        dateTimeError.value = _normalizeDateTimeErrorMessage(message);
        firstErrorSection.value = AddEventFormSection.dateTime;
      } else {
        AppSnackBars.errorSnackBar(
          title: AppTexts.errorOccurred,
          message: message,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool validate() {
    _cleanDynamicState();
    nameError.value = null;
    locationError.value = null;
    descriptionError.value = null;
    dateTimeError.value = null;
    categoryError.value = null;
    remindersError.value = null;
    membersError.value = null;
    firstErrorSection.value = null;

    final name = nameController.text.trim();
    final location = locationController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) nameError.value = AppTexts.eventNameRequired;
    if (location.isEmpty) locationError.value = AppTexts.locationRequired;
    if (description.isEmpty) {
      descriptionError.value = AppTexts.descriptionRequired;
    }

    if (nameError.value != null ||
        locationError.value != null ||
        descriptionError.value != null) {
      firstErrorSection.value = AddEventFormSection.basicInfo;
      return false;
    }

    final roleError = _validateRoleRules();
    if (roleError != null) {
      if (roleError == AppTexts.selectCategory) {
        categoryError.value = roleError;
        firstErrorSection.value = AddEventFormSection.category;
      }
      if (roleError == AppTexts.employeesMustBeSelected ||
          roleError == AppTexts.chooseMembersForTheEvent) {
        membersError.value = roleError;
        firstErrorSection.value = AddEventFormSection.members;
      }
      return false;
    }

    final commonError = _validateCommonFields(
      name: name,
      location: location,
      description: description,
    );
    if (commonError != null) {
      dateTimeError.value = commonError;
      firstErrorSection.value = AddEventFormSection.dateTime;
      return false;
    }

    return true;
  }

  String? _validateCommonFields({
    required String name,
    required String location,
    required String description,
  }) {
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
      return null;
    } catch (e) {
      return e is Exception
          ? e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')
          : e.toString();
    }
  }

  bool _isDateTimeBackendValidationError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('start_date') ||
        normalized.contains('end_date') ||
        normalized.contains('start_time') ||
        normalized.contains('end_time') ||
        normalized.contains('date') ||
        normalized.contains('time');
  }

  String _normalizeDateTimeErrorMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('after') ||
        normalized.contains('before') ||
        normalized.contains('end') ||
        normalized.contains('start')) {
      return AppTexts.theEndDateAndTimeMustBeAfterTheStartDate;
    }
    return AppTexts.futureEventsOnly;
  }

  String? _validateRoleRules() {
    if (showCategory) {
      final selectedId = selectedCategoryId.value;
      if (selectedId == null) {
        categoryError.value = AppTexts.selectCategory;
        return categoryError.value;
      }
      final categories = categoriesController?.categories ?? const [];
      if (categories.isEmpty && _isEditingCategorySelected) {
        return null;
      }
      final exists = categories.any((category) => category.id == selectedId);
      if (!exists) {
        if (_isEditingCategorySelected) return null;
        categoryError.value = AppTexts.selectCategory;
        return categoryError.value;
      }
    }

    if (showMembers && members.isEmpty) {
      membersError.value = currentUser.isAdmin
          ? AppTexts.employeesMustBeSelected
          : AppTexts.chooseMembersForTheEvent;
      firstErrorSection.value = AddEventFormSection.members;
      return membersError.value;
    }

    return null;
  }

  void _clearRoleErrors() {
    categoryError.value = null;
    membersError.value = null;
  }

  void _cleanDynamicState() {
    userCurrentInMembers.value = true;
    if (!showCategory) {
      selectedCategoryId.value = null;
      categoryError.value = null;
    } else {
      final selectedId = selectedCategoryId.value;
      if (selectedId != null) {
        final categories = categoriesController?.categories ?? const [];
        final hasLoadedCategories = categories.isNotEmpty;
        if (hasLoadedCategories &&
            !categories.any((category) => category.id == selectedId) &&
            !_isEditingCategorySelected) {
          selectedCategoryId.value = null;
        }
      }
    }

    if (!showMembers) {
      members.clear();
      _prefilledMemberIds.clear();
      membersError.value = null;
      clearMemberSearch(unfocus: true);
      _deptExpanded.clear();
      return;
    }

    final selectableIds = selectableMembers.map((user) => user.id).toSet();
    if (isEditMode && selectableIds.isEmpty && members.isNotEmpty) {
      // Users list may still be loading; keep prefilled ids to avoid losing edit state.
      return;
    }
    members.removeWhere((id) => !selectableIds.contains(id));
  }

  bool get hasChanges {
    if (!isEditMode) return true;
    final current = _buildSnapshot();
    return _initialSnapshot.toString() != current.toString();
  }

  String get submitButtonText =>
      isEditMode ? AppTexts.updateEvent : AppTexts.saveEvent;
  String? get editingCategoryName => _editingEvent?.category?.name;

  bool get _isEditingCategorySelected {
    if (!isEditMode) return false;
    final selectedId = selectedCategoryId.value;
    final editingCategoryId = _editingEvent?.category?.id;
    return selectedId != null &&
        editingCategoryId != null &&
        selectedId == editingCategoryId;
  }

  void _fillFromEvent(EventModel event) {
    nameController.text = event.name;
    locationController.text = event.location;
    descriptionController.text = event.description;
    selectedCategoryId.value = event.category?.id;

    final start = event.startDateTimeSafe ?? DateTime.now();
    final end =
        event.endDateTimeSafe ?? DateTime.now().add(const Duration(hours: 1));
    selectedStartDate.value = DateTime(start.year, start.month, start.day);
    selectedEndDate.value = DateTime(end.year, end.month, end.day);
    selectedStartTime.value = TimeOfDay(hour: start.hour, minute: start.minute);
    selectedEndTime.value = TimeOfDay(hour: end.hour, minute: end.minute);
    startDateController.text = EventDateTimeHelper.formatDate(
      selectedStartDate.value!,
    );
    endDateController.text = EventDateTimeHelper.formatDate(
      selectedEndDate.value!,
    );
    startTimeController.text = DateLocalizationHelper.formatTimeOfDay(
      selectedStartTime.value!,
    );
    endTimeController.text = DateLocalizationHelper.formatTimeOfDay(
      selectedEndTime.value!,
    );

    reminders.assignAll(event.reminders);
    final validMemberIds = event.members.where((id) => id > 0).toSet();
    _prefilledMemberIds
      ..clear()
      ..addAll(validMemberIds);
    members.assignAll(validMemberIds.toList());
    userCurrentInMembers.value = event.userCurrentInMembers;

    if (currentUser.isAdmin) {
      if (event.isPublic == 1) {
        adminEventType.value = AdminEventType.public;
      } else if (event.isPrivate == 1) {
        adminEventType.value = AdminEventType.personal;
      } else {
        adminEventType.value = AdminEventType.included;
      }
    } else if (currentUser.department?.isManager == true) {
      visibility.value = (event.isPrivate == 0 && event.isPublic == 0)
          ? EventVisibility.included
          : EventVisibility.personal;
    }
  }

  void _captureInitialSnapshot() {
    _initialSnapshot
      ..clear()
      ..addAll(_buildSnapshot());
  }

  Future<void> _loadEditEventDetails() async {
    final editing = _editingEvent;
    if (!isEditMode || editing == null || editing.id <= 0) return;
    try {
      final details = await homeController.eventRepo.getEventDetails(
        editing.id,
      );
      _editingEvent = details;
      _fillFromEvent(details);
      updateVisibilityFlags();
      _cleanDynamicState();
      _captureInitialSnapshot();
      update();
    } catch (_) {
      // Keep existing prefilled event data if details fetch fails.
    }
  }

  Future<void> _loadEditMembers() async {
    final editing = _editingEvent;
    if (!isEditMode || editing == null || editing.id <= 0) return;
    await _loadSelectableUsers();
    final validIds = editing.members.where((id) => id > 0).toSet();
    if (validIds.isEmpty) return;
    _prefilledMemberIds
      ..clear()
      ..addAll(validIds);
    members.assignAll(validIds.toList());
    _cleanDynamicState();
    update();
  }

  Future<void> _loadSelectableUsers() async {
    if (!(currentUser.isAdmin || currentUser.department?.isManager == true)) {
      return;
    }
    await homeController.loadUsers();
  }

  Map<String, Object?> _buildSnapshot() {
    final cleanedMembers = List<int>.from(members)..sort();
    final remindersSnapshot =
        reminders.map((r) => '${r.type.name}:${r.value}').toList()..sort();
    return {
      'name': nameController.text.trim(),
      'location': locationController.text.trim(),
      'description': descriptionController.text.trim(),
      'startDate': selectedStartDate.value?.toIso8601String(),
      'endDate': selectedEndDate.value?.toIso8601String(),
      'startTime': selectedStartTime.value == null
          ? null
          : '${selectedStartTime.value!.hour}:${selectedStartTime.value!.minute}',
      'endTime': selectedEndTime.value == null
          ? null
          : '${selectedEndTime.value!.hour}:${selectedEndTime.value!.minute}',
      'categoryId': selectedCategoryId.value,
      'members': cleanedMembers.join(','),
      'reminders': remindersSnapshot.join('|'),
      'adminType': adminEventType.value.name,
      'visibility': visibility.value.name,
    };
  }

  bool hasSectionError(AddEventFormSection section) {
    return switch (section) {
      AddEventFormSection.basicInfo =>
        nameError.value != null ||
            locationError.value != null ||
            descriptionError.value != null,
      AddEventFormSection.eventType => false,
      AddEventFormSection.category => categoryError.value != null,
      AddEventFormSection.dateTime => dateTimeError.value != null,
      AddEventFormSection.reminders => remindersError.value != null,
      AddEventFormSection.members => membersError.value != null,
    };
  }

  List<UserEntity> _orderUsersForGroupedList(
    List<UserEntity> users, {
    String? searchQuery,
  }) {
    final out = List<UserEntity>.from(users);
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      out.sort(
        (a, b) =>
            MemberSearchHelper.compareUsersBySearchRelevance(a, b, searchQuery),
      );
      return out;
    }
    return orderUsers(out);
  }

  Map<Department, List<UserEntity>> _groupMembersByDepartment(
    List<UserEntity> users, {
    String? searchQuery,
  }) {
    final Map<Department, List<UserEntity>> map = {};

    for (final user in users) {
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

    final managerDeptId = currentUser.department?.id;
    final sortedEntries = map.entries.toList()
      ..sort((a, b) {
        if (managerDeptId != null) {
          if (a.key.id == managerDeptId) return -1;
          if (b.key.id == managerDeptId) return 1;
        }
        return a.key.name.toLowerCase().compareTo(b.key.name.toLowerCase());
      });
    return {
      for (final entry in sortedEntries)
        entry.key: _orderUsersForGroupedList(
          entry.value,
          searchQuery: searchQuery,
        ),
    };
  }

  Map<Department, List<UserEntity>> get membersGroupedByDepartment =>
      _groupMembersByDepartment(selectableMembers);

  Map<Department, List<UserEntity>> get filteredMembersGroupedByDepartment {
    if (!hasMemberSearch) return membersGroupedByDepartment;
    final filtered = selectableMembers.where(matchesMemberSearch).toList();
    return _groupMembersByDepartment(
      filtered,
      searchQuery: memberSearchQuery.value,
    );
  }

  Map<Department, List<UserEntity>> get selectedMembersGroupedByDepartment =>
      _groupMembersByDepartment(selectedMembers);

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

  bool isDepartmentFullySelected(Department dept, {bool useFiltered = false}) {
    final users = (useFiltered
        ? filteredMembersGroupedByDepartment
        : membersGroupedByDepartment)[dept];
    if (users == null || users.isEmpty) return false;
    return users.every((u) => members.contains(u.id));
  }

  void toggleDepartmentSelection(Department dept, {bool useFiltered = false}) {
    final users = (useFiltered
        ? filteredMembersGroupedByDepartment
        : membersGroupedByDepartment)[dept];
    if (users == null || users.isEmpty) return;

    final allSelected = isDepartmentFullySelected(
      dept,
      useFiltered: useFiltered,
    );
    final updatedMembers = List<int>.from(members);
    if (allSelected) {
      for (final u in users) {
        updatedMembers.remove(u.id);
      }
    } else {
      for (final u in users) {
        if (!updatedMembers.contains(u.id)) updatedMembers.add(u.id);
      }
    }
    members.assignAll(updatedMembers);
  }

  @override
  void onClose() {
    _adminTypeWorker?.dispose();
    _visibilityWorker?.dispose();

    memberSearchFocusNode.removeListener(_syncMemberSearchFocus);

    nameController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    memberSearchController.dispose();
    memberSearchFocusNode.dispose();
    startDateController.dispose();
    endDateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();

    _deptExpanded.clear();
    super.onClose();
  }
}
