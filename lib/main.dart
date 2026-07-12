import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mow_events/features/notifications/fcm/fcm_background_handler.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mow_events/app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mow_events/core/alarm/alarm_pending_action_store.dart';
import 'package:mow_events/core/general/bindings.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/alarm/android_alarm_permissions.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mow_events/firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  tz_data.initializeTimeZones();

  Get.put(AppLocalStorage(), permanent: true);

  GeneralBindings().dependencies();

  if (_isIos) {
    await _requestIosAlarmNotificationPermission();
  }

  await requestNotificationPermission();
  await requestAndroidAlarmReliabilityEnhancements();
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('ar', null);
  DateLocalizationHelper.init();
  DateLocalizationHelper.startTodayUpdater();

  if (_isIos) {
    await _captureIosAlarmColdStartTap();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const App());
}

bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

/// طلب صلاحية الإشعارات على iOS صراحة (لا تُطلب تلقائياً عند `.initialize()`).
Future<void> _requestIosAlarmNotificationPermission() async {
  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}

/// يحفظ حمولة منبّه iOS عند إطلاق التطبيق بالضغط على إشعار وهو مغلق تماماً؛
/// لا يُنقّل هنا لأن شجرة GetX/الملّاح لم تُركَّب بعد — يُستهلك لاحقاً في
/// [NotificationsController.onInit].
Future<void> _captureIosAlarmColdStartTap() async {
  final launchDetails = await FlutterLocalNotificationsPlugin()
      .getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp != true) return;

  final payloadStr = launchDetails!.notificationResponse?.payload;
  if (payloadStr == null || payloadStr.isEmpty) return;

  try {
    final decoded = jsonDecode(payloadStr) as Map<String, dynamic>;
    if (decoded['kind'] == 'event_alarm') {
      await AlarmPendingActionStore.save(decoded);
    }
  } catch (_) {}
}
