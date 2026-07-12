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
  final RxBool optionalUpdateDismissed = false.obs;
  final RxBool hasReachedHome = false.obs;

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
      final settings = await _backend.showSettings();
      final packageInfo = await PackageInfo.fromPlatform();

      if (!VersionComparator.isNewer(settings.version, packageInfo.version)) {
        updateState.value = AppUpdateState.none;
        return;
      }

      appUrl.value = settings.appUrl;
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
}
