// import 'dart:async';
// import 'dart:developer';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Future<void> initService() async {
//   final service = FlutterBackgroundService();
//   try {
//     await service.configure(
//       iosConfiguration: IosConfiguration(
//         autoStart: true,
//         onForeground: onStart,
//         onBackground: onIosBackground,
//       ),
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         isForegroundMode: true,
//         autoStart: true, // تشغيل تلقائي
//         foregroundServiceNotificationId: 888,
//       ),
//     );
//   } catch (e) {
//     log('error in background service $e');
//   }
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   if (service is AndroidServiceInstance) {
//     // 👇 مهم جداً
//     service.setForegroundNotificationInfo(
//       title: "Foreground Service",
//       content: "Running in background",
//     );
//     service.setAsForegroundService(); // فعل foreground فوراً
//   }

//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
//  }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();
//   return true;
// }
