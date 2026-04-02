import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/presentation/controller/change_password_controller.dart';

class ChangePasswordScreen extends GetView<ChangePasswordController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = AppThemeHelper.background(context);
    final textColor = AppThemeHelper.whiteBlack(context);
    final borderColor = AppThemeHelper.border(context);
    final sectionColor = AppThemeHelper.blackWhite(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppTexts.changePassword, style: TextStyle(color: textColor)),
        centerTitle: true,
        backgroundColor: sectionColor,
        elevation: 1,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppTexts.changePasswordDescription,
                  style: TextStyle(
                    color: AppThemeHelper.textSecondary(context),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => AdaptiveFormField(
                    controller: controller.currentPasswordController,
                    focusNode: controller.currentPasswordFocusNode,
                    type: AdaptiveFieldType.password,
                    label: AppTexts.currentPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: controller.currentPasswordValidator,
                    onChanged: controller.onCurrentPasswordChanged,
                    autovalidateMode:
                        controller.currentPasswordAutovalidateMode,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => AdaptiveFormField(
                    controller: controller.newPasswordController,
                    focusNode: controller.newPasswordFocusNode,
                    type: AdaptiveFieldType.password,
                    label: AppTexts.newPassword,
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    validator: controller.newPasswordValidator,
                    onChanged: controller.onNewPasswordChanged,
                    autovalidateMode: controller.newPasswordAutovalidateMode,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final validationTick = controller.confirmValidationVersion.value;
                  return AdaptiveFormField(
                    key: ValueKey(validationTick),
                    controller: controller.confirmPasswordController,
                    focusNode: controller.confirmPasswordFocusNode,
                    type: AdaptiveFieldType.password,
                    label: AppTexts.confirmNewPassword,
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    validator: controller.confirmPasswordValidator,
                    onChanged: controller.onConfirmPasswordChanged,
                    autovalidateMode:
                        controller.confirmPasswordAutovalidateMode,
                    borderColor: borderColor,
                  );
                }),
                const SizedBox(height: 32),
                Obx(
                  () => SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          controller.isLoading.value || !controller.canSubmit.value
                          ? null
                          : controller.submit,
                      icon: controller.isLoading.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_reset_rounded, size: 20),
                      label: Text(AppTexts.changePassword),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
