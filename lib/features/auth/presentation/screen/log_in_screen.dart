import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/shared/widgets/app_rich_text.dart';
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
    final secondaryText = AppThemeHelper.greyprimary(
      context,
    ).withValues(alpha: 0.5);
    final accentColor = AppThemeHelper.accent(context);

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
                            bottom: keyboardOpen ? 0 : 60.h,
                          ),
                          child: Form(
                            key: controller.loginFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  final isPhoneLogin =
                                      controller.isPhoneLogin.value;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        controller.identifierLabel,
                                        style: TextStyle(
                                          color: secondaryText,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 320,
                                        ),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0.08, 0),
                                                end: Offset.zero,
                                              ).animate(animation),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: AdaptiveFormField(
                                          key: ValueKey(
                                            isPhoneLogin
                                                ? 'phone-login-field'
                                                : 'email-login-field',
                                          ),
                                          type: isPhoneLogin
                                              ? AdaptiveFieldType.phone
                                              : AdaptiveFieldType.email,
                                          hintText: controller.identifierHint,
                                          focusNode: controller.identifierFocus,
                                          controller:
                                              controller.identifierController,
                                          validator: isPhoneLogin
                                              ? controller.phoneValidator
                                              : controller.emailValidator,
                                          prefixIcon: Icon(
                                            isPhoneLogin
                                                ? Icons.phone_android_rounded
                                                : Icons.email_outlined,
                                          ),
                                          inputFormatters: isPhoneLogin
                                              ? [
                                                  FilteringTextInputFormatter.allow(
                                                    RegExp(r'[0-9]'),
                                                  ),
                                                  LengthLimitingTextInputFormatter(
                                                    10,
                                                  ),
                                                ]
                                              : null,
                                          onFieldSubmitted: (_) {
                                            FocusScope.of(context).requestFocus(
                                              controller.passwordFocus,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 16),
                                Text(
                                  AppTexts.password,
                                  style: TextStyle(
                                    color: secondaryText,
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
                                    value: controller.rememberMe.value,
                                    onChanged: controller.toggleRememberMe,
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
                                                    height: 1.25,
                                                    leadingDistribution:
                                                        TextLeadingDistribution
                                                            .even,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    );
                                    return elevatedButton;
                                  }),
                                ),
                                SizedBox(height: 24.h),
                                Center(
                                  child: InkWell(
                                    onTap: controller.toggleLoginMethod,
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.w,
                                        vertical: 6.h,
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        transitionBuilder: (child, animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },

                                        child: Obx(
                                          () => Text(
                                            key: ValueKey(
                                              controller.switchLoginMethodLabel,
                                            ),
                                            controller.switchLoginMethodLabel,
                                            style: TextStyle(
                                              color: accentColor,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12.h),

                                Center(
                                  child: InkWell(
                                    onTap: controller.openRegister,
                                    child: AppRichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                '${AppTexts.dontHaveAccount} ',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color:
                                                  AppThemeHelper.textSecondary(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                          TextSpan(
                                            text: AppTexts.createAccount,
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: accentColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 23.h),
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
