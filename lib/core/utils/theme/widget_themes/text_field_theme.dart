import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';

class AppTextFormFieldTheme {
  AppTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: AppColors.darkGrey,
    suffixIconColor: AppColors.darkGrey,
    labelStyle: TextStyle(fontSize: 16, color: AppColors.black),
    hintStyle: TextStyle(fontSize: 12, color: AppColors.black),
    floatingLabelStyle: TextStyle(color: AppColors.black.withOpacity(0.8)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: AppColors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: AppColors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: AppColors.dark),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: AppColors.errorSecondary),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 2, color: AppColors.errorSecondary),
    ),
    errorStyle: TextStyle(color: AppColors.errorSecondary),
    floatingLabelBehavior: FloatingLabelBehavior.never,
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: AppColors.darkGrey,
    suffixIconColor: AppColors.darkGrey,
    labelStyle: TextStyle(fontSize: 16, color: AppColors.white),
    hintStyle: TextStyle(fontSize: 12, color: AppColors.white),
    floatingLabelStyle: TextStyle(color: AppColors.white.withOpacity(0.8)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: AppColors.darkGrey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: AppColors.darkGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: AppColors.white),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: AppColors.errorSecondary),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 2, color: AppColors.errorSecondary),
    ),
    errorStyle: TextStyle(color: AppColors.errorSecondary),
    floatingLabelBehavior: FloatingLabelBehavior.never,
  );
}
