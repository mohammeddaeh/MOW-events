import 'package:get/get.dart';
import 'package:mow_events/features/event/presentation/controller/edit_event_controller.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

class EditEventBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditEventController>(
      () => EditEventController(homeController: Get.find<HomeController>()),
      fenix: false,
    );
  }
}
