import 'package:mow_events/core/utils/error/api_exceptions.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

/// استخراج التوكن والمستخدم من استجابة login / register / edit_register.
class AuthResponseParser {
  AuthResponseParser._();

  static AuthSessionData parseSession(
    Map<String, dynamic> res, {
    String? fallbackToken,
  }) {
    if (res['status'] != true) {
      throw ApiException(
        res['message']?.toString() ?? AppTexts.unableToCreateAccount,
      );
    }

    final data = res['data'];
    if (data is! Map) {
      throw ApiException(AppTexts.unableToCreateAccount);
    }

    final map = Map<String, dynamic>.from(data);
    final token =
        (map['access_token'] ?? map['token'])?.toString() ?? fallbackToken;
    if (token == null || token.isEmpty) {
      throw ApiException(AppTexts.unableToCreateAccount);
    }

    final userRaw = map['user'] ?? map;
    if (userRaw is! Map) {
      throw ApiException(AppTexts.unableToCreateAccount);
    }

    return AuthSessionData(
      token: token,
      userJson: Map<String, dynamic>.from(userRaw),
    );
  }
}

class AuthSessionData {
  final String token;
  final Map<String, dynamic> userJson;

  const AuthSessionData({
    required this.token,
    required this.userJson,
  });
}
