import 'package:get/get.dart';
import 'package:mow_events/features/auth/presentation/controller/login_controller.dart';

class LogInBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(LoginController(), permanent: true);
  }
}
