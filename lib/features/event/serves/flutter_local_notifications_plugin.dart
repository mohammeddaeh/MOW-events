// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// Future<void> initNotifications() async {
//   const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//   const iosInit = DarwinInitializationSettings();
//   const settings = InitializationSettings(android: androidInit, iOS: iosInit);

//   await flutterLocalNotificationsPlugin.initialize(
//     settings,
//     onDidReceiveNotificationResponse: (details) {
//       final eventId = details.payload;
//       if (eventId != null) {
//         ReminderController.to.showReminderScreenById(eventId);
//       }
//     },
//   );

//   const androidChannel = AndroidNotificationChannel(
//     'event_reminder',
//     'Event Reminder',
//     description: 'Channel for event reminders',
//     importance: Importance.max,
//     playSound: true,
//   );

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(androidChannel);
// }
