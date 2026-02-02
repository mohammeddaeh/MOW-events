import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/validator.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';

class ForgotPasswordController extends GetxController {
  final AuthRepository repo;

  ForgotPasswordController({required this.repo});

  final emailController = TextEditingController();
  final forgotPasswordKey = GlobalKey<FormState>();

  RxBool isLoading = false.obs;
  String? Function(String?) get emailValidator => AppValidator.validateEmail;

  Future<void> sendResetCode() async {
    if (!forgotPasswordKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await repo.sendResetCode(emailController.text.trim());

      AppSnackBars.successSnackBar(
        title: AppTexts.success,
        message: AppTexts.theCodeHasBeenSent,
      );

      Get.toNamed(AppRouter.verifyCode, arguments: emailController.text.trim());
    } catch (e) {
      ErrorHandler.handle(e);
    } finally {
      isLoading.value = false;
    }
  }
}
