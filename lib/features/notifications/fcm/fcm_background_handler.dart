import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';
import 'package:mow_events/features/notifications/fcm/fcm_pending_action_store.dart';

/// يُستدعى عند وصول رسالة FCM والتطبيق في الخلفية أو مغلق.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await GetStorage.init();

  final registrationType = registrationNotificationTypeFromFcmData(
    message.data,
  );
  final legacyType = NotificationTypeExtension.fromPayload(
    data: message.data,
    title: message.notification?.title,
    body: message.notification?.body,
  );
  final type = registrationType ?? legacyType;

  if (!type.isRegistrationApproval) return;

  await FcmPendingActionStore.save(
    type: type,
    data: Map<String, dynamic>.from(message.data),
    title: message.notification?.title,
    body: message.notification?.body,
  );
}
