import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/helpers/helper_functions.dart';
import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';

class AppLocaleController extends GetxController {
  static AppLocaleController get instance => Get.find();
  final appStorage = AppStorage();

  var currentLang = ''.obs;

  @override
  void onInit() {
    final saved = appStorage.lang;
    currentLang.value = saved;
    super.onInit();
  }

  Locale get initialLang => currentLang.value.isEmpty
      ? const Locale('en')
      : langCode(currentLang.value);

  void toggleLang() {
    final newLang = AppHelper.currentLang == 'ar' ? 'en' : 'ar';
    changeLang(newLang);
  }

  void changeLang(String lang) async {
    currentLang.value = lang;
    await appStorage.setLang(lang);
    Get.updateLocale(langCode(lang));
  }

  Locale langCode(String lang) {
    return Locale(lang);
  }
}
