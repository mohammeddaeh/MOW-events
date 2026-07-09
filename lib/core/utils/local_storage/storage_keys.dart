class StorageKeys {
  static const theme = 'app_theme';
  static const lang = 'app_lang';
  static const token = 'auth_token';
  static const user = 'auth_user';
  static const legacyDefaultReminders = 'default_reminders';
  static String categories(int userId) => 'user_${userId}_categories';
  static String events(int userId) => 'user_${userId}_events';
  static String reminders(int userId) => 'user_${userId}_reminders';
  static String home(int userId) => 'user_${userId}_home';
  static String defaultReminders(int userId) =>
      'user_${userId}_default_reminders';
  static const calendar = 'app_calendar';
  static const timeFormat = 'app_time_format';
  static const rememberMe = 'app_remember_me';
  static const registrationApprovalStatus = 'registration_approval_status';
  static const registrationRejectionReason = 'registration_rejection_reason';
  static const registrationSubmissionSnapshot =
      'registration_submission_snapshot';
  static String scheduledReminders(int userId) =>
      'user_${userId}_scheduled_reminders';
  static String ignoredDefaults(int userId) =>
      'user_${userId}_ignored_defaults';
}
