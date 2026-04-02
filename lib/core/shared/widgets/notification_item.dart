import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';

class NotificationItem extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final bool isHighlighted;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _blinkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    if (widget.isHighlighted) {
      _blinkController.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) _blinkController.stop();
      });
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = notification.isRead
        ? (isDark ? Colors.grey[900] : Colors.grey[100])
        : (isDark ? Colors.blueGrey[900] : Colors.blue[50]);

    final borderColor = notification.isRead
        ? (isDark ? Colors.grey[700] : Colors.grey[300])
        : (isDark ? Colors.blue[700] : Colors.blue[200]);

    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        final highlightOpacity = widget.isHighlighted ? _blinkAnimation.value * 0.5 : 0.0;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (highlightOpacity > 0)
                BoxShadow(
                  color: Colors.amber.withOpacity(highlightOpacity),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(type: widget.notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translateNotification(widget.notification),
                      style: TextStyle(
                        fontWeight: widget.notification.isRead
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
                        DateTime.parse(widget.notification.createdAt),
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
      ),
    );
  }

  String _translateNotification(NotificationModel notification) {
    final title = notification.title;

    final location = notification.data['location'];
    final locationText = (location != null && location.isNotEmpty)
        ? '📍 ${AppTexts.theSite}: $location'
        : '';

    final dateTimeText =
        notification.data['start_time'] != null &&
            notification.data['start_time'] != ''
        ? '${notification.data['start_date']}   ${notification.data['start_time']}'
        : '';

    switch (notification.type) {
      case NotificationType.eventInvitation:
        return [
          '${AppTexts.invitedToEvent}: $title',
          locationText,
          dateTimeText,
        ].where((e) => e.isNotEmpty).join('\n');

      case NotificationType.updateEvent:
        return [
          '🔄 ${AppTexts.updateEvent}: $title',
          locationText,
          dateTimeText,
        ].where((e) => e.isNotEmpty).join('\n');

      case NotificationType.deleteEvent:
        return [
          '❌ ${AppTexts.eventCancelled}: $title',
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
