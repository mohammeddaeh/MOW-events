class ApiEndpoints {
  static const String dashboardBase = 'api/v1/dashboard';
  static const String eventsBase = '$dashboardBase/events';
  static const String login = '$dashboardBase/login';
  static const String logout = '$dashboardBase/logout';

  static const String forgotPassword = '$dashboardBase/forget-password';
  static const String checkResetCode =
      '$dashboardBase/forget-password/check/code';
  static const String resetPassword = '$dashboardBase/reset-password';
  static const String editProfile = '$dashboardBase/profile/edit';

  static const String alluser = '$dashboardBase/users/index';

  static const String eventsIndex = '$eventsBase/index';
  static const String eventsStore = '$eventsBase/store';
  static String eventsShow(int id) => '$eventsBase/show/$id';
  static String eventsUpdate(int id) => '$eventsBase/update/$id';
  static const String eventsDelete = '$eventsBase/delete';
  static String eventShowMembers(int id) => '$eventsBase/show/$id/members';
  static const String profile = '$dashboardBase/profile';

  static const String fcmSetToken =
      '$dashboardBase/notifications/fcm/set-token';
  static const String notificationsAll = '$dashboardBase/notifications/all';
  static const String notificationsUnread =
      '$dashboardBase/notifications/unread';
  static const String notificationsRead = '$dashboardBase/notifications/read';
  static String notificationsRemove(List<String> ids) {
    final params = ids
        .asMap()
        .entries
        .map((e) => 'ids[${e.key}]=${e.value}')
        .join('&');
    return '$dashboardBase/notifications/remove?$params';
  }

  static const String notificationsClear = '$dashboardBase/notifications/clear';

  static const String categoriesIndex = '$dashboardBase/categories/index';
  static const String categoriesStore = '$dashboardBase/categories/store';
  static String categoriesShow(int id) => '$dashboardBase/categories/show/$id';
  static String categoriesUpdate(int id) =>
      '$dashboardBase/categories/update/$id';
  static const String categoriesDelete = '$dashboardBase/categories/delete';
}
