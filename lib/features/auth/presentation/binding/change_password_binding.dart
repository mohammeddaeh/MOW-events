import 'package:get/get.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/controller/change_password_controller.dart';

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChangePasswordController>(
      () => ChangePasswordController(repo: Get.find<AuthRepository>()),
    );
  }
}
