import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/validator/validator.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/notifications/presentation/controller/notifications_controller.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();
  RxBool rememberMe = false.obs;
  RxBool isLoading = false.obs;

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  final appStorage = AppStorage();
  final AuthController authController = Get.find<AuthController>();

  String? Function(String?) get emailValidator => AppValidator.validateEmail;
  String? Function(String?) get passwordValidator =>
      AppValidator.validatePassword;

  @override
  void onReady() async {
    emailController.clear();
    passwordController.clear();

    rememberMe.value = appStorage.rememberMe;

    super.onReady();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void login() async {
    if (!loginFormKey.currentState!.validate()) return;
    if (!InternetGuard.ensureOnline()) return;

    Get.focusScope?.unfocus();
    isLoading.value = true;

    try {
      final result = await ErrorHandler.safeCall(() async {
        await authController.login(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
        return true;
      });
      await appStorage.setRememberMe(rememberMe.value);

      if (result == true) {
        Get.offAllNamed(AppRouter.homeScreen);

        final notificationsController = Get.find<NotificationsController>();
        await notificationsController.syncFcmTokenWithUser();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void toggleRememberMe(bool value) async {
    rememberMe.value = value;

    await appStorage.setRememberMe(value);
  }
}
