import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';

class ThemeController extends GetxController {
  static ThemeController get instance => Get.find();
  final appStorage = AppStorage();

  var storedTheme = 'system'.obs;

  ThemeMode get currentThemeMode {
    switch (storedTheme.value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  void onInit() {
    super.onInit();
    storedTheme.value = appStorage.theme;
    _applyTheme();
  }

  void _applyTheme() {
    Get.changeThemeMode(currentThemeMode);
  }

  void changeTheme(String theme) async {
    storedTheme.value = theme;
    await appStorage.setTheme(theme);

    _applyTheme();
  }

  IconData getThemeIcon(String theme) {
    switch (theme) {
      case 'light':
        return Icons.wb_sunny;
      case 'dark':
        return Icons.nightlight_round;
      default:
        return Icons.brightness_auto;
    }
  }
}
