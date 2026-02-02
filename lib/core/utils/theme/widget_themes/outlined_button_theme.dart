import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';

/* -- Light & Dark Outlined Button Themes -- */
class AppOutlinedButtonTheme {
  AppOutlinedButtonTheme._(); //To avoid creating instances

  /* -- Light Theme -- */
  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: AppColors.dark,
      side: const BorderSide(color: AppColors.borderPrimary),
      textStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.black,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  /* -- Dark Theme -- */
  static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.light,
      side: const BorderSide(color: AppColors.primary),
      textStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.white,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
