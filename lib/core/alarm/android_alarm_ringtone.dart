import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _kAlarmChannel = MethodChannel('alarm_channel');

enum AlarmRingtoneSource { defaultTone, device, storage, unknown }

/// طلب منبّه اختبار لسماع النغمة المحفوظة — لا يتعارض مع [ReminderController.testAlarmRequestCode].
const int androidAlarmRingtonePreviewRequestCode = 0x7FFFFFFD;

/// ثوانٍ قبل إطلاق منبّه التجربة (نفس فكرة اختبار التذكيرات).
const int androidAlarmRingtonePreviewDelaySeconds = 5;

/// يجدول منبّه ملء الشاشة بعد [seconds] لسماع نغمة المنبّه الحالية.
Future<bool> scheduleAndroidAlarmRingtonePreview({
  int seconds = androidAlarmRingtonePreviewDelaySeconds,
  required String alarmTitle,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    final when = DateTime.now().add(Duration(seconds: seconds));
    final t = when.millisecondsSinceEpoch;
    await _kAlarmChannel.invokeMethod<void>('scheduleAlarm', {
      'time': t,
      'eventId': 'ringtone_preview',
      'requestCode': androidAlarmRingtonePreviewRequestCode,
      'isLast': true,
      'eventStartTime': t,
      'title': alarmTitle,
      'location': '',
      'startTime': '',
      'snoozeMinutes': 10,
    });
    return true;
  } catch (_) {
    return false;
  }
}

/// `null` = استخدام نغمة المنبّه الافتراضية في النظام.
Future<String?> getAndroidAlarmRingtoneUri() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  try {
    final v = await _kAlarmChannel.invokeMethod<String?>('getAlarmRingtoneUri');
    return v;
  } catch (_) {
    return null;
  }
}

Future<AlarmRingtoneSource> getAndroidAlarmRingtoneSource() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return AlarmRingtoneSource.defaultTone;
  }
  try {
    final v = await _kAlarmChannel.invokeMethod<String?>(
      'getAlarmRingtoneSource',
    );
    switch (v) {
      case 'default':
        return AlarmRingtoneSource.defaultTone;
      case 'device':
        return AlarmRingtoneSource.device;
      case 'storage':
        return AlarmRingtoneSource.storage;
      default:
        return AlarmRingtoneSource.unknown;
    }
  } on MissingPluginException {
    // توافق مع نسخ APK قديمة لا تحتوي method getAlarmRingtoneSource.
    final uri = await getAndroidAlarmRingtoneUri();
    return _inferRingtoneSourceFromUri(uri);
  } catch (_) {
    final uri = await getAndroidAlarmRingtoneUri();
    return _inferRingtoneSourceFromUri(uri);
  }
}

Future<void> clearAndroidAlarmRingtone() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _kAlarmChannel.invokeMethod<void>('clearAlarmRingtone');
  } catch (_) {}
}

/// يفتح منتقي نغمات المنبّه في النظام؛ يعيد [Uri] كنص أو `null` عند الإلغاء.
Future<String?> pickAndroidSystemAlarmRingtone() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  try {
    final v =
        await _kAlarmChannel.invokeMethod<String?>('pickSystemAlarmRingtone');
    return v;
  } catch (_) {
    return null;
  }
}

/// يفتح منتقي ملفات صوتية من التخزين؛ يعيد [Uri] كنص أو `null`.
Future<String?> pickAndroidAlarmAudioFile() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  try {
    final v = await _kAlarmChannel.invokeMethod<String?>('pickAlarmAudioFile');
    return v;
  } catch (_) {
    return null;
  }
}

/// معاينة فورية للنغمة الحالية أو URI مُمرّر.
Future<bool> playAndroidAlarmTonePreview({String? uri}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    final ok = await _kAlarmChannel.invokeMethod<bool>(
      'playAlarmTonePreview',
      {'uri': uri},
    );
    return ok ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> stopAndroidAlarmTonePreview() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _kAlarmChannel.invokeMethod<void>('stopAlarmTonePreview');
  } catch (_) {}
}

AlarmRingtoneSource _inferRingtoneSourceFromUri(String? uri) {
  final v = uri?.trim().toLowerCase() ?? '';
  if (v.isEmpty) return AlarmRingtoneSource.defaultTone;
  if (v.startsWith('content://media') || v.startsWith('content://settings')) {
    return AlarmRingtoneSource.device;
  }
  if (v.startsWith('content://') || v.startsWith('file://') || v.contains('/')) {
    return AlarmRingtoneSource.storage;
  }
  return AlarmRingtoneSource.unknown;
}
