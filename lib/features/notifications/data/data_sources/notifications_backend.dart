import 'package:mow_events/core/utils/error/api_exceptions.dart';
import 'package:mow_events/core/utils/http/api_endpoints.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';

import '../../../../core/utils/helpers/http_helper.dart';

class NotificationsBackend {
  Future<void> setFcmToken(String token) async {
    final res = await HttpHelper.post(
      ApiEndpoints.fcmSetToken,
      {'device_token': token},
    );

    if (res['status'] == false) {
      final message =
          res['message']?.toString() ??
          res['error']?.toString() ??
          AppTexts.fcmTokenSyncFailed;
      throw ApiException(message);
    }
  }

  Future<NotificationsResponse> getAllNotifications({int page = 1}) async {
    final url = page == 1
        ? ApiEndpoints.notificationsAll
        : '${ApiEndpoints.notificationsAll}?page=$page';
    final res = await HttpHelper.get(url);
    return NotificationsResponse.fromJson(res['data']);
  }

  Future<NotificationsResponse> getUnreadNotifications({int page = 1}) async {
    final url = page == 1
        ? ApiEndpoints.notificationsUnread
        : '${ApiEndpoints.notificationsUnread}?page=$page';
    final res = await HttpHelper.get(url);
    return NotificationsResponse.fromJson(res['data']);
  }

  Future<void> markAsRead(String id) async {
    await HttpHelper.post(ApiEndpoints.notificationsRead, {'id': id});
  }

  Future<void> markAllAsRead() async {
    await HttpHelper.post(ApiEndpoints.notificationsRead, {});
  }

  Future<void> removeNotifications(List<String> ids) async {
    final endpoint = ApiEndpoints.notificationsRemove(ids);
    await HttpHelper.delete(endpoint);
  }

  Future<void> clearNotifications() async {
    await HttpHelper.delete(ApiEndpoints.notificationsClear);
  }
}
