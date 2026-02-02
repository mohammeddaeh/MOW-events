import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';

class AppBootstrapController extends GetxController {
  final AuthController auth = Get.find();
  final NetworkManager network = Get.find();
  @override
  void onInit() {
    super.onInit();
    Get.put(ReminderController(), permanent: true);
  }

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    auth.loadFromLocal();
    final remember = await AppStorage().rememberMe;

    if (!auth.isAuthenticated.value || remember == false) {
      Get.offAllNamed(AppRouter.logInScreen);
      return;
    }

    Get.offAllNamed(AppRouter.homeScreen);

    await Future.delayed(Duration.zero);
  }
}
