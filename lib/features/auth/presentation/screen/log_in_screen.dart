 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/presentation/controller/login_controller.dart';
import 'package:mow_events/features/auth/presentation/widgets/remember_me_checkbox.dart';

class LogInScreen extends GetView<LoginController> {
  LogInScreen({super.key});
  final NetworkManager network = Get.find();

  bool _isKeyboardVisible(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 0;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,

        body: Stack(
          children: [
            Container(
              color: AppColors.primary,
              width: double.infinity,
              height: double.infinity,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Obx(() {
                bool keyboardOpen = _isKeyboardVisible(context);
                return SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          AppImages.logoAndName,
                          height: keyboardOpen ? 80.h : 210.h,
                        ),
                      ),
                      SizedBox(height: 32.h),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: EdgeInsets.symmetric(horizontal: AppSizes.s24),
                        decoration: BoxDecoration(
                          color: AppThemeHelper.blackWhite(context),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10.r,
                              offset: Offset(0, -4.h),
                            ),
                          ],
                        ),
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 400),
                          padding: EdgeInsets.only(
                            top: 32.h,
                            bottom: keyboardOpen ? 0 : 100.h,
                          ),
                          child: Form(
                            key: controller.loginFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTexts.email,
                                  style: TextStyle(
                                    color: AppThemeHelper.greyprimary(
                                      context,
                                    ).withOpacity(0.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AdaptiveFormField(
                                  type: AdaptiveFieldType.email,
                                  hintText: 'example@gmail.com',

                                  focusNode: controller.emailFocus,
                                  controller: controller.emailController,
                                  validator: controller.emailValidator,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(controller.passwordFocus);
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppTexts.password,
                                  style: TextStyle(
                                    color: AppThemeHelper.greyprimary(
                                      context,
                                    ).withOpacity(0.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AdaptiveFormField(
                                  type: AdaptiveFieldType.password,
                                  focusNode: controller.passwordFocus,
                                  controller: controller.passwordController,
                                  validator: controller.passwordValidator,
                                ),
                                SizedBox(height: 12.h),
                                InkWell(
                                  onTap: () =>
                                      Get.toNamed(AppRouter.forgotPassword),
                                  child: Text(
                                    AppTexts.forgotMyPassword,
                                    style: TextStyle(
                                      color: AppThemeHelper.whiteBlack(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Obx(
                                  () => RememberMeCheckbox(
                                    initialValue: controller.rememberMe.value,
                                    storageKey: 'remember_me',
                                    onChanged: (v) =>
                                        controller.toggleRememberMe(v),
                                    title: Text(
                                      AppTexts.rememberMe,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppThemeHelper.whiteBlack(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,

                                  child: Obx(() {
                                    var elevatedButton = ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          controller.isLoading.value ||
                                              !network.isOnline.value
                                          ? null
                                          : controller.login,

                                      child: Ink(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.secondary,
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: controller.isLoading.value
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                              : Text(
                                                  network.isOnline.value
                                                      ? AppTexts.login
                                                      : AppTexts
                                                            .internetRequired,
                                                  style: TextStyle(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    );
                                    return elevatedButton;
                                  }),
                                ),
                                SizedBox(height: 16.h),
                                Center(
                                  child: TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      AppTexts.logInPhone,
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
