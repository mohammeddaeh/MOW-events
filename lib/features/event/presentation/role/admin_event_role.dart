import 'package:get/get.dart';
import 'package:mow_events/core/utils/helpers/event_date_time_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';
import 'package:mow_events/features/event/presentation/role/event_role.dart';

class AdminEventBuilder extends EventBuilderBase {
  @override
  void applyDefaults(AddEventController c) {
    c.adminEventType.value = AdminEventType.private;
    c.isPrivate.value = 1;
    c.isPublic.value = 0;
  }

  @override
  bool showCategory(AddEventController c) =>
      c.adminEventType.value != AdminEventType.private;

  @override
  bool showMembers(AddEventController c) =>
      c.adminEventType.value == AdminEventType.included;

  @override
  bool showAttendance(AddEventController c) =>
      c.adminEventType.value == AdminEventType.included;

  @override
  bool showAdminType(AddEventController c) => true;

  @override
  void validate(AddEventController c) {
    if (c.adminEventType.value == AdminEventType.included &&
        c.members.isEmpty) {
      throw Exception(AppTexts.employeesMustBeSelected);
    }

    if (showCategory(c) && c.selectedCategoryId.value == null) {
      throw Exception(AppTexts.selectCategory);
    }
  }

  @override
  List<UserEntity> getSelectableMembers(
    UserEntity currentUser,
    List<UserEntity> allUsers,
  ) => allUsers;

  @override
  EventModel build(AddEventController c) {
    final type = c.adminEventType.value;

    final category = showCategory(c)
        ? Get.find<CategoriesController>().categories.firstWhere(
            (e) => e.id == c.selectedCategoryId.value,
          )
        : null;

    return EventModel(
      id: 0,
      name: c.nameController.text,
      location: c.locationController.text,
      description: c.descriptionController.text,
      startDate: EventDateTimeHelper.formatDate(c.selectedStartDate.value!),
      startTime: EventDateTimeHelper.formatTimeHhMm(c.selectedStartTime.value!),
      endDate: EventDateTimeHelper.formatDate(c.selectedEndDate.value!),
      endTime: EventDateTimeHelper.formatTimeHhMm(c.selectedEndTime.value!),
      status: 'active',
      category: category,
      isPublic: type == AdminEventType.public ? 1 : 0,
      isPrivate: type == AdminEventType.private ? 1 : 0,
      members: c.adminEventType.value == AdminEventType.included
          ? c.members.toList()
          : [],
      userCurrentInMembers: c.adminEventType.value == AdminEventType.included
          ? c.userCurrentInMembers.value
          : false,

      reminders: c.reminders.toList(),
      rawReminders: [],
      createdAt: DateTime.now().toString(),
    );
  }

  @override
  List<int> getEffectiveMembers(UserEntity currentUser, AddEventController c) {
    throw UnimplementedError();
  }
}
