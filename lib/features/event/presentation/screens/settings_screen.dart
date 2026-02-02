// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_locale_controller.dart';
import 'package:mow_events/core/utils/theme/theme_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/event/presentation/widgets/custom_card_setting.dart';
import 'package:mow_events/core/shared/widgets/gradient_text.dart';
import 'package:mow_events/features/event/presentation/screens/add_reminders_screen.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});
  final network = Get.find<NetworkManager>();

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser!.toEntity();
    final localeController = Get.find<AppLocaleController>();
    final themeController = Get.find<ThemeController>();
    final authController = Get.find<AuthController>();

    return Obx(() {
      final userFullName =
          '${authController.user.value?.firstName} ${authController.user.value?.lastName}';
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  AppTexts.settings,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),

                CustomCardSetting(
                  title: userFullName,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: userFullName));
                          Get.snackbar(
                            AppTexts.copied,
                            AppTexts.theNameWasCopiedToTheClipboard,
                          );
                        },
                        child: GradientText(title: AppTexts.copy),
                      ),
                      SizedBox(width: 8),
                      InkWell(
                        onTap: () => Get.toNamed(AppRouter.profile),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: AppThemeHelper.blackBblack(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (currentUser.isAdmin == true ||
                    currentUser.department?.isManager == true)
                  CustomCardSetting(
                    title: AppTexts.manageCategories,
                    trailing: InkWell(
                      onTap: () {
                        Get.toNamed(AppRouter.categoriesPage);
                      },

                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: AppThemeHelper.blackBblack(context),
                      ),
                    ),
                  ),

                Obx(() {
                  return CustomCardSetting(
                    title: AppTexts.dateFormat,

                    options: ['gregorian', 'hijri', 'both'],
                    currentValue: DateLocalizationHelper.userCalendar.value,
                    onSelected: (val) {
                      DateLocalizationHelper.save(val);
                    },
                  );
                }),
                Obx(() {
                  return CustomCardSetting(
                    iconData: Icons.language_outlined,
                    title: AppTexts.language,
                    options: ['ar', 'en'],
                    currentValue: localeController.currentLang.value,
                    onSelected: (val) {
                      localeController.changeLang(val);
                    },
                  );
                }),

                Obx(() {
                  return CustomCardSetting(
                    iconData: themeController.getThemeIcon(
                      themeController.storedTheme.value,
                    ),

                    title: AppTexts.theme,
                    options: const ['light', 'dark', 'system'],
                    currentValue: themeController.storedTheme.value,
                    onSelected: (val) {
                      themeController.changeTheme(val);
                    },
                  );
                }),
                CustomCardSetting(
                  iconData: Icons.alarm,
                  title: AppTexts.reminders,
                  trailing: InkWell(
                    onTap: () {
                      Get.to(() => const AddRemindersScreen());
                    },
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: AppThemeHelper.blackBblack(context),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text('v1', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                OutlinedButton.icon(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: AppColors.errorSecondary,
                    size: 22,
                  ),
                  label: Text(
                    AppTexts.logOut,
                    style: TextStyle(
                      color: AppColors.errorPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.errorSecondary,
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    overlayColor: Theme.of(
                      context,
                    ).colorScheme.error.withOpacity(0.08),
                    textStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      letterSpacing: 0.3,
                    ),
                  ),
                  iconAlignment: IconAlignment.start,
                  onPressed: network.isOnline.value
                      ? authController.logout
                      : () {
                          AppSnackBars.errorSnackBar(
                            title: AppTexts.noInternet,
                            message: AppTexts.internetRequiredToLogout,
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
