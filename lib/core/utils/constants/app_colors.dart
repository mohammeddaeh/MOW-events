import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/helpers/helper_functions.dart';

class AppColors {
  AppColors._();
  static const Color light = Color(0xFFeeeeee);
  static const Color dark = Color(0xFF272727);
  static const Color primary = Color(0xFF002723);
  static const Color secondary = Color(0xFF094239);
  static const Color accent = Color(0xFF427f77);
  static const Color gold = Color(0xFFB9A779);
  static const Color borderPrimary = Color(0xFFD9D9D9);
  static const Color red = Color(0xFFFF3B30);

  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color errorPrimary = Color(0xFFA53724);
  static const Color errorSecondary = Color.fromARGB(255, 211, 77, 54);
  static const Color info = Color(0xFF1976D2);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF232323);
  static const Color grey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF939393);
  static const Color textGray = Color(0xFF6C7278);
  static const Color backgroundGray = Color(0XFFF8F8F8);

  static const Color orange = Color(0xFFEF5A56);
  static const Color green = Color(0xFF00B383);
  static const Color purple = Color(0xFF735BF2);
  static const Color blue = Color(0xFF0095FF);
  static const Color buttonDisabled = Color(0xFFC4C4C4);
  static Color get darkLightGray => AppHelper.isDarkMode ? textGray : textGray;
}
