import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/user_access_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/auth/services/registration_approval_service.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';
import 'package:mow_events/features/notifications/services/notifications_fcm_service.dart';

class AppBootstrapController extends GetxController {
  final AuthController auth = Get.find();
  final UserAccessController accessController = Get.find();

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

    final localUser = auth.user.value;
    await RegistrationApprovalService.reconcileLocalStateWithUser(localUser);

    if (auth.isAuthenticated.value &&
        RegistrationApprovalService.shouldHoldRegistrationApproval(localUser)) {
      if (localUser != null) {
        await RegistrationApprovalService.syncFromUser(localUser);
      }
      NotificationsFcmService.ensureController();
      await NotificationsFcmService.processPendingBackgroundAction();
      Get.offAllNamed(AppRouter.registrationPendingScreen);
      return;
    }

    final storage = AppStorage();
    final remember = storage.rememberMe;

    if (!auth.isAuthenticated.value || remember == false) {
      if (auth.isAuthenticated.value && remember == false) {
        await AuthService.logout();
        auth.user.value = null;
        auth.isAuthenticated.value = false;
      }

      Get.offAllNamed(AppRouter.logInScreen);
      return;
    }

    final startupAccess = await accessController.resolveStartupAccess();

    switch (startupAccess) {
      case StartupAccessResult.unauthenticated:
        Get.offAllNamed(AppRouter.logInScreen);
        return;
      case StartupAccessResult.active:
      case StartupAccessResult.requiresRefresh:
      case StartupAccessResult.inactive:
        Get.offAllNamed(AppRouter.homeScreen);
        return;
    }
  }
}
