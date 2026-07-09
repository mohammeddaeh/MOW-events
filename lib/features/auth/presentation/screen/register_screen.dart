import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/adaptive_form_field.dart';
import 'package:mow_events/core/shared/widgets/app_rich_text.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/presentation/controller/register_controller.dart';
import 'package:mow_events/features/auth/presentation/widgets/remember_me_checkbox.dart';

class RegisterScreen extends GetView<RegisterController> {
  RegisterScreen({super.key});

  final NetworkManager network = Get.find();

  bool _isKeyboardVisible(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 0;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final keyboardOpen = _isKeyboardVisible(context);
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
            AnimatedBuilder(
              animation: controller.scrollController,
              builder: (context, _) {
                final scrollOffset = controller.scrollController.hasClients
                    ? controller.scrollController.offset
                    : 0.0;
                final collapseProgress = (scrollOffset / 140).clamp(0.0, 1.0);

                final expandedHeaderHeight = keyboardOpen ? 130.h : 292.h;
                final collapsedHeaderHeight = keyboardOpen ? 102.h : 172.h;
                final headerHeight = lerpDouble(
                  expandedHeaderHeight,
                  collapsedHeaderHeight,
                  collapseProgress,
                )!;

                final expandedLogoHeight = keyboardOpen ? 74.h : 210.h;
                final collapsedLogoHeight = keyboardOpen ? 58.h : 110.h;
                final logoHeight = lerpDouble(
                  expandedLogoHeight,
                  collapsedLogoHeight,
                  collapseProgress,
                )!;

                final expandedHeaderTopGap = keyboardOpen ? 10.h : 18.h;
                final collapsedHeaderTopGap = keyboardOpen ? 6.h : 10.h;
                final headerTopGap = lerpDouble(
                  expandedHeaderTopGap,
                  collapsedHeaderTopGap,
                  collapseProgress,
                )!;

                final expandedHeaderBottomGap = keyboardOpen ? 16.h : 34.h;
                final collapsedHeaderBottomGap = keyboardOpen ? 10.h : 18.h;
                final headerBottomGap = lerpDouble(
                  expandedHeaderBottomGap,
                  collapsedHeaderBottomGap,
                  collapseProgress,
                )!;

                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: headerHeight,
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        top: headerTopGap,
                        bottom: headerBottomGap,
                      ),
                      alignment: Alignment.bottomCenter,
                      child: SvgPicture.asset(
                        AppImages.logoAndName,
                        height: logoHeight,
                      ),
                    ),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: double.infinity,
                        padding: EdgeInsets.only(
                          top: 12.h,
                          right: AppSizes.s24,
                          left: AppSizes.s24,
                        ),

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
                        child: SingleChildScrollView(
                          controller: controller.scrollController,
                          padding: EdgeInsets.only(
                            top: 32.h,
                            bottom: keyboardOpen ? 16.h : 60.h,
                          ),
                          child: Form(
                            key: controller.registerFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  final isResubmit =
                                      controller.isResubmitMode.value;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isResubmit
                                            ? AppTexts.editYourRegistrationTitle
                                            : AppTexts.createYourAccount,
                                        style: TextStyle(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppThemeHelper.whiteBlack(
                                            context,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        isResubmit
                                            ? AppTexts
                                                  .editRegistrationShortDescription
                                            : AppTexts
                                                  .createAccountShortDescription,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          height: 1.4,
                                          color: AppThemeHelper.textSecondary(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                Obx(() {
                                  final reason =
                                      controller.rejectionNotice.value;
                                  if (reason == null || reason.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 16.h),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(14.r),
                                      decoration: BoxDecoration(
                                        color: AppThemeHelper.red(
                                          context,
                                        ).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border: Border.all(
                                          color: AppThemeHelper.red(
                                            context,
                                          ).withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppTexts.registrationRejectionReason,
                                            style: TextStyle(
                                              color: AppThemeHelper.red(
                                                context,
                                              ),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                          SizedBox(height: 6.h),
                                          Text(
                                            reason,
                                            style: TextStyle(
                                              height: 1.4,
                                              fontSize: 13.sp,
                                              color: AppThemeHelper.whiteBlack(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                SizedBox(height: 8.h),
                                Text(
                                  AppTexts.firstName,
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AdaptiveFormField(
                                  controller: controller.firstNameController,
                                  focusNode: controller.firstNameFocus,
                                  type: AdaptiveFieldType.text,
                                  hintText: AppTexts.firstNamePlaceholder,
                                  validator: controller.firstNameValidator,
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(controller.lastNameFocus);
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppTexts.familyName,
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AdaptiveFormField(
                                  controller: controller.lastNameController,
                                  focusNode: controller.lastNameFocus,
                                  type: AdaptiveFieldType.text,
                                  hintText: AppTexts.familyNamePlaceholder,
                                  validator: controller.lastNameValidator,
                                  prefixIcon: const Icon(Icons.person_rounded),
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(controller.emailFocus);
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppTexts.email,
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AdaptiveFormField(
                                  controller: controller.emailController,
                                  focusNode: controller.emailFocus,
                                  type: AdaptiveFieldType.email,
                                  hintText: AppTexts.emailPlaceholder,
                                  validator: controller.emailValidator,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(controller.phoneFocus);
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppTexts.phoneNumber,
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AdaptiveFormField(
                                  controller: controller.phoneController,
                                  focusNode: controller.phoneFocus,
                                  type: AdaptiveFieldType.phone,
                                  hintText: AppTexts.syrianPhonePlaceholder,
                                  validator: controller.phoneValidator,
                                  prefixIcon: const Icon(
                                    Icons.phone_android_rounded,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(controller.passwordFocus);
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppTexts.section,
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Obx(() {
                                  if (controller.isLoadingDepartments.value) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final loadError =
                                      controller.departmentsLoadError.value;
                                  final hasBackendError =
                                      loadError != null && loadError.isNotEmpty;
                                  final canSelectDepartment =
                                      controller.departments.isNotEmpty &&
                                      !hasBackendError;
                                  final errorColor = AppThemeHelper.red(
                                    context,
                                  );
                                  final borderColor = hasBackendError
                                      ? errorColor
                                      : AppThemeHelper.border(context);

                                  OutlineInputBorder outline({
                                    double width = 1.2,
                                  }) => OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: borderColor,
                                      width: width.w,
                                    ),
                                    borderRadius: BorderRadius.circular(10.r),
                                  );

                                  Widget buildDropdown() {
                                    return DropdownButtonFormField<int>(
                                      isExpanded: true,
                                      value: controller
                                          .selectedDepartmentId.value,
                                      decoration: InputDecoration(
                                        hintText: hasBackendError
                                            ? AppTexts.tapDepartmentToRetry
                                            : AppTexts.chooseDepartment,
                                        hintStyle: TextStyle(
                                          color: hasBackendError
                                              ? errorColor.withValues(
                                                  alpha: 0.8,
                                                )
                                              : AppThemeHelper.hintTextGrey(
                                                  context,
                                                ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.apartment_outlined,
                                          color: hasBackendError
                                              ? errorColor
                                              : null,
                                        ),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
                                        border: outline(),
                                        enabledBorder: outline(),
                                        focusedBorder: outline(width: 1.8),
                                        errorBorder: outline(width: 1.5),
                                        focusedErrorBorder: outline(
                                          width: 1.8,
                                        ),
                                      ),
                                      selectedItemBuilder: (context) =>
                                          controller.departments
                                              .map(
                                                (d) => Align(
                                                  alignment: AlignmentDirectional
                                                      .centerStart,
                                                  child: Text(
                                                    d.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      items: controller.departments
                                          .map(
                                            (d) => DropdownMenuItem<int>(
                                              value: d.id,
                                              child: Text(
                                                d.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: canSelectDepartment
                                          ? (value) {
                                              controller
                                                      .selectedDepartmentId
                                                      .value =
                                                  value;
                                              controller.departmentsLoadError
                                                  .value = null;
                                            }
                                          : null,
                                      validator: (_) {
                                        if (hasBackendError) {
                                          return AppTexts.departmentRequired;
                                        }
                                        return controller.departmentValidator(
                                          controller
                                              .selectedDepartmentId.value,
                                        );
                                      },
                                    );
                                  }

                                  final departmentField = Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: buildDropdown()),
                                      IconButton(
                                        onPressed: () => controller
                                            .loadDepartments(
                                          showSnackBarOnError: true,
                                        ),
                                        icon: const Icon(Icons.refresh_rounded),
                                      ),
                                    ],
                                  );

                                  final fieldWithTap = canSelectDepartment
                                      ? departmentField
                                      : GestureDetector(
                                          onTap: controller.onDepartmentFieldTap,
                                          behavior: HitTestBehavior.opaque,
                                          child: departmentField,
                                        );

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      fieldWithTap,
                                      if (hasBackendError) ...[
                                        SizedBox(height: 6.h),
                                        Text(
                                          loadError,
                                          style: TextStyle(
                                            color: errorColor,
                                            fontSize: 12.sp,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                }),
                                const SizedBox(height: 12),
                                Obx(
                                  () => RememberMeCheckbox(
                                    value: controller.isManager.value,
                                    onChanged: (value) =>
                                        controller.isManager.value = value,
                                    title: Text(
                                      AppTexts.registerAsManager,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppThemeHelper.textSecondary(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
                                  controller: controller.passwordController,
                                  focusNode: controller.passwordFocus,
                                  type: AdaptiveFieldType.password,
                                  validator: controller.passwordValidator,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(
                                      controller.confirmPasswordFocus,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppTexts.confirmNewPassword,
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AdaptiveFormField(
                                  controller:
                                      controller.confirmPasswordController,
                                  focusNode: controller.confirmPasswordFocus,
                                  type: AdaptiveFieldType.password,
                                  validator:
                                      controller.confirmPasswordValidator,
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: Obx(() {
                                    final elevatedButton = ElevatedButton(
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
                                          : controller.register,
                                      child: Ink(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
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
                                              : Obx(
                                                  () => Text(
                                                    network.isOnline.value
                                                        ? (controller
                                                                  .isResubmitMode
                                                                  .value
                                                              ? AppTexts
                                                                    .resubmitRegistrationRequest
                                                              : AppTexts
                                                                    .createAccount)
                                                        : AppTexts
                                                              .internetRequired,
                                                    style: TextStyle(
                                                      fontSize: 18.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      height: 1.25,
                                                      leadingDistribution:
                                                          TextLeadingDistribution
                                                              .even,
                                                    ),
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
                                  child: InkWell(
                                    onTap: controller.goToLogin,
                                    child: AppRichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                '${AppTexts.alreadyHaveAccount} ',
                                            style: TextStyle(
                                              fontSize: 12.h,
                                              color: AppThemeHelper
                                                  .textSecondary(context),
                                            ),
                                          ),
                                          TextSpan(
                                            text: AppTexts.login,
                                            style: TextStyle(
                                              color: accentColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
