import 'package:get/get.dart';

class AppHelper {
  static void hideKeyboard() {
    Get.focusScope?.unfocus();
  }

  static bool get isDarkMode => Get.isDarkMode;

  static String get currentTheme => Get.theme.toString();

  static String get currentLang => Get.locale?.languageCode ?? 'ar';
  static String get deviceLang => Get.deviceLocale?.languageCode ?? 'ar';

  static double get screenHeight => Get.height;
  static double get screenWidth => Get.width;
}
