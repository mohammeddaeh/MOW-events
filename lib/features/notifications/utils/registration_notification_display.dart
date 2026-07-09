import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_registration_data.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';

/// نصوص عرض إشعارات قبول/رفض التسجيل (بدل مفاتيح FCM أو JSON خام).
class RegistrationNotificationContent {
  const RegistrationNotificationContent({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class RegistrationNotificationDisplay {
  RegistrationNotificationDisplay._();

  static RegistrationNotificationContent resolve({
    required NotificationType type,
    Map<String, dynamic>? data,
    String? title,
    String? body,
  }) {
    final payload = data ?? const <String, dynamic>{};

    switch (type) {
      case NotificationType.acceptUserRegistration:
        return RegistrationNotificationContent(
          title: AppTexts.registrationApprovedTitle,
          body: _firstReadable([
            _clean(body),
            _clean(title),
            AppTexts.registrationApprovedMessage,
          ]),
        );
      case NotificationType.rejectUserRegistration:
        return RegistrationNotificationContent(
          title: AppTexts.registrationRejectedTitle,
          body: rejectionReason(
            data: payload,
            title: title,
            body: body,
          ),
        );
      default:
        return RegistrationNotificationContent(
          title: _clean(title) ?? AppTexts.notifications,
          body: _clean(body) ?? '',
        );
    }
  }

  /// سبب الرفض للعرض في الإشعار أو الشاشة.
  static String rejectionReason({
    Map<String, dynamic>? data,
    String? title,
    String? body,
  }) {
    return UserRegistrationData.extractRejectionReason(
          data: data,
          notificationTitle: title,
          notificationBody: body,
        ) ??
        AppTexts.registrationRejectedDefaultReason;
  }

  static bool isTechnicalText(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return true;
    return UserRegistrationData.isTechnicalToken(text);
  }

  static String? _clean(String? raw) {
    return UserRegistrationData.normalizeReasonText(raw);
  }

  static String _firstReadable(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return AppTexts.registrationApprovedMessage;
  }
}
