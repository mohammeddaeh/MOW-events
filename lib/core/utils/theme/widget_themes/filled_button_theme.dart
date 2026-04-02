import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';

class AppFilledButtonTheme {
  AppFilledButtonTheme._();

  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static final lightFilledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      elevation: 0,
      foregroundColor: AppColors.light,
      backgroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.darkGrey,
      disabledBackgroundColor: AppColors.buttonDisabled,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      minimumSize: const Size(0, 48),
      textStyle: _buttonTextStyle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static final darkFilledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      elevation: 0,
      foregroundColor: AppColors.light,
      backgroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.darkGrey,
      disabledBackgroundColor: AppColors.darkGrey,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      minimumSize: const Size(0, 48),
      textStyle: _buttonTextStyle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
