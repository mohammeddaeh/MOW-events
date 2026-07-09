import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class InternetGuard {
  static DateTime? _lastListRefreshOfflineMessageAt;
  static const Duration _listRefreshOfflineMessageCooldown =
      Duration(seconds: 4);

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

  /// قبل سحب التحديث في قوائم اليومي/الأسبوعي.
  /// لا تُعرض الرسالة مع كل سحب؛ تُعاد بعد [_listRefreshOfflineMessageCooldown].
  static bool ensureOnlineForListRefresh({bool showMessage = true}) {
    final online = NetworkManager.instance.isOnline.value;

    if (online) {
      _lastListRefreshOfflineMessageAt = null;
      return true;
    }

    if (showMessage) {
      final now = DateTime.now();
      final lastShown = _lastListRefreshOfflineMessageAt;
      final canShowAgain = lastShown == null ||
          now.difference(lastShown) >= _listRefreshOfflineMessageCooldown;

      if (canShowAgain) {
        _lastListRefreshOfflineMessageAt = now;
        AppSnackBars.warningSnackBar(
          title: AppTexts.noInternetConnection,
          message: AppTexts.refreshRequiresInternetConnection,
        );
      }
    }
    return false;
  }
}
