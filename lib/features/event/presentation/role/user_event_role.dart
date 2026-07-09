import 'package:mow_events/core/utils/helpers/event_date_time_helper.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';
import 'package:mow_events/features/event/presentation/role/event_role.dart';

class UserEventBuilder extends EventBuilderBase {
  @override
  void applyDefaults(EventFormController c) {
    c.isPrivate.value = 1;
    c.isPublic.value = 0;
  }

  @override
  bool showCategory(EventFormController c) => false;

  @override
  bool showMembers(EventFormController c) => false;

  @override
  bool showAttendance(EventFormController c) => false;

  @override
  bool showAdminType(EventFormController c) => false;

  @override
  void validate(EventFormController c) {}

  @override
  List<UserEntity> getSelectableMembers(
    UserEntity currentUser,
    List<UserEntity> allUsers,
  ) => [];

  @override
  List<int> getEffectiveMembers(UserEntity currentUser, EventFormController c) =>
      [];

  @override
  EventModel build(EventFormController c) {
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
      category: null,
      isPublic: 0,
      isPrivate: 1,
      members: [],
      userCurrentInMembers: false,
      reminders: c.reminders.toList(),
      rawReminders: [],
      createdAt: DateTime.now().toString(),
      alarmTimeIso: null,
      isAlarmEnabled: false,
      snoozeDurationMinutes: 10,
    );
  }
}
