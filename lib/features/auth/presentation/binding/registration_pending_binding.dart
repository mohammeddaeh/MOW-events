import 'package:get/get.dart';
import 'package:mow_events/features/auth/presentation/controller/registration_pending_controller.dart';
import 'package:mow_events/features/notifications/services/notifications_fcm_service.dart';

class RegistrationPendingBinding extends Bindings {
  @override
  void dependencies() {
    NotificationsFcmService.ensureController();

    Get.put<RegistrationPendingController>(
      RegistrationPendingController(),
    );
  }
}
