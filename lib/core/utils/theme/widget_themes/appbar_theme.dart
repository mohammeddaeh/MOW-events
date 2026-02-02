import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';

class AppAppBarTheme {
  AppAppBarTheme._();

  static final lightAppAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: AppColors.black, size: 24),
    actionsIconTheme: IconThemeData(color: AppColors.black, size: 24),
    titleTextStyle: const TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: AppColors.black,
      fontFamily: 'Arabic',
    ),
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  static final darkAppAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: AppColors.white, size: 24),
    actionsIconTheme: IconThemeData(color: AppColors.white, size: 24),
    titleTextStyle: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
      fontFamily: 'Arabic',
    ),
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
}
