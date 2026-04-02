import 'package:get/get.dart';
import 'package:mow_events/core/utils/helpers/event_date_time_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';
import 'package:mow_events/features/event/presentation/role/event_role.dart';

class ManagerEventBuilder extends EventBuilderBase {
  @override
  void applyDefaults(AddEventController c) {
    c.visibility.value = EventVisibility.private;
    c.isPrivate.value = 1;
    c.isPublic.value = 0;
  }

  @override
  bool showCategory(AddEventController c) =>
      c.visibility.value == EventVisibility.included;

  @override
  bool showMembers(AddEventController c) =>
      c.visibility.value == EventVisibility.included;

  @override
  bool showAttendance(AddEventController c) => false;

  @override
  bool showAdminType(AddEventController c) => false;

  @override
  void validate(AddEventController c) {
    if (showMembers(c) && c.members.isEmpty) {
      throw Exception(AppTexts.chooseMembersForTheEvent);
    }
    if (showCategory(c)) {
      final catId = c.selectedCategoryId.value;
      if (catId == null) {
        throw Exception(AppTexts.selectCategory);
      }
      final hasMatch = Get.find<CategoriesController>().categories.any(
        (e) => e.id == catId,
      );
      if (!hasMatch) {
        throw Exception(AppTexts.selectCategory);
      }
    }
  }

  @override
  List<UserEntity> getSelectableMembers(
    UserEntity currentUser,
    List<UserEntity> allUsers,
  ) {
    return allUsers
        .where((u) => u.department?.id == currentUser.department?.id)
        .toList();
  }

  @override
  List<int> getEffectiveMembers(UserEntity currentUser, AddEventController c) =>
      c.members.toList();

  @override
  EventModel build(AddEventController c) {
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
      category: () {
        if (!showCategory(c)) return null;
        final list = Get.find<CategoriesController>().categories
            .where((e) => e.id == c.selectedCategoryId.value)
            .toList();
        return list.isNotEmpty ? list.first : null;
      }(),

      isPublic: 0,
      isPrivate: c.visibility.value == EventVisibility.private ? 1 : 0,
      members: getEffectiveMembers(c.currentUser, c),
      userCurrentInMembers: c.visibility.value == EventVisibility.included
          ? true
          : c.userCurrentInMembers.value,
      reminders: c.reminders.toList(),
      rawReminders: [],
      createdAt: DateTime.now().toString(),
    );
  }
}
