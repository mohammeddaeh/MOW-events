import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/notification_item.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/widgets/card_event.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';
import 'package:mow_events/features/notifications/presentation/controller/notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final controller = Get.find<NotificationsController>();
    final args = Get.arguments as Map<String, dynamic>?;
    controller.setPendingFromArguments(args);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToHighlighted(controller);
      _autoOpenEventIfNeeded(controller);
    });
  }

  void _scrollToHighlighted(NotificationsController controller) {
    final id = controller.highlightNotificationId.value;
    if (id == null || !_scrollController.hasClients) return;
    final index = controller.notifications
        .indexWhere((n) => n.id == id);
    if (index >= 0) {
      const itemHeight = 90.0;
      final offset = (index * itemHeight).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _autoOpenEventIfNeeded(NotificationsController controller) async {
    final eventId = controller.autoOpenEventId.value;
    if (eventId == null || eventId <= 0) return;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    NotificationModel? notification;
    for (final n in controller.notifications) {
      if (n.eventId == eventId) {
        notification = n;
        break;
      }
    }
    if (notification != null) {
      controller.autoOpenEventId.value = null;
      await _openEventDetailsAndMarkRead(controller, notification);
    }
  }

  Future<void> _openEventDetailsAndMarkRead(
    NotificationsController controller,
    NotificationModel notification,
  ) async {
    if (notification.eventId <= 0 ||
        notification.type == NotificationType.deleteEvent) {
      await controller.markAsRead(notification.id);
      return;
    }
    try {
      final homeController = Get.find<HomeController>();
      final EventModel event =
          await homeController.eventRepo.getEventDetails(notification.eventId);
      if (!mounted) return;
      await CardEvent.showEventDetailsSheet(
        context,
        event,
        homeController,
        onClosed: () => controller.markAsRead(notification.id),
      );
    } catch (_) {
      await controller.markAsRead(notification.id);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.find<NotificationsController>().clearHighlight();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTexts.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await controller.repository.markAllAsRead();
              for (int i = 0; i < controller.notifications.length; i++) {
                controller.notifications[i] = controller.notifications[i]
                    .copyWith(isRead: true);
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return const EmptyNotifications();
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scroll) {
            if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent) {
              controller.loadMore();
            }
            return false;
          },
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount:
                controller.notifications.length +
                (controller.isLoading.value ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index >= controller.notifications.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final notification = controller.notifications[index];
              final isHighlighted =
                  controller.highlightNotificationId.value == notification.id;

              return NotificationItem(
                notification: notification,
                isHighlighted: isHighlighted,
                onTap: () => _openEventDetailsAndMarkRead(
                  controller,
                  notification,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
