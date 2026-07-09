import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/theme/theme_controller.dart';

class AppThemeHelper {
  AppThemeHelper._();

  static Brightness currentBrightness(BuildContext context) {
    switch (ThemeController.instance.currentThemeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
    }
  }

  static Color background(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.black
      : AppColors.white;

  static Color scaffoldColor(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.black
      : AppColors.white;

  static Color whitePrimary(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.white
      : AppColors.primary;

  static Color whiteBlack(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.white
      : AppColors.black;

  static Color blackWhite(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.black
      : AppColors.white;
  static Color blackPrimary(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.black
      : AppColors.primary;

  static Color whiteWhite(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.white
      : AppColors.white;

  static Color blackBblack(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.black
      : AppColors.black;

  static Color greyprimary(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.grey
      : AppColors.primary;
  static Color grey(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.grey
      : AppColors.grey;
  static Color hintTextGrey(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.grey.withAlpha(80)
      : AppColors.grey;
  static Color gold(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.gold
      : AppColors.gold;

  static Color textSecondary(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.textGray.withOpacity(0.7)
      : AppColors.textGray;

  static Color accent(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.gold
      : AppColors.accent;

  static Color border(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? Colors.grey.shade700
      : Colors.grey.shade300;

  static Color buttonPrimary(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.gold
      : AppColors.primary;

  static Color buttonSecondary(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.grey
      : Colors.grey.shade400;

  static Color bottomNav(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.darkBottomBar
      : AppColors.white;
  static Color red(BuildContext context) =>
      currentBrightness(context) == Brightness.dark
      ? AppColors.errorPrimary.withOpacity(0.8)
      : AppColors.errorSecondary;
}
