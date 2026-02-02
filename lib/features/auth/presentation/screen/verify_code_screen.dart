import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/validator.dart';
import 'package:mow_events/features/auth/presentation/controller/verify_code_controller.dart';

class VerifyCodeScreen extends GetView<VerifyCodeController> {
  const VerifyCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.confirmTheCode)),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppTexts.enterTheVerificationCodeSentToYourEmail),
            SizedBox(height: 20.h),

            AdaptiveFormField(
              type: AdaptiveFieldType.password,
              controller: controller.codeController,
              hintText: "123456",
              validator: (value) =>
                  AppValidator.validateOtpCode(value, length: 5),
            ),

            SizedBox(height: 32.h),

            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.verifyCode,
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(AppTexts.verification),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
