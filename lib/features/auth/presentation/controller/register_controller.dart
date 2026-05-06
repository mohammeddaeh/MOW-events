import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/validator/validator.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/login_controller.dart';

class RegisterController extends GetxController {
  final registerFormKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final firstNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final emailFocus = FocusNode();
  final phoneFocus = FocusNode();
  final addressFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();

  final AuthController authController = Get.find<AuthController>();

  final RxBool isLoading = false.obs;

  String? Function(String?) get firstNameValidator => AppValidator.required;
  String? Function(String?) get lastNameValidator => AppValidator.required;
  String? Function(String?) get emailValidator => AppValidator.validateEmail;
  String? Function(String?) get phoneValidator =>
      AppValidator.validatePhoneNumber;
  String? Function(String?) get passwordValidator =>
      AppValidator.validatePassword;

  String? confirmPasswordValidator(String? value) {
    return AppValidator.validateConfirmPassword(
      value,
      passwordController.text.trim(),
    );
  }

  void goToLogin() {
    if (Get.previousRoute == AppRouter.logInScreen) {
      Get.back();
      return;
    }

    Get.offAllNamed(AppRouter.logInScreen);
  }

  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) return;
    if (!InternetGuard.ensureOnline()) return;

    Get.focusScope?.unfocus();
    isLoading.value = true;

    try {
      final normalizedPhone = AppValidator.normalizePhoneNumber(
        phoneController.text,
      );

      final result = await ErrorHandler.safeCall(() async {
        await authController.register(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          email: emailController.text.trim(),
          phone: normalizedPhone,
          password: passwordController.text.trim(),
          passwordConfirmation: confirmPasswordController.text.trim(),
          address: addressController.text.trim().isEmpty
              ? null
              : addressController.text.trim(),
        );
        return true;
      });

      if (result == true) {
        if (Get.isRegistered<LoginController>()) {
          Get.find<LoginController>().prefillAfterRegistration(
            email: emailController.text.trim(),
            phone: normalizedPhone,
          );
        }

        goToLogin();
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    addressFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.onClose();
  }
}
