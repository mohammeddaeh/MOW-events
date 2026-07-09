import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/shared/widgets/notification_item.dart';
import 'package:mow_events/core/shared/widgets/pagination_footer.dart';
import 'package:mow_events/core/utils/error/api_exceptions.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/widgets/card_event.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';
import 'package:mow_events/features/notifications/handlers/registration_approval_notification_handler.dart';
import 'package:mow_events/features/notifications/presentation/controller/notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isOpeningNotification = false;
  bool _openRequestLock = false;
  DateTime? _lastDeletedNoticeAt;
  String? _lastDeletedNoticeNotificationId;

  void _setTapLock(bool value) {
    if (!mounted || _isOpeningNotification == value) return;
    setState(() {
      _isOpeningNotification = value;
    });
  }

  @override
  void initState() {
    super.initState();
    final controller = Get.find<NotificationsController>();
    final args = Get.arguments as Map<String, dynamic>?;
    controller.setPendingFromArguments(args);
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 180) {
        controller.loadMore();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToHighlighted(controller);
      _autoOpenEventIfNeeded(controller);
    });
  }

  void _scrollToHighlighted(NotificationsController controller) {
    final id = controller.highlightNotificationId.value;
    if (id == null || !_scrollController.hasClients) return;
    final index = controller.notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      const itemHeight = 90.0;
      final offset = (index * itemHeight).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _autoOpenEventIfNeeded(
    NotificationsController controller,
  ) async {
    final eventId = controller.autoOpenEventId.value;
    if (eventId == null || eventId <= 0) return;
    controller.autoOpenEventId.value = null;
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
      await _openEventDetailsAndMarkRead(controller, notification);
    } else {
      // الإشعار غير موجود في القائمة (تأخر API أو عدم تطابق) — نفتح الحدث مباشرةً
      await _openEventDirectlyById(controller, eventId);
    }
  }

  Future<void> _openEventDirectlyById(
    NotificationsController controller,
    int eventId,
  ) async {
    if (!mounted) return;
    try {
      final homeController = Get.find<HomeController>();
      final event = await homeController.eventRepo.getEventDetails(eventId);
      if (!mounted) return;
      await CardEvent.showEventDetailsSheet(context, event, homeController);
    } catch (_) {}
  }

  Future<void> _openEventDetailsAndMarkRead(
    NotificationsController controller,
    NotificationModel notification,
  ) async {
    if (_openRequestLock || _isOpeningNotification) return;
    _openRequestLock = true;
    _setTapLock(true);
    final notificationType = notification.resolvedType;

    try {
      if (notificationType == NotificationType.acceptUserRegistration ||
          notificationType == NotificationType.rejectUserRegistration) {
        await RegistrationApprovalNotificationHandler.handlePayload(
          data: notification.data,
          title: notification.title,
          body: notification.body,
          clicked: true,
        );
        if (!notification.isRead) {
          await controller.markAsRead(notification.id);
        }
        return;
      }

      if (notification.eventId <= 0 ||
          notificationType == NotificationType.deleteEvent) {
        await _handleDeletedEventNotification(controller, notification);
        return;
      }
      try {
        final homeController = Get.find<HomeController>();
        final EventModel event = await homeController.eventRepo.getEventDetails(
          notification.eventId,
        );
        if (!mounted) return;
        await CardEvent.showEventDetailsSheet(
          context,
          event,
          homeController,
          onClosed: () => controller.markAsRead(notification.id),
        );
      } on NotFoundException {
        await _handleDeletedEventNotification(controller, notification);
      } catch (e) {
        if (_isBackendEventNotFound(e)) {
          await _handleDeletedEventNotification(controller, notification);
        } else {
          await controller.markAsRead(notification.id);
        }
      }
    } finally {
      _openRequestLock = false;
      _setTapLock(false);
    }
  }

  Future<void> _handleDeletedEventNotification(
    NotificationsController controller,
    NotificationModel notification,
  ) async {
    if (!notification.isRead) {
      await controller.markAsRead(notification.id);
    }
    final now = DateTime.now();
    final last = _lastDeletedNoticeAt;
    final sameNotificationRepeatedFast =
        _lastDeletedNoticeNotificationId == notification.id &&
        last != null &&
        now.difference(last).inMilliseconds < 3000;
    final anyDeletedNoticeTooSoon =
        last != null && now.difference(last).inMilliseconds < 1200;
    if (sameNotificationRepeatedFast || anyDeletedNoticeTooSoon) {
      return;
    }
    _lastDeletedNoticeAt = now;
    _lastDeletedNoticeNotificationId = notification.id;
    if (Get.isSnackbarOpen) {
      AppSnackBars.hideSnackBar();
    }
    AppSnackBars.infoSnackBar(
      title: AppTexts.notifications,
      message: AppTexts.eventDeletedMessage,
    );
  }

  bool _isBackendEventNotFound(Object error) {
    if (error is NotFoundException) return true;
    if (error is ApiException && error.statusCode == 404) return true;

    final normalized = error.toString().toLowerCase();
    return normalized.contains('Item not found') ||
        normalized.contains('item not found') ||
        normalized.contains('not found') ||
        normalized.contains('statuscode: 404') ||
        normalized.contains('status code: 404') ||
        normalized.contains('"status":404') ||
        normalized.contains('"statuscode":404') ||
        normalized.contains('resource does not exist') ||
        normalized.contains('الحدث غير موجود') ||
        normalized.contains('غير موجود') ||
        normalized.contains('تم حذف');
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

        final shouldShowFooter = controller.notifications.isNotEmpty;

        return IgnorePointer(
          ignoring: _isOpeningNotification,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount:
                controller.notifications.length + (shouldShowFooter ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              if (index >= controller.notifications.length) {
                return PaginationFooter(
                  isLoadingMore: controller.isLoadingMore.value,
                  hasMore: controller.hasMoreNotifications.value,
                  actionLabel: AppTexts.viewmore,
                  loadingLabel: AppTexts.loadingMoreNotifications,
                  completedLabel: AppTexts.allNotificationsLoaded,
                  onLoadMore: controller.loadMore,
                );
              }
              final notification = controller.notifications[index];
              final isHighlighted =
                  controller.highlightNotificationId.value == notification.id;

              return NotificationItem(
                notification: notification,
                isHighlighted: isHighlighted,
                onTap: () =>
                    _openEventDetailsAndMarkRead(controller, notification),
              );
            },
          ),
        );
      }),
    );
  }
}
