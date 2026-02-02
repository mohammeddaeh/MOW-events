import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mow_events/app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mow_events/core/general/bindings.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:permission_handler/permission_handler.dart';

// التشغيل بالخلفية مشان و التذكيرات

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  Get.put(AppLocalStorage(), permanent: true);

  GeneralBindings().dependencies();

  await requestNotificationPermission();
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('ar', null);
  DateLocalizationHelper.init();
  DateLocalizationHelper.startTodayUpdater();
  await Firebase.initializeApp();
  runApp(const App());
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}
