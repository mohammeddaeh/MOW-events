import 'package:get_storage/get_storage.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';

/// حفظ إجراء FCM وصل والتطبيق في الخلفية لمعالجته عند العودة (قبول/رفض التسجيل).
class FcmPendingActionStore {
  static const _key = 'notifications_pending_fcm_action';

  static Future<void> save({
    required NotificationType type,
    required Map<String, dynamic> data,
    String? title,
    String? body,
  }) async {
    await GetStorage().write(_key, {
      'type': type.wireValue,
      'data': data,
      'title': title,
      'body': body,
      'saved_at': DateTime.now().toIso8601String(),
    });
  }

  static Map<String, dynamic>? read() {
    final raw = GetStorage().read(_key);
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  static Future<void> clear() async {
    await GetStorage().remove(_key);
  }

  static Future<void> saveFromPayload({
    required Map<String, dynamic> data,
    String? title,
    String? body,
  }) async {
    final type =
        registrationNotificationTypeFromFcmData(data) ??
        NotificationTypeExtension.fromPayload(
          data: data,
          title: title,
          body: body,
        );
    if (!type.isRegistrationApproval) return;

    await save(type: type, data: data, title: title, body: body);
  }
}
