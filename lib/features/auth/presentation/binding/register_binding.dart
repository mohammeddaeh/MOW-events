import 'package:get/get.dart';
import 'package:mow_events/features/auth/presentation/controller/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterController>(() => RegisterController());
  }
}
