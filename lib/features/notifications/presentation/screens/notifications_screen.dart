import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/notification_item.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/notifications/presentation/controller/notifications_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
              return NotificationItem(
                notification: notification,
                onTap: () {
                  controller.markAsRead(notification.id);
                },
              );
            },
          ),
        );
      }),
    );
  }
}
