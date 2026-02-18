import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = notification.isRead
        ? (isDark ? Colors.grey[900] : Colors.grey[100])
        : (isDark ? Colors.blueGrey[900] : Colors.blue[50]);

    final borderColor = notification.isRead
        ? (isDark ? Colors.grey[700] : Colors.grey[300])
        : (isDark ? Colors.blue[700] : Colors.blue[200]);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor!),
        boxShadow: [
          if (!notification.isRead)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationIcon(type: notification.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _translateNotification(notification),
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.bold,
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateLocalizationHelper.formatNotificationDate(
                      DateTime.parse(notification.createdAt),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// دالة لترجمة النص حسب نوع الإشعار
  /// دالة لترجمة النص حسب نوع الإشعار
  String _translateNotification(NotificationModel notification) {
    final title = notification.title;

    // مكان الحدث
    final location = notification.data['location'];
    final locationText = (location != null && location.isNotEmpty)
        ? '📍 المكان: $location'
        : '';

    // تاريخ ووقت الحدث
    final dateTimeText =
        notification.data['start_time'] != null &&
            notification.data['start_time'] != ''
        ? '${notification.data['start_date']}   ${notification.data['start_time']}'
        : '';

    switch (notification.type) {
      case NotificationType.eventInvitation:
        return [
          'تم دعوتك لحضور: $title',
          locationText,
          dateTimeText,
        ].where((e) => e.isNotEmpty).join('\n');

      case NotificationType.updateEvent:
        return [
          '🔄 تم تحديث الحدث: $title',
          locationText,
          dateTimeText,
        ].where((e) => e.isNotEmpty).join('\n');

      case NotificationType.deleteEvent:
        return [
          '❌ تم إلغاء الحدث: $title',
          locationText,
        ].where((e) => e.isNotEmpty).join('\n');
    }
  }
}

class _NotificationIcon extends StatelessWidget {
  final NotificationType type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: type.color.withOpacity(0.15),
      child: Icon(type.icon, color: type.color, size: 20),
    );
  }
}

class EmptyNotifications extends StatelessWidget {
  const EmptyNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            AppTexts.thereAreNoNotificationsAtTheMoment,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
