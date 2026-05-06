import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/alarm/android_alarm_ringtone.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class AlarmRingtoneSettingsController extends GetxController {
  final uri = RxnString();
  final source = AlarmRingtoneSource.defaultTone.obs;
  final isLoading = true.obs;
  final isBusy = false.obs;
  final isPreviewPlaying = false.obs;

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get isDefault => (uri.value == null || uri.value!.isEmpty);
  bool get isDefaultSelected =>
      source.value == AlarmRingtoneSource.defaultTone && isDefault;
  bool get isDeviceSelected => source.value == AlarmRingtoneSource.device;
  bool get isStorageSelected => source.value == AlarmRingtoneSource.storage;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  @override
  void onClose() {
    stopAndroidAlarmTonePreview();
    super.onClose();
  }

  Future<void> reload() async {
    if (!isAndroid) {
      isLoading.value = false;
      return;
    }
    uri.value = await getAndroidAlarmRingtoneUri();
    source.value = await getAndroidAlarmRingtoneSource();
    isLoading.value = false;
  }

  Future<void> runBusy(Future<void> Function() fn) async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      await fn();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> togglePreview() async {
    if (isPreviewPlaying.value) {
      await stopAndroidAlarmTonePreview();
      isPreviewPlaying.value = false;
      return;
    }
    final ok = await playAndroidAlarmTonePreview(uri: uri.value);
    if (ok) {
      isPreviewPlaying.value = true;
    } else {
      AppSnackBars.warningSnackBar(
        title: AppTexts.warningTitle,
        message: AppTexts.somethingWentWrong,
      );
    }
  }

  Future<void> playPreviewFresh() async {
    await stopAndroidAlarmTonePreview();
    isPreviewPlaying.value = false;
    final ok = await playAndroidAlarmTonePreview(uri: uri.value);
    if (ok) isPreviewPlaying.value = true;
  }

  Future<void> chooseDefaultTone() async {
    await runBusy(() async {
      await clearAndroidAlarmRingtone();
      await reload();
    });
  }

  Future<void> chooseFromDeviceTones() async {
    await runBusy(() async {
      final picked = await pickAndroidSystemAlarmRingtone();
      await reload();
      if (picked != null && picked.isNotEmpty) {
        await playPreviewFresh();
      }
    });
  }

  Future<void> chooseFromStorageFile() async {
    await runBusy(() async {
      final picked = await pickAndroidAlarmAudioFile();
      await reload();
      if (picked != null && picked.isNotEmpty) {
        await playPreviewFresh();
      }
    });
  }

  String statusLabel() {
    if (isDefault) return AppTexts.alarmRingtoneStatusDefault;
    switch (source.value) {
      case AlarmRingtoneSource.device:
        return '${AppTexts.alarmRingtoneStatusCustom} • ${AppTexts.alarmRingtoneChooseFromPhone}';
      case AlarmRingtoneSource.storage:
        return '${AppTexts.alarmRingtoneStatusCustom} • ${AppTexts.alarmRingtoneChooseFromFile}';
      case AlarmRingtoneSource.defaultTone:
        return AppTexts.alarmRingtoneStatusDefault;
      case AlarmRingtoneSource.unknown:
        return AppTexts.alarmRingtoneStatusCustom;
    }
  }
}
