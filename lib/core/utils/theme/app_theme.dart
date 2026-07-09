import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/theme/widget_themes/appbar_theme.dart';
import 'package:mow_events/core/utils/theme/widget_themes/bottom_sheet_theme.dart';
import 'package:mow_events/core/utils/theme/widget_themes/checkbox_theme.dart';
import 'package:mow_events/core/utils/theme/widget_themes/chip_theme.dart';
import 'package:mow_events/core/utils/theme/widget_themes/elevated_button_theme.dart';
import 'package:mow_events/core/utils/theme/widget_themes/filled_button_theme.dart';
import 'package:mow_events/core/utils/theme/widget_themes/outlined_button_theme.dart';
import 'package:mow_events/core/utils/theme/widget_themes/text_field_theme.dart';
import 'package:mow_events/core/utils/theme/widget_themes/text_theme.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String appFontFamily = 'Arabic';

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: appFontFamily,
    disabledColor: AppColors.grey,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light().copyWith(primary: AppColors.primary),
    textTheme: AppTextTheme.lightTextTheme.apply(fontFamily: appFontFamily),
    primaryTextTheme: AppTextTheme.lightTextTheme.apply(
      fontFamily: appFontFamily,
    ),
    chipTheme: AppChipTheme.lightChipTheme,
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: AppAppBarTheme.lightAppAppBarTheme,
    checkboxTheme: AppCheckboxTheme.lightCheckboxTheme,
    bottomSheetTheme: AppBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.lightElevatedButtonTheme,
    filledButtonTheme: AppFilledButtonTheme.lightFilledButtonTheme,
    outlinedButtonTheme: AppOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: AppTextFormFieldTheme.lightInputDecorationTheme,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: Color(0x33223F3A),
      selectionHandleColor: AppColors.primary,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: appFontFamily,
    disabledColor: AppColors.grey,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark().copyWith(primary: AppColors.primary),
    textTheme: AppTextTheme.darkTextTheme.apply(fontFamily: appFontFamily),
    primaryTextTheme: AppTextTheme.darkTextTheme.apply(
      fontFamily: appFontFamily,
    ),
    chipTheme: AppChipTheme.darkChipTheme,
    scaffoldBackgroundColor: AppColors.black,
    appBarTheme: AppAppBarTheme.darkAppAppBarTheme,
    checkboxTheme: AppCheckboxTheme.darkCheckboxTheme,
    bottomSheetTheme: AppBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.darkElevatedButtonTheme,
    filledButtonTheme: AppFilledButtonTheme.darkFilledButtonTheme,
    outlinedButtonTheme: AppOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: AppTextFormFieldTheme.darkInputDecorationTheme,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.gold,
      selectionColor: Color(0x33B9A779),
      selectionHandleColor: AppColors.gold,
    ),
  );
}
