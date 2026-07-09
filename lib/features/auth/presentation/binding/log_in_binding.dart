import 'package:get/get.dart';
import 'package:mow_events/features/auth/presentation/controller/login_controller.dart';

class LogInBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoginController>()) {
      Get.lazyPut<LoginController>(() => LoginController());
    }
  }
}
