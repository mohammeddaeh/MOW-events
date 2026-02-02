class StorageKeys {
  static const theme = 'app_theme';
  static const lang = 'app_lang';
  static const token = 'auth_token';
  static const user = 'auth_user';
  static String categories(int userId) => 'user_${userId}_categories';
  static String events(int userId) => 'user_${userId}_events';
  static String reminders(int userId) => 'user_${userId}_reminders';
  static String home(int userId) => 'user_${userId}_home';
  static const calendar = 'app_calendar';
  static const rememberMe = 'app_remember_me';
  static String scheduledReminders(int userId) =>
      'user_${userId}_scheduled_reminders';
  static String ignoredDefaults(int userId) =>
      'user_${userId}_ignored_defaults';
}
