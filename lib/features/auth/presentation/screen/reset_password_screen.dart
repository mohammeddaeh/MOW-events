import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/validator.dart';

import 'package:mow_events/features/auth/presentation/controller/reset_password_controller.dart';

class ResetPasswordScreen extends GetView<ResetPasswordController> {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.resetPassword)),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: controller.resetPasswordKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppTexts.enterTheNewPassword),
              SizedBox(height: 20.h),

              AdaptiveFormField(
                type: AdaptiveFieldType.password,
                controller: controller.passController,
                hintText: "********",
                validator: controller.passwordValidator,
              ),
              SizedBox(height: 16.h),

              AdaptiveFormField(
                type: AdaptiveFieldType.password,
                controller: controller.confirmPassController,
                hintText: "********",
                validator: (value) => AppValidator.validateConfirmPassword(
                  value,
                  controller.passController.text,
                ),
              ),
              SizedBox(height: 32.h),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.resetPassword,
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(AppTexts.changePassword),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
