import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_registration_data.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/registration_pending_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/user_access_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/auth/services/registration_approval_service.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';
import 'package:mow_events/features/notifications/presentation/controller/notifications_controller.dart';
import 'package:mow_events/features/notifications/services/notifications_fcm_service.dart';
import 'package:mow_events/features/notifications/utils/registration_notification_display.dart';

/// معالجة إشعارات قبول/رفض التسجيل عبر FCM (`data_registration_user`).
class RegistrationApprovalNotificationHandler {
  static bool canHandle(Map<String, dynamic> data) {
    final fromRegistrationPayload =
        registrationNotificationTypeFromFcmData(data) != null;
    if (fromRegistrationPayload) return true;

    return NotificationTypeExtension.fromPayload(data: data)
        .isRegistrationApproval;
  }

  static Future<void> handlePayload({
    required Map<String, dynamic> data,
    String? title,
    String? body,
    bool clicked = false,
    bool foreground = false,
  }) async {
    NotificationsFcmService.ensureController();

    final message = RemoteMessage(
      data: data,
      notification: (title != null || body != null)
          ? RemoteNotification(title: title, body: body)
          : null,
    );
    await handle(message, clicked: clicked, foreground: foreground);
  }

  static Future<void> handle(
    RemoteMessage message, {
    bool clicked = false,
    bool foreground = false,
  }) async {
    NotificationsFcmService.ensureController();

    final data = Map<String, dynamic>.from(message.data);
    final type =
        registrationNotificationTypeFromFcmData(data) ??
        NotificationTypeExtension.fromPayload(
          data: data,
          title: message.notification?.title,
          body: message.notification?.body,
        );

    if (!type.isRegistrationApproval) return;

    switch (type) {
      case NotificationType.acceptUserRegistration:
        await _handleAccepted(message: message, foreground: foreground);
      case NotificationType.rejectUserRegistration:
        await _handleRejected(
          message: message,
          reason: _extractReason(message),
          foreground: foreground,
        );
      default:
        break;
    }
  }

  static String _extractReason(RemoteMessage message) {
    final fromPayload = UserRegistrationData.extractFromDataRegistrationUser(
      Map<String, dynamic>.from(message.data),
    );
    if (fromPayload != null && fromPayload.isNotEmpty) {
      return fromPayload;
    }

    return RegistrationNotificationDisplay.rejectionReason(
      data: message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  static Future<void> _handleAccepted({
    required RemoteMessage message,
    required bool foreground,
  }) async {
    if (Get.isRegistered<RegistrationPendingController>()) {
      await Get.find<RegistrationPendingController>()
          .completeRegistrationApproval(showLoader: true);
      return;
    }

    final auth = Get.find<AuthController>();
    final authRepo = Get.find<AuthRepository>();

    try {
      final user = await authRepo.getProfile();
      auth.user.value = user;
      auth.isAuthenticated.value = true;
      await AuthService.saveUser(user.toJson());
    } catch (_) {}

    await RegistrationApprovalService.clear();
    await Get.find<UserAccessController>().preparePostLoginAccess();

    AppSnackBars.navigateAfterClosingSnackbars(() {
      Get.offAllNamed(AppRouter.homeScreen);
      if (foreground) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackBars.successSnackBar(
            title: AppTexts.success,
            message: AppTexts.registrationApprovedMessage,
          );
        });
      }
    });
  }

  static Future<void> _handleRejected({
    required RemoteMessage message,
    required String reason,
    required bool foreground,
  }) async {
    final auth = Get.find<AuthController>();
    final resolvedReason = _resolveRejectionReason(message, reason);

    await _persistRejectionLocally(
      auth: auth,
      fcmData: message.data,
      reason: resolvedReason,
    );

    if (Get.isRegistered<RegistrationPendingController>()) {
      await Get.find<RegistrationPendingController>().applyRejection(
        resolvedReason,
      );
    } else if (Get.currentRoute != AppRouter.registrationPendingScreen) {
      AppSnackBars.navigateAfterClosingSnackbars(() {
        Get.offAllNamed(AppRouter.registrationPendingScreen);
      });
      if (Get.isRegistered<RegistrationPendingController>()) {
        await Get.find<RegistrationPendingController>().applyRejection(
          resolvedReason,
        );
      }
    }

    if (foreground) {
      await _showForegroundAlertIfNeeded(
        message: message,
        type: NotificationType.rejectUserRegistration,
        foreground: foreground,
      );
    }
  }

  static String _resolveRejectionReason(
    RemoteMessage message,
    String fallback,
  ) {
    final extracted = _extractReason(message).trim();
    if (extracted.isEmpty ||
        extracted == AppTexts.registrationRejectedDefaultReason) {
      return fallback.trim().isEmpty
          ? AppTexts.registrationRejectedDefaultReason
          : fallback;
    }
    return extracted;
  }

  static Future<void> _persistRejectionLocally({
    required AuthController auth,
    required Map<String, dynamic> fcmData,
    required String reason,
  }) async {
    await RegistrationApprovalService.markRejected(reason);

    final current = auth.user.value ?? AuthService.currentUser;
    if (current == null) return;

    final fcmReg = UserRegistrationData.fromFcmData(fcmData);
    final description = reason == AppTexts.registrationRejectedDefaultReason
        ? fcmReg?.registerDescriptionStatus
        : reason;

    final updated = current.copyWith(
      registrationData: UserRegistrationData(
        registerStatus: fcmReg?.registerStatus ?? 'rejected',
        registerDescriptionStatus: description,
      ),
    );

    auth.user.value = updated;
    await AuthService.saveUser(updated.toJson());
  }

  static Future<void> _showForegroundAlertIfNeeded({
    required RemoteMessage message,
    required NotificationType type,
    required bool foreground,
  }) async {
    if (!foreground || !Get.isRegistered<NotificationsController>()) return;

    final content = RegistrationNotificationDisplay.resolve(
      type: type,
      data: message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );
    await Get.find<NotificationsController>().showRegistrationPushAlert(
      title: content.title,
      body: content.body,
      type: type,
      data: Map<String, dynamic>.from(message.data),
    );
  }
}
