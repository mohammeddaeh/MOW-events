import 'package:get/get.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:mow_events/core/utils/local_storage/storage_keys.dart';

class AppStorage {
  final AppLocalStorage _storage = Get.find(); // تأكد من التسجيل قبل الاستخدام

  String get theme => _storage.read(StorageKeys.theme) ?? 'system';

  Future<void> setTheme(String value) =>
      _storage.write(StorageKeys.theme, value);

  String get lang => _storage.read(StorageKeys.lang) ?? 'en';

  Future<void> setLang(String value) => _storage.write(StorageKeys.lang, value);
  String get calendar => _storage.read(StorageKeys.calendar) ?? 'gregorian';

  Future<void> setCalendar(String value) =>
      _storage.write(StorageKeys.calendar, value);
  bool get rememberMe => _storage.read(StorageKeys.rememberMe) ?? false;

  Future<void> setRememberMe(bool value) =>
      _storage.write(StorageKeys.rememberMe, value);
}
