import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mow_events/core/app_update/data/app_settings_backend.dart';
import 'package:mow_events/core/app_update/utils/version_comparator.dart';

enum AppUpdateState { none, optional, required }

class AppVersionController extends GetxController {
  static AppVersionController get instance => Get.find();

  final AppSettingsBackend _backend;

  AppVersionController({AppSettingsBackend? backend})
    : _backend = backend ?? AppSettingsBackend();

  final Rx<AppUpdateState> updateState = AppUpdateState.none.obs;
  final RxString appUrl = ''.obs;
  final RxString latestVersion = ''.obs;
  final RxString currentVersion = ''.obs;
  final RxBool optionalUpdateDismissed = false.obs;
  final RxBool hasReachedHome = false.obs;

  /// يصبح true بمجرد أن يفتح المستخدم صفحة الإعدادات مرة واحدة —
  /// يُخفي البادج الحمراء عن أيقونة الإعدادات في الـ nav بشكل نهائي.
  final RxBool settingsBadgeSeen = false.obs;

  bool get hasOptionalUpdate => updateState.value == AppUpdateState.optional;

  @override
  void onInit() {
    super.onInit();
    checkForUpdate();
  }

  void markHomeReached() {
    if (!hasReachedHome.value) {
      hasReachedHome.value = true;
    }
  }

  Future<void> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion.value = packageInfo.version;

      final settings = await _backend.showSettings();

      if (!VersionComparator.isNewer(settings.version, packageInfo.version)) {
        updateState.value = AppUpdateState.none;
        return;
      }

      appUrl.value = settings.appUrl;
      latestVersion.value = settings.version;
      updateState.value = settings.isVersionRequired
          ? AppUpdateState.required
          : AppUpdateState.optional;
    } catch (_) {
      // Silently ignore: update check must never block app usage.
    }
  }

  void dismissOptionalUpdate() {
    optionalUpdateDismissed.value = true;
  }

  void markSettingsBadgeSeen() {
    if (!settingsBadgeSeen.value) {
      settingsBadgeSeen.value = true;
    }
  }
}
