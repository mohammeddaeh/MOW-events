import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/http/api_exceptions.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/validator.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';

class ChangePasswordController extends GetxController {
  final AuthRepository repo;

  ChangePasswordController({required this.repo});

  final formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final currentPasswordFocusNode = FocusNode();
  final newPasswordFocusNode = FocusNode();
  final confirmPasswordFocusNode = FocusNode();
  final isLoading = false.obs;
  final canSubmit = false.obs;
  final currentPasswordTouched = false.obs;
  final newPasswordTouched = false.obs;
  final confirmPasswordTouched = false.obs;
  final confirmValidationVersion = 0.obs;

  String? Function(String?) get currentPasswordValidator => AppValidator.required;
  String? Function(String?) get newPasswordValidator =>
      AppValidator.validatePassword;
  AutovalidateMode get currentPasswordAutovalidateMode =>
      currentPasswordTouched.value
      ? AutovalidateMode.always
      : AutovalidateMode.disabled;
  AutovalidateMode get newPasswordAutovalidateMode =>
      newPasswordTouched.value
      ? AutovalidateMode.always
      : AutovalidateMode.disabled;
  AutovalidateMode get confirmPasswordAutovalidateMode =>
      confirmPasswordTouched.value
      ? AutovalidateMode.always
      : AutovalidateMode.disabled;

  @override
  void onInit() {
    super.onInit();
    _bindFocusNode(currentPasswordFocusNode, currentPasswordTouched);
    _bindFocusNode(
      newPasswordFocusNode,
      newPasswordTouched,
      onBlur: _refreshConfirmValidation,
    );
    _bindFocusNode(confirmPasswordFocusNode, confirmPasswordTouched);
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    currentPasswordFocusNode.dispose();
    newPasswordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.onClose();
  }

  String? confirmPasswordValidator(String? value) {
    return AppValidator.validateConfirmPassword(
      value,
      newPasswordController.text,
    );
  }

  void onCurrentPasswordChanged(String? value) {
    _markTouched(currentPasswordTouched, value);
    _updateSubmitAvailability();
  }

  void onNewPasswordChanged(String? value) {
    _markTouched(newPasswordTouched, value);
    _updateSubmitAvailability();
    _refreshConfirmValidation();
  }

  void onConfirmPasswordChanged(String? value) {
    _markTouched(confirmPasswordTouched, value);
    _updateSubmitAvailability();
  }

  void _bindFocusNode(
    FocusNode focusNode,
    RxBool touched, {
    VoidCallback? onBlur,
  }) {
    focusNode.addListener(() {
      if (focusNode.hasFocus) return;
      touched.value = true;
      onBlur?.call();
      _updateSubmitAvailability();
    });
  }

  void _markTouched(RxBool touched, String? value) {
    if (touched.value || (value ?? '').isEmpty) return;
    touched.value = true;
  }

  void _markAllFieldsTouched() {
    currentPasswordTouched.value = true;
    newPasswordTouched.value = true;
    confirmPasswordTouched.value = true;
    _refreshConfirmValidation(force: true);
  }

  void _refreshConfirmValidation({bool force = false}) {
    if (force ||
        confirmPasswordTouched.value ||
        confirmPasswordController.text.isNotEmpty) {
      confirmValidationVersion.value++;
    }
  }

  void _updateSubmitAvailability() {
    canSubmit.value =
        currentPasswordValidator(currentPasswordController.text) == null &&
        newPasswordValidator(newPasswordController.text) == null &&
        confirmPasswordValidator(confirmPasswordController.text) == null;
  }

  Future<void> submit() async {
    _markAllFieldsTouched();
    _updateSubmitAvailability();
    if (!formKey.currentState!.validate() || !canSubmit.value) return;
    if (!InternetGuard.ensureOnline()) return;

    isLoading.value = true;
    try {
      await repo.changePassword(
        oldPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );

      AppSnackBars.hideSnackBar();
      AppSnackBars.successSnackBar(
        title: AppTexts.success,
        message: AppTexts.thePasswordHasBeenSuccessfullyChanged,
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      _updateSubmitAvailability();

      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 120));
      Get.back();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : AppTexts.thePasswordHasNotBeenChanged;
      AppSnackBars.hideSnackBar();
      AppSnackBars.errorSnackBar(
        title: AppTexts.errorOccurred,
        message: message,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
