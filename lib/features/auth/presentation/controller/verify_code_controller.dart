import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/utils/http/api_exceptions.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';

class VerifyCodeController extends GetxController {
  final AuthRepository repo;

  VerifyCodeController({required this.repo});

  final codeController = TextEditingController();
  RxBool isLoading = false.obs;
  late final String email;

  @override
  void onInit() {
    email = Get.arguments;
    super.onInit();
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }

  Future<void> verifyCode() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.errorOccurred,
        message: AppTexts.enterTheCode,
      );
      return;
    }

    if (code.length != 5) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.errorOccurred,
        message: AppTexts.otpLengthError.trParams({'length': '${code.length}'}),
      );
      return;
    }

    isLoading.value = true;

    try {
      await repo.verifyResetCode(email, code);

      AppSnackBars.successSnackBar(
        title: AppTexts.success,
        message: AppTexts.theCodeIsCorrect,
      );

      Get.toNamed(
        AppRouter.resetPassword,
        arguments: {'email': email, 'code': code},
      );
    } on ApiException catch (e) {
      final message = e.message.contains("Bad request")
          ? AppTexts.theCodeIsIncorrect
          : e.message;
      AppSnackBars.errorSnackBar(
        title: AppTexts.errorOccurred,
        message: message,
      );
    } catch (e) {
      ErrorHandler.handle(e);
    } finally {
      isLoading.value = false;
    }
  }
}
