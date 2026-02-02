import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppLoader {
  static void show() {
    if (!(Get.isDialogOpen ?? false)) {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
    }
  }

  static void hide() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
