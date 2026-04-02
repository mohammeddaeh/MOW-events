import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';

class AppSnackBars {
  static const EdgeInsets _standardMargin = EdgeInsets.all(16);
  static const SnackPosition _position = SnackPosition.BOTTOM;

  static void hideSnackBar() {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
    }
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }

  /// Display a success snackbar with green background
  static void successSnackBar({
    required String title,
    String message = '',
    int duration = 3,
  }) {
    if (Get.context == null) return;

    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: false,
      colorText: AppColors.white,
      backgroundColor: AppColors.success,
      snackPosition: _position,
      duration: Duration(seconds: duration),
      margin: _standardMargin,
      borderRadius: 8,
      dismissDirection: DismissDirection.horizontal,
      icon: const Icon(Iconsax.check, color: AppColors.white),
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Display a warning snackbar with orange background
  static void warningSnackBar({
    required String title,
    String message = '',
    int duration = 3,
    bool force = false,
  }) {
    if (Get.context == null) return;
    if (AuthService.isSessionExpiredHandling && !force) return;

    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: false,
      colorText: AppColors.white,
      backgroundColor: AppColors.warning,
      snackPosition: _position,
      duration: Duration(seconds: duration),
      margin: _standardMargin,
      borderRadius: 8,
      dismissDirection: DismissDirection.horizontal,
      icon: const Icon(Iconsax.warning_2, color: AppColors.white),
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Display an error snackbar with red background
  static void errorSnackBar({
    required String title,
    String message = '',
    int duration = 4,
    bool force = false,
  }) {
    if (Get.context == null) return;
    if (AuthService.isSessionExpiredHandling && !force) return;

    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: false,
      colorText: AppColors.white,
      backgroundColor: AppColors.errorSecondary,
      snackPosition: _position,
      duration: Duration(seconds: duration),
      margin: _standardMargin,
      borderRadius: 8,
      dismissDirection: DismissDirection.horizontal,
      icon: const Icon(Iconsax.close_circle, color: AppColors.white),
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Display an info snackbar with blue background
  static void infoSnackBar({
    required String title,
    String message = '',
    int duration = 3,
    bool force = false,
  }) {
    if (Get.context == null) return;
    if (AuthService.isSessionExpiredHandling && !force) return;

    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: false,
      colorText: AppColors.white,
      backgroundColor: AppColors.info,
      snackPosition: _position,
      duration: Duration(seconds: duration),
      margin: _standardMargin,
      borderRadius: 8,
      dismissDirection: DismissDirection.horizontal,
      icon: const Icon(Iconsax.info_circle, color: AppColors.white),
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}
