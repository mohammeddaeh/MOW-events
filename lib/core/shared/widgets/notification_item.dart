import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
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
  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;

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
    final notificationType = notification.resolvedType;
    final typeColor = _resolvedTypeColor(notificationType, isDark: isDark);
    final eventTitle = _eventTitle(notification);
    final createdAt = DateTime.tryParse(notification.createdAt);
    final timeDisplay = createdAt == null
        ? const _NotificationTimeDisplay()
        : _buildTimeDisplay(createdAt);

    final backgroundColor = notification.isRead
        ? (isDark ? Colors.grey[900]! : Colors.grey[100]!)
        : typeColor.withValues(alpha: isDark ? 0.24 : 0.11);

    final borderColor = notification.isRead
        ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
        : typeColor.withValues(alpha: isDark ? 0.78 : 0.42);

    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        final highlightOpacity = widget.isHighlighted
            ? _blinkAnimation.value * 0.5
            : 0.0;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (highlightOpacity > 0)
                BoxShadow(
                  color: Colors.amber.withValues(alpha: highlightOpacity),
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
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            if (!notification.isRead)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(500),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(
                type: notificationType,
                baseColor: typeColor,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(
                              alpha: isDark ? 0.28 : 0.14,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _notificationTypeLabel(notificationType),
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (timeDisplay.cornerText != null) ...[
                          const Spacer(),
                          Text(
                            timeDisplay.cornerText!,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      eventTitle,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.bold,
                        fontSize: 15,
                        height: 1.35,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (timeDisplay.footerLines.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...timeDisplay.footerLines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            line,
                            style: TextStyle(
                              color: AppThemeHelper.textSecondary(context),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: typeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _notificationTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.eventInvitation:
        return AppTexts.invitedToEvent;
      case NotificationType.updateEvent:
        return AppTexts.updateEvent;
      case NotificationType.deleteEvent:
        return AppTexts.eventCancelled;
      case NotificationType.acceptUserRegistration:
        return AppTexts.registrationApprovedTitle;
      case NotificationType.rejectUserRegistration:
        return AppTexts.registrationRejectedTitle;
    }
  }

  String _eventTitle(NotificationModel notification) {
    final type = notification.resolvedType;
    if (type.isRegistrationApproval) {
      final body = notification.displayBody.trim();
      if (body.isNotEmpty) return body;
      return notification.displayTitle;
    }

    final data = notification.data;
    final candidates = [
      data['event_name'],
      data['name'],
      data['event_title'],
      notification.title,
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return notification.body.trim().isNotEmpty
        ? notification.body.trim()
        : AppTexts.notifications;
  }

  _NotificationTimeDisplay _buildTimeDisplay(DateTime date) {
    final relativeText = DateLocalizationHelper.formatNotificationDate(date);
    if (_isRelativeTime(relativeText)) {
      return _NotificationTimeDisplay(cornerText: relativeText);
    }

    final time = DateLocalizationHelper.formatTime(date);
    final dateLines = DateLocalizationHelper.formatDateLines(date);

    switch (DateLocalizationHelper.userCalendar.value) {
      case 'hijri':
        return _NotificationTimeDisplay(
          footerLines: ['${dateLines.first} - $time'],
        );
      case 'both':
        return _NotificationTimeDisplay(
          footerLines: ['${dateLines.first} - $time', dateLines.last],
        );
      case 'gregorian':
      default:
        return _NotificationTimeDisplay(
          footerLines: ['${dateLines.first} - $time'],
        );
    }
  }

  bool _isRelativeTime(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.contains(AppTexts.ago.toLowerCase()) ||
        normalized.contains('مضى') ||
        normalized == AppTexts.now.toLowerCase() ||
        normalized == 'الآن';
  }

  Color _resolvedTypeColor(NotificationType type, {required bool isDark}) {
    switch (type) {
      case NotificationType.eventInvitation:
        return isDark ? AppColors.accent : AppColors.primary;
      case NotificationType.updateEvent:
        return isDark ? const Color(0xFFE5C06C) : AppColors.gold;
      case NotificationType.deleteEvent:
        return isDark ? const Color(0xFFFF7A70) : AppColors.errorPrimary;
      case NotificationType.acceptUserRegistration:
        return isDark ? AppColors.accent : AppColors.primary;
      case NotificationType.rejectUserRegistration:
        return isDark ? const Color(0xFFFF7A70) : AppColors.errorPrimary;
    }
  }
}

class _NotificationTimeDisplay {
  final String? cornerText;
  final List<String> footerLines;

  const _NotificationTimeDisplay({
    this.cornerText,
    this.footerLines = const [],
  });
}

class _NotificationIcon extends StatelessWidget {
  final NotificationType type;
  final Color baseColor;
  final bool isDark;

  const _NotificationIcon({
    required this.type,
    required this.baseColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isInvitation = type == NotificationType.eventInvitation;
    final iconColor = isInvitation && isDark ? Colors.white : baseColor;
    final backgroundColor = isInvitation
        ? (isDark
              ? baseColor.withValues(alpha: 0.95)
              : baseColor.withValues(alpha: 0.18))
        : baseColor.withValues(alpha: isDark ? 0.34 : 0.18);

    return CircleAvatar(
      radius: 20,
      backgroundColor: backgroundColor,
      child: Icon(type.icon, color: iconColor, size: 20),
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
          const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            AppTexts.thereAreNoNotificationsAtTheMoment,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
