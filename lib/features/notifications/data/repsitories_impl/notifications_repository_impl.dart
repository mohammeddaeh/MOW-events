import 'dart:async';

import 'package:mow_events/features/notifications/data/data_sources/notifications_backend.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';
import 'package:mow_events/features/notifications/domin/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsBackend backend;

  NotificationsRepositoryImpl({required this.backend});

  Future<T> _safe<T>(
    Future<T> future, {
    required String timeoutMsg,
    Duration duration = const Duration(seconds: 15),
  }) {
    return future.timeout(
      duration,
      onTimeout: () => throw TimeoutException(timeoutMsg),
    );
  }

  @override
  Future<void> setFcmToken(String token) => _safe(
    backend.setFcmToken(token),
    timeoutMsg: 'Setting FCM token timed out',
  );

  @override
  Future<NotificationsResponse> getAllNotifications({int page = 1}) => _safe(
    backend.getAllNotifications(page: page),
    timeoutMsg: 'Fetching notifications timed out',
  );

  @override
  Future<NotificationsResponse> getUnreadNotifications({int page = 1}) => _safe(
    backend.getUnreadNotifications(page: page),
    timeoutMsg: 'Fetching unread notifications timed out',
  );

  @override
  Future<void> markAsRead(String id) => _safe(
    backend.markAsRead(id),
    timeoutMsg: 'Marking notification as read timed out',
  );

  @override
  Future<void> markAllAsRead() => _safe(
    backend.markAllAsRead(),
    timeoutMsg: 'Marking all notifications as read timed out',
  );

  @override
  Future<void> removeNotifications(List<String> ids) => _safe(
    backend.removeNotifications(ids),
    timeoutMsg: 'Removing notifications timed out',
  );

  @override
  Future<void> clearNotifications() => _safe(
    backend.clearNotifications(),
    timeoutMsg: 'Clearing notifications timed out',
  );
}
