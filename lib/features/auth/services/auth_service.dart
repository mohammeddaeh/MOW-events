import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';
import 'package:mow_events/core/utils/local_storage/AuthStorage/auth_storage.dart';
import 'package:mow_events/core/utils/local_storage/UserStorage/user_storage.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';

class AuthService {
  static bool isLoggingOut = false;

  static final _authStorage = AuthStorage();
  static final _appStorage = AppStorage();

  static Future<void> setToken(String token) async {
    await _authStorage.saveToken(token);
  }

  static String get token {
    final t = _authStorage.token;
    if (t == null || t.isEmpty) return '';
    return 'Bearer $t';
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

// class AuthService {
//   static final _storage = GetStorage();

//   static bool isLoggingOut = false;

//   static Future<void> setToken(String token) async {
//     await _storage.write('token', token);
//   }

//   static String get token {
//     final storedToken = _storage.read('token');
//     if (storedToken == null) return '';
//     return 'Bearer $storedToken';
//   }

//   static bool get authenticated {
//     try {
//       final storedToken = _storage.read('token');
//       return storedToken != null && storedToken.isNotEmpty;
//     } catch (_) {
//       return false;
//     }
//   }

//   static Future<void> saveUser(Map<String, dynamic> userJson) async {
//     final sanitizedJson = {
//       'id': userJson['id'],
//       'first_name': userJson['first_name'] ?? '',
//       'last_name': userJson['last_name'] ?? '',
//       'full_name': userJson['full_name'] ?? '',
//       'email': userJson['email'] ?? '',
//       'phone': userJson['phone'] ?? '',
//       'image': userJson['image'],
//       'address': userJson['address'],
//       'is_active': userJson['is_active'] ?? 1,
//       'is_admin': userJson['is_admin'] ?? false,
//       'department': userJson['department'],
//     };

//     await _storage.write('user', sanitizedJson);
//   }

//   static UserModel? get currentUser {
//     final json = _storage.read('user');
//     if (json == null) return null;
//     return UserModel.fromJson(json);
//   }

//   static Future<void> logout() async {
//     await _storage.remove('token');
//     await _storage.remove('user');
//   }
// }
