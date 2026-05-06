import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

const MethodChannel _kAlarmChannel = MethodChannel('alarm_channel');

class AlarmRuntimeStatus {
  const AlarmRuntimeStatus({
    required this.canScheduleExactAlarms,
    required this.canUseFullScreenIntent,
    required this.areNotificationsEnabled,
    required this.sdkInt,
  });

  final bool canScheduleExactAlarms;
  final bool canUseFullScreenIntent;
  final bool areNotificationsEnabled;
  final int sdkInt;

  bool get allGranted =>
      canScheduleExactAlarms &&
      canUseFullScreenIntent &&
      areNotificationsEnabled;
}

Future<AlarmRuntimeStatus?> queryAlarmRuntimeStatus() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  try {
    final raw = await _kAlarmChannel.invokeMethod<dynamic>(
      'getAlarmRuntimeStatus',
    );
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return AlarmRuntimeStatus(
      canScheduleExactAlarms: m['canScheduleExactAlarms'] as bool? ?? true,
      canUseFullScreenIntent: m['canUseFullScreenIntent'] as bool? ?? true,
      areNotificationsEnabled: m['areNotificationsEnabled'] as bool? ?? true,
      sdkInt: m['sdkInt'] as int? ?? 0,
    );
  } catch (e, st) {
    debugPrint('queryAlarmRuntimeStatus: $e\n$st');
    return null;
  }
}

Future<void> openAndroidExactAlarmSettings() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _kAlarmChannel.invokeMethod<void>('openExactAlarmSettings');
  } catch (e, st) {
    debugPrint('openAndroidExactAlarmSettings: $e\n$st');
  }
}

Future<void> openAndroidFullScreenIntentSettings() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _kAlarmChannel.invokeMethod<void>('openFullScreenIntentSettings');
  } catch (e, st) {
    debugPrint('openAndroidFullScreenIntentSettings: $e\n$st');
  }
}

Future<void> openAndroidNotificationSettings() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _kAlarmChannel.invokeMethod<void>('openNotificationSettings');
  } catch (e, st) {
    debugPrint('openAndroidNotificationSettings: $e\n$st');
  }
}

/// يفتح إعدادات الصوت في النظام (نغمة المنبّه الافتراضية وغيرها).
Future<void> openAndroidSystemSoundSettings() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _kAlarmChannel.invokeMethod<void>('openSystemSoundSettings');
  } catch (e, st) {
    debugPrint('openAndroidSystemSoundSettings: $e\n$st');
  }
}

/// تحسينات موثوقية المنبّه على أندرويد (بدون الاعتماد على تشغيل Flutter).
///
/// يطلب استثناء البطارية ثم يوجّه المستخدم (مرة واحدة لكل نوع) لإعدادات مطلوبة.
Future<void> requestAndroidAlarmReliabilityEnhancements() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  try {
    await Permission.ignoreBatteryOptimizations.request();
  } catch (_) {}

  try {
    final status = await queryAlarmRuntimeStatus();
    if (status == null) return;

    if (kDebugMode) {
      if (!status.areNotificationsEnabled) {
        debugPrint(
          'Alarm: notifications disabled — enable in system settings.',
        );
      }
      if (!status.canScheduleExactAlarms) {
        debugPrint('Alarm: canScheduleExactAlarms=false — allow exact alarms.');
      }
      if (status.sdkInt >= 34 && !status.canUseFullScreenIntent) {
        debugPrint(
          'Alarm: canUseFullScreenIntent=false — allow full-screen intents (Android 14+).',
        );
      }
    }

    final box = GetStorage();

    if (!status.areNotificationsEnabled &&
        box.read<bool>('alarm_prompted_notifications_v1') != true) {
      await openAndroidNotificationSettings();
      await box.write('alarm_prompted_notifications_v1', true);
      return;
    }
    if (!status.canScheduleExactAlarms &&
        box.read<bool>('alarm_prompted_exact_v1') != true) {
      await openAndroidExactAlarmSettings();
      await box.write('alarm_prompted_exact_v1', true);
      return;
    }
    if (status.sdkInt >= 34 &&
        !status.canUseFullScreenIntent &&
        box.read<bool>('alarm_prompted_fsi_v1') != true) {
      await openAndroidFullScreenIntentSettings();
      await box.write('alarm_prompted_fsi_v1', true);
      return;
    }
  } catch (e, st) {
    debugPrint('requestAndroidAlarmReliabilityEnhancements: $e\n$st');
  }
}
