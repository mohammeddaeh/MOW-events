import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';

class AppOutlinedButtonTheme {
  AppOutlinedButtonTheme._();  

  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    leadingDistribution: TextLeadingDistribution.even,
  );

   static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: AppColors.dark,
      side: const BorderSide(color: AppColors.borderPrimary),
      textStyle: _buttonTextStyle,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

   static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.light,
      side: const BorderSide(color: AppColors.primary),
      textStyle: _buttonTextStyle,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
