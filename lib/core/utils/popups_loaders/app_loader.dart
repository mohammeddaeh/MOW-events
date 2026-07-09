import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

/// طبقة تحميل شفافة تمنع التفاعل أثناء العمليات الطويلة (مثل تسجيل الخروج).
class AppLoader {
  static bool _isVisible = false;

  static bool get isVisible => _isVisible;

  static void show({String? message}) {
    if (_isVisible) return;

    _isVisible = true;
    final label = message?.trim().isNotEmpty == true
        ? message!.trim()
        : AppTexts.processing;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
              decoration: BoxDecoration(
                color: Get.isDarkMode ? AppColors.dark : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Get.isDarkMode ? AppColors.white : AppColors.black,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      useSafeArea: false,
    );
  }

  static void hide() {
    if (!_isVisible) return;
    _isVisible = false;

    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
