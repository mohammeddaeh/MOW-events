import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';

abstract class EventBuilderBase {
  bool showCategory(EventFormController c);
  bool showMembers(EventFormController c);
  bool showAttendance(EventFormController c);
  bool showAdminType(EventFormController c);

  void applyDefaults(EventFormController c);

  void validate(EventFormController c);

  List<UserEntity> getSelectableMembers(
    UserEntity currentUser,
    List<UserEntity> allUsers,
  );

  List<int> getEffectiveMembers(UserEntity currentUser, EventFormController c);

  EventModel build(EventFormController c);
}
