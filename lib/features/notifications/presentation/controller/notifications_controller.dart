import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/error/api_exceptions.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';
import 'package:mow_events/features/notifications/domin/repositories/notifications_repository.dart';

class NotificationsController extends GetxController {
  final NotificationsRepository repository;

  NotificationsController({required this.repository});

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> highlightNotificationId = Rx<String?>(null);
  final Rx<int?> autoOpenEventId = Rx<int?>(null);
  final HomeController homeController = Get.find<HomeController>();

  int _page = 1;
  bool _hasMore = true;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    _initLocalNotifications();
    _initFirebaseMessaging();
    fetchNotifications();
  }

  Future<void> syncFcmTokenWithUser() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await repository.setFcmToken(token);
    }
  }

  Future<void> _initFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await repository.setFcmToken(newToken);
    });

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();

    if (token != null) {
      await repository.setFcmToken(token);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleFcmMessage(message, foreground: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleFcmMessage(message, clicked: true);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleFcmMessage(initialMessage, clicked: true);
      });
    }
  }

  void setPendingFromArguments(Map<String, dynamic>? args) {
    if (args == null) return;
    final highlightId = args['highlightId'] as String?;
    final eventId = args['eventId'] as int?;
    if (highlightId != null) highlightNotificationId.value = highlightId;
    if (eventId != null && eventId > 0) autoOpenEventId.value = eventId;
  }

  void clearHighlight() {
    highlightNotificationId.value = null;
    autoOpenEventId.value = null;
  }

  void _handleFcmMessage(
    RemoteMessage message, {
    bool foreground = false,
    bool clicked = false,
  }) async {
    try {
      final data = message.data;
      final notification = message.notification;

      final type = NotificationTypeExtension.fromString(
        data['notification_type'],
      );

      final eventId = int.tryParse(data['event_id'] ?? '0') ?? 0;

      final model = NotificationModel(
        id: data['id'] ?? UniqueKey().toString(),
        type: type,
        title: notification?.title ?? '',
        body: notification?.body ?? '',
        data: data,
        eventId: eventId,
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      notifications.insert(0, model);

      final reminderCtrl = ReminderController.to;

      switch (type) {
        case NotificationType.eventInvitation:
        case NotificationType.updateEvent:
          await _syncEvent(eventId);
          break;

        case NotificationType.deleteEvent:
          homeController.allEvents.removeWhere((e) => e.id == eventId);
          homeController.allEvents.refresh();
          await reminderCtrl.onEventDeleted(eventId.toString());
          homeController.applySettings();
          homeController.processedEvents.refresh();
          await homeController.saveEvents();
          break;
      }

      if (foreground) {
        _showLocalNotification(model);
      }

      if (clicked) {
        Get.toNamed(
          AppRouter.notifications,
          arguments: {'highlightId': model.id, 'eventId': model.eventId},
        );
      }
    } catch (e) {
      return;
    }
  }

  void _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            final eventId =
                int.tryParse(data['event_id']?.toString() ?? '0') ?? 0;
            final id = data['id']?.toString();
            Get.toNamed(
              AppRouter.notifications,
              arguments: {
                if (id != null) 'highlightId': id,
                if (eventId > 0) 'eventId': eventId,
              },
            );
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _syncEvent(int eventId) async {
    try {
      final event = await homeController.eventRepo.getEventDetails(eventId);

      final index = homeController.allEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) {
        homeController.allEvents.add(event);
        homeController.allEvents.refresh();
        await ReminderController.to.onEventAdded(event);
      } else {
        homeController.allEvents[index] = event;
        homeController.allEvents.refresh();
        await ReminderController.to.onEventUpdated(event);
      }

      homeController.applySettings();
      homeController.processedEvents.refresh();
      await homeController.saveEvents();
    } on NotFoundException {
      homeController.allEvents.removeWhere((e) => e.id == eventId);
      homeController.allEvents.refresh();
      await ReminderController.to.onEventDeleted(eventId.toString());
      homeController.applySettings();
      homeController.processedEvents.refresh();
      await homeController.saveEvents();
    } catch (_) {}
  }

  Future<void> _showLocalNotification(NotificationModel model) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fcm_channel_id',
          'App Notifications',
          channelDescription: 'Foreground notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      model.id.hashCode,
      model.title,
      model.body,
      details,
      payload: jsonEncode(model.data),
    );
  }

  Future<void> fetchNotifications({bool loadMore = false}) async {
    if (isLoading.value) return;
    if (loadMore && !_hasMore) return;

    isLoading.value = true;

    try {
      if (!loadMore) {
        _page = 1;
        notifications.clear();
      }

      final res = await repository.getAllNotifications(page: _page);
      notifications.addAll(res.items);

      _hasMore = res.hasMorePages;
      _page++;
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  void loadMore() {
    fetchNotifications(loadMore: true);
  }

  Future<void> markAsRead(String id) async {
    await repository.markAsRead(id);

    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
    }
  }
}
