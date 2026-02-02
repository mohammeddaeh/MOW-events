import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';

class AppSnackBars {
  static void hideSnackBar() {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
    }
  }

  static void successSnackBar({
    required String title,
    String message = '',
    int duration = 3,
  }) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: AppColors.white,
      backgroundColor: AppColors.success,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      dismissDirection: DismissDirection.horizontal,
      icon: const Icon(Iconsax.check, color: AppColors.white),
    );
  }

  static void warningSnackBar({
    required String title,
    String message = '',
    int duration = 3,
  }) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: AppColors.white,
      backgroundColor: AppColors.warning,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(20),
      dismissDirection: DismissDirection.horizontal,
      icon: const Icon(Iconsax.warning_2, color: AppColors.white),
    );
  }

  static void errorSnackBar({
    required String title,
    String message = '',
    int duration = 3,
  }) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: AppColors.white,
      backgroundColor: AppColors.errorSecondary,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(20),
      dismissDirection: DismissDirection.horizontal,
      icon: const Icon(Iconsax.close_circle, color: AppColors.white),
    );
  }

  static void infoSnackBar({
    required String title,
    String message = '',
    int duration = 3,
  }) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: AppColors.white,
      backgroundColor: AppColors.info,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(20),
      dismissDirection: DismissDirection.horizontal,
      icon: const Icon(Iconsax.info_circle, color: AppColors.white),
    );
  }
}

// class AppSnackBar {
//   static void show(
//     AppSnack type, {
//     String? title,
//     String? message,
//     Duration? duration,
//     bool dismissible = true,
//   }) {
//     Get.closeCurrentSnackbar();

//     Get.snackbar(
//       title ?? _defaultTitle(type),
//       message ?? type.defaultMessage,
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: type.color.withOpacity(0.95),
//       colorText: Colors.white,
//       icon: Icon(type.icon, color: Colors.white),
//       duration: duration ?? type.duration,
//       isDismissible: dismissible,
//       margin: const EdgeInsets.all(16),
//       borderRadius: 12,
//       snackStyle: SnackStyle.FLOATING,
//       animationDuration: const Duration(milliseconds: 300),
//     );
//   }

//   static String _defaultTitle(AppSnack type) {
//     switch (type) {
//       case AppSnack.success:
//         return 'نجاح';
//       case AppSnack.error:
//         return 'خطأ';
//       case AppSnack.warning:
//         return 'تنبيه';
//       case AppSnack.loading:
//         return 'انتظر';
//     }
//   }
// }

// extension AppSnackX on AppSnack {
//   void show({
//     String? title,
//     String? message,
//     Duration? duration,
//     bool dismissible = true,
//   }) {
//     AppSnackBar.show(
//       this,
//       title: title,
//       message: message,
//       duration: duration,
//       dismissible: dismissible,
//     );
//   }
// }
