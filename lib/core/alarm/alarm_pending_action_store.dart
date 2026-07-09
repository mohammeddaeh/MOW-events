import 'package:get_storage/get_storage.dart';

/// يحفظ حمولة إشعار منبّه iOS تم الضغط عليه لمعالجتها عند عودة/إطلاق التطبيق.
class AlarmPendingActionStore {
  static const _key = 'event_alarm_pending_action';

  static Future<void> save(Map<String, dynamic> payload) async {
    await GetStorage().write(_key, payload);
  }

  static Map<String, dynamic>? read() {
    final raw = GetStorage().read(_key);
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  static Future<void> clear() async {
    await GetStorage().remove(_key);
  }
}
