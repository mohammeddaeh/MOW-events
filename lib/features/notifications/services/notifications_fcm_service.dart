import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/auth/services/registration_approval_service.dart';
import 'package:mow_events/features/notifications/data/data_sources/notifications_backend.dart';
import 'package:mow_events/features/notifications/data/repsitories_impl/notifications_repository_impl.dart';
import 'package:mow_events/features/notifications/fcm/fcm_pending_action_store.dart';
import 'package:mow_events/features/notifications/handlers/registration_approval_notification_handler.dart';
import 'package:mow_events/features/notifications/presentation/controller/notifications_controller.dart';

enum RegistrationRecheckOutcome { handled, stillPending, failed }

/// واجهة موحّدة لـ FCM: تسجيل التوكن، معالجة الإشعارات المؤجلة، والتكامل مع الباكند.
class NotificationsFcmService {
  static const _retryDelays = [
    Duration(milliseconds: 800),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  static void ensureController() {
    if (Get.isRegistered<NotificationsController>()) return;

    Get.put<NotificationsController>(
      NotificationsController(
        repository: NotificationsRepositoryImpl(
          backend: NotificationsBackend(),
        ),
      ),
      permanent: true,
    );
  }

  static NotificationsController get _controller {
    ensureController();
    return Get.find<NotificationsController>();
  }

  /// بعد التسجيل أو الدخول بحساب pending: حفظ الحالة + تسجيل توكن الجهاز.
  static Future<bool> preparePendingRegistration(UserModel user) async {
    await RegistrationApprovalService.syncFromUser(user);
    return syncPushTokenWithRetries(
      showError: false,
      debugContext: 'preparePendingRegistration',
    );
  }

  /// طباعة توكن الجهاز في وضع التطوير فقط (للتشخيص).
  static Future<void> logDeviceToken(String context) async {
    if (!kDebugMode) return;
    try {
      await _controller.ensurePushSetup();
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[FCM][$context] ${token ?? "(null)"}');
    } catch (e) {
      debugPrint('[FCM][$context] error: $e');
    }
  }

  static Future<bool> syncPushTokenWithRetries({
    bool showError = false,
    String? debugContext,
  }) async {
    if (!AuthService.authenticated || !_canRegisterPushToken) return false;

    final syncedOnce = await _controller.syncFcmTokenWithUser(
      showError: false,
      debugContext: debugContext ?? 'syncPushTokenWithRetries',
    );
    if (syncedOnce) return true;

    for (var attempt = 1; attempt <= _retryDelays.length; attempt++) {
      await Future<void>.delayed(_retryDelays[attempt - 1]);

      final isLastAttempt = attempt == _retryDelays.length;
      final synced = await _controller.syncFcmTokenWithUser(
        showError: showError && isLastAttempt,
        debugContext: debugContext != null
            ? '$debugContext#retry$attempt'
            : 'syncPushTokenWithRetries#retry$attempt',
      );

      if (synced) return true;
    }

    return false;
  }

  /// معالجة إشعار وصل في الخلفية قبل تهيئة GetX بالكامل.
  static Future<void> processPendingBackgroundAction() async {
    final pending = FcmPendingActionStore.read();
    if (pending == null) return;

    ensureController();
    await _controller.ensurePushSetup();

    await FcmPendingActionStore.clear();

    final data = pending['data'];
    final payload = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};

    if (!RegistrationApprovalNotificationHandler.canHandle(payload)) return;

    await RegistrationApprovalNotificationHandler.handlePayload(
      data: payload,
      title: pending['title']?.toString(),
      body: pending['body']?.toString(),
      foreground: false,
    );
  }

  /// إعادة فحص حالة طلب التسجيل (FCM مؤجل + إشعارات الخادم) — وليس الملف الشخصي.
  static Future<RegistrationRecheckOutcome>
  recheckRegistrationRequestStatus() async {
    ensureController();
    await _controller.ensurePushSetup();
    await processPendingBackgroundAction();

    if (Get.currentRoute != AppRouter.registrationPendingScreen) {
      return RegistrationRecheckOutcome.handled;
    }

    try {
      final notification = await _controller.fetchLatestRegistrationDecision();
      if (notification == null) {
        return RegistrationRecheckOutcome.stillPending;
      }

      await RegistrationApprovalNotificationHandler.handlePayload(
        data: notification.data,
        title: notification.title,
        body: notification.body,
        foreground: true,
      );
      return RegistrationRecheckOutcome.handled;
    } catch (_) {
      return RegistrationRecheckOutcome.failed;
    }
  }

  static bool get _canRegisterPushToken {
    if (!AuthService.authenticated) return false;
    if (RegistrationApprovalService.isAwaitingApproval) return true;
    return RegistrationApprovalService.shouldHoldRegistrationApproval(
      AuthService.currentUser,
    );
  }
}
