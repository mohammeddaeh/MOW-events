import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/utils/http/api_exceptions.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/validator.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/binding/log_in_binding.dart';
import 'package:mow_events/features/auth/presentation/screen/log_in_screen.dart';

class ResetPasswordController extends GetxController {
  final AuthRepository repo;

  ResetPasswordController({required this.repo});

  final passController = TextEditingController();
  final confirmPassController = TextEditingController();

  final resetPasswordKey = GlobalKey<FormState>();

  RxBool isLoading = false.obs;

  late final String email;
  late final String code;

  String? Function(String?) get passwordValidator =>
      AppValidator.validatePassword;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args == null || args['email'] == null || args['code'] == null) {
      throw ApiException(AppTexts.missingEmailOrCodeForResetPassword);
    }
    email = args['email'];
    code = args['code'];
  }

  @override
  void onClose() {
    passController.dispose();
    confirmPassController.dispose();
    super.onClose();
  }

  Future<void> resetPassword() async {
    if (!resetPasswordKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await repo.resetPassword(email, code, passController.text.trim());

      AppSnackBars.successSnackBar(
        title: AppTexts.success,
        message: AppTexts.thePasswordHasBeenSuccessfullyChanged,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 80));

      Get.offAll(() => LogInScreen(), binding: LogInBinding());
    } catch (e) {
      ErrorHandler.handle(e);
    } finally {
      isLoading.value = false;
    }
  }
}
