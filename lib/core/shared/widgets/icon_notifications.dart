// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/features/notifications/presentation/controller/notifications_controller.dart';

class IconNotifications extends StatelessWidget {
  const IconNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();

    return Obx(() {
      final unreadCount = controller.notifications
          .where((n) => !n.isRead)
          .length;

      return Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Get.toNamed(AppRouter.notifications);
            },
          ),
          if (unreadCount > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      );
    });
  }
}
