import 'package:get/get.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/controller/verify_code_controller.dart';

class VerifyCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerifyCodeController>(
      () => VerifyCodeController(repo: Get.find<AuthRepository>()),
    );
  }
}
