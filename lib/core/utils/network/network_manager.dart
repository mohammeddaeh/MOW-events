import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final RxBool isOnline = true.obs;

  bool _wasOffline = false;

  @override
  void onInit() {
    super.onInit();
    _checkInitialConnection();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _checkInitialConnection() async {
    final connected = await isConnected();
    isOnline.value = connected;
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final hasInternet = await _hasInternetAccess();
    isOnline.value = hasInternet;

    if (!hasInternet && !_wasOffline) {
      _wasOffline = true;
      showSnackBar(
        AppTexts.noInternet,
        AppTexts.checkTheInternetConnection,
        isError: true,
      );
    } else if (hasInternet && _wasOffline) {
      _wasOffline = false;
      showSnackBar(
        AppTexts.contactMade,
        AppTexts.internetConnectionHasBeenRestored,
        isSuccess: true,
      );
    }
  }

  void showSnackBar(
    String title,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!Get.isSnackbarOpen) {
      if (isError) AppSnackBars.errorSnackBar(title: title, message: message);
      if (isSuccess) {
        AppSnackBars.successSnackBar(title: title, message: message);
      }
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) return false;
      return await _hasInternetAccess();
    } catch (_) {
      return false;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
