import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class InternetGuard {
  static bool canWrite() {
    return NetworkManager.instance.isOnline.value;
  }

  static bool ensureOnline({bool showMessage = true}) {
    final online = NetworkManager.instance.isOnline.value;
    if (!online && showMessage) {
      AppSnackBars.warningSnackBar(
        title: AppTexts.noInternetConnection,
        message: AppTexts.thisActionRequiresInternetConnection,
      );
    }
    return online;
  }
}
