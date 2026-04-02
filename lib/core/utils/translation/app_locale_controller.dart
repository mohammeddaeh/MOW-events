import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/helpers/helper_functions.dart';
import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';

class AppLocaleController extends GetxController {
  static const String _fallbackLang = 'ar';
  static const Set<String> _supportedLanguages = {'ar', 'en'};

  static AppLocaleController get instance => Get.find();
  final appStorage = AppStorage();

  var currentLang = ''.obs;

  @override
  void onInit() {
    super.onInit();
    currentLang.value = _resolveInitialLanguage();
  }

  Locale get initialLang => langCode(currentLang.value);

  void toggleLang() {
    final newLang = AppHelper.currentLang == 'ar' ? 'en' : 'ar';
    changeLang(newLang);
  }

  void changeLang(String lang) async {
    final normalizedLang = _normalizeLanguage(lang);
    currentLang.value = normalizedLang;
    await appStorage.setLang(normalizedLang);
    Get.updateLocale(langCode(normalizedLang));
  }

  Locale langCode(String lang) {
    return Locale(_normalizeLanguage(lang));
  }

  String _resolveInitialLanguage() {
    final savedLang = _normalizeStoredLanguage(appStorage.lang);
    if (savedLang != null) return savedLang;

    return _fallbackLang;
  }

  String? _normalizeStoredLanguage(String? lang) {
    if (lang == null || lang.trim().isEmpty) return null;
    return _supportedLanguages.contains(_extractLanguageCode(lang))
        ? _extractLanguageCode(lang)
        : null;
  }

  String _normalizeLanguage(String lang) {
    final languageCode = _extractLanguageCode(lang);
    return _supportedLanguages.contains(languageCode)
        ? languageCode
        : _fallbackLang;
  }

  String _extractLanguageCode(String lang) {
    final normalized = lang.trim().toLowerCase();
    if (normalized.isEmpty) return _fallbackLang;
    return normalized.split(RegExp(r'[-_]')).first;
  }
}
