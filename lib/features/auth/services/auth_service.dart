import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';
import 'package:mow_events/core/utils/local_storage/AuthStorage/auth_storage.dart';
import 'package:mow_events/core/utils/local_storage/UserStorage/user_storage.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';

class AuthService {
  static bool isLoggingOut = false;
  static bool isSessionExpiredHandling = false;

  static final _authStorage = AuthStorage();
  static final _appStorage = AppStorage();

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
  }

  static UserModel? get currentUser {
    final json = _authStorage.user;
    if (json == null) return null;

    final Map<String, dynamic> fixedJson = Map<String, dynamic>.from(json);

    return UserModel.fromJson(fixedJson);
  }

  static Future<void> logout() async {
    final user = currentUser;

    if (user != null) {
      await UserStorage().clearAllUserData();
    }

    await _authStorage.clear();
    await _appStorage.setRememberMe(false);
  }
}
