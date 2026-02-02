import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/presentation/controller/forgot_password_controller.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.iForgotMyPassword)),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: controller.forgotPasswordKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTexts.enterYourEmailAddressToReceiveTheVerificationCode,
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 20.h),

              AdaptiveFormField(
                type: AdaptiveFieldType.email,
                controller: controller.emailController,
                validator: controller.emailValidator,
                hintText: 'example@gmail.com',
              ),

              SizedBox(height: 32.h),

              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.sendResetCode,
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(AppTexts.sendTheCode),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
