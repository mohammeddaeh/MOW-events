import 'package:get/get.dart';
import 'package:mow_events/core/alarm/event_alarm_service.dart';
import 'package:mow_events/core/utils/local_storage/AuthStorage/auth_storage.dart';
import 'package:mow_events/core/utils/local_storage/UserStorage/user_storage.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/services/registration_approval_service.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';

class AuthService {
  static bool isLoggingOut = false;
  static bool isSessionExpiredHandling = false;
  static bool isInactiveAccountHandling = false;

  static final _authStorage = AuthStorage();

  static Future<void> setToken(String token) async {
    await _authStorage.saveToken(token);
  }

  static String get token {
    final t = _authStorage.token;
    if (t == null || t.isEmpty) return '';
    return t;
  }

  static bool get authenticated {
    final t = _authStorage.token;
    return t != null && t.isNotEmpty;
  }

  static Future<void> saveUser(Map<String, dynamic> userJson) async {
    await _authStorage.saveUser(userJson);

    if (Get.isRegistered<ReminderController>()) {
      ReminderController.to.reloadUserScopedState();
    }
  }

  static UserModel? get currentUser {
    final json = _authStorage.user;
    if (json == null) return null;

    final Map<String, dynamic> fixedJson = Map<String, dynamic>.from(json);

    return UserModel.fromJson(fixedJson);
  }

  static Future<void> logout() async {
    final user = currentUser;

    if (Get.isRegistered<ReminderController>()) {
      await ReminderController.to.clearUserScopedState();
    }

    if (Get.isRegistered<EventAlarmService>()) {
      await EventAlarmService.to.cancelAll();
    }

    if (user != null) {
      await UserStorage().clearAllUserDataFor(user.id);
    }

    await RegistrationApprovalService.clear();
    await _authStorage.clear();
  }
}
