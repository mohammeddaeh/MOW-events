import 'package:get/get.dart';
import 'package:mow_events/features/event/presentation/controller/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettingsController());
  }
}
