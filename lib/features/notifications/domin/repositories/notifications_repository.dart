import 'package:mow_events/features/notifications/data/models/notification_model.dart';

abstract class NotificationsRepository {
  Future<void> setFcmToken(String token);
  Future<NotificationsResponse> getAllNotifications({int page = 1});
  Future<NotificationsResponse> getUnreadNotifications({int page = 1});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> removeNotifications(List<String> ids);
  Future<void> clearNotifications();
}
