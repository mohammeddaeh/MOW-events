import 'package:get/get.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';

class EditEventBinding extends Bindings {
  @override
  void dependencies() {
    final event = Get.arguments as EventModel?;
    Get.lazyPut<EventFormController>(
      () => EventFormController(mode: EventFormMode.edit, initialEvent: event),
      fenix: false,
    );
  }
}
