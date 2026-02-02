import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';

abstract class EventBuilderBase {
  bool showCategory(AddEventController c);
  bool showMembers(AddEventController c);
  bool showAttendance(AddEventController c);
  bool showAdminType(AddEventController c);

  void applyDefaults(AddEventController c);

  void validate(AddEventController c);

  List<UserEntity> getSelectableMembers(
    UserEntity currentUser,
    List<UserEntity> allUsers,
  );

  List<int> getEffectiveMembers(UserEntity currentUser, AddEventController c);

  EventModel build(AddEventController c);
}
