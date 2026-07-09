import 'package:get/get.dart';
import 'package:mow_events/features/event/presentation/controller/add_event_controller.dart';

class AddEventBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventFormController>(
      () => EventFormController(mode: EventFormMode.create),
      fenix: false,
    );
  }
}
