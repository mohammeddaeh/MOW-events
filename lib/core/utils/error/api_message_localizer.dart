import 'dart:convert';

import 'package:mow_events/core/utils/translation/app_texts.dart';

/// ترجمة رسائل الأخطاء الشائعة القادمة من الباكند (Laravel validation).
class ApiMessageLocalizer {
  ApiMessageLocalizer._();

  static bool? _phoneLoginContext;

  static String extractFromResponse(
    Map<String, dynamic> res, {
    String? fallback,
  }) {
    final fromError = extractDynamicMessage(res['error']);
    if (fromError.isNotEmpty) return localize(fromError);

    final fromMessage = extractDynamicMessage(res['message']);
    if (fromMessage.isNotEmpty) return localize(fromMessage);

    return fallback ?? AppTexts.unexpectedError;
  }

  static String extractDynamicMessage(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return '';
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed);
          final nested = extractDynamicMessage(decoded);
          if (nested.isNotEmpty) return nested;
        } catch (_) {}
      }
      return trimmed;
    }
    if (raw is List) {
      for (final item in raw) {
        final text = extractDynamicMessage(item);
        if (text.isNotEmpty) return text;
      }
      return '';
    }
    if (raw is Map) {
      final preferred = raw['message'] ?? raw['msg'] ?? raw['error'];
      final preferredText = extractDynamicMessage(preferred);
      if (preferredText.isNotEmpty) return preferredText;

      for (final entry in raw.entries) {
        final text = extractDynamicMessage(entry.value);
        if (text.isNotEmpty) {
          return localizeField(entry.key.toString(), text);
        }
      }
    }
    return '';
  }

  static String forSnackBar(String? message, {int maxLength = 160}) {
    final text = localize(message?.trim());
    if (text.isEmpty) return AppTexts.unexpectedError;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trim()}…';
  }
  /// يحدّد رسالة «هاتف/كلمة مرور» بدل «بريد/كلمة مرور» أثناء طلب تسجيل الدخول.
  static Future<T> runWithPhoneLoginMessage<T>(
    bool isPhoneLogin,
    Future<T> Function() action,
  ) async {
    final previous = _phoneLoginContext;
    _phoneLoginContext = isPhoneLogin;
    try {
      return await action();
    } finally {
      _phoneLoginContext = previous;
    }
  }

  static String localize(String? message) {
    if (message == null) return '';
    final trimmed = message.trim();
    if (trimmed.isEmpty) return trimmed;

    if (_isCanonicalLoginFailureMessage(trimmed)) return trimmed;

    final normalized = trimmed.toLowerCase();

    if (_isEmailTaken(normalized)) return AppTexts.emailAlreadyTaken;
    if (_isPhoneTaken(normalized)) return AppTexts.phoneAlreadyTaken;
    if (_isInvalidLoginCredentials(normalized)) {
      return _invalidLoginCredentialsMessage();
    }
    if (_isServerInternalMessage(normalized)) {
      return AppTexts.registrationProfileCheckUnavailable;
    }

    return trimmed;
  }

  static bool isProfileUnavailableError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('profilecontroller') ||
        text.contains('getauth') ||
        text.contains('authenticatable') ||
        text.contains('null returned');
  }

  static bool _isServerInternalMessage(String normalized) {
    return normalized.contains('profilecontroller') ||
        normalized.contains('getauth') ||
        normalized.contains('authenticatable') ||
        normalized.contains('return value must be of type');
  }

  static String localizeField(String field, String message) {
    final fieldKey = field.trim().toLowerCase();
    final normalized = message.trim().toLowerCase();

    if (fieldKey == 'email' &&
        (_isEmailTaken(normalized) || _isTakenPhrase(normalized))) {
      return AppTexts.emailAlreadyTaken;
    }
    if (fieldKey == 'phone' &&
        (_isPhoneTaken(normalized) || _isTakenPhrase(normalized))) {
      return AppTexts.phoneAlreadyTaken;
    }
    if ((fieldKey == 'email' || fieldKey == 'password') &&
        _isInvalidLoginCredentials(normalized)) {
      return _invalidLoginCredentialsMessage();
    }

    return localize(message);
  }

  static String _invalidLoginCredentialsMessage() {
    if (_phoneLoginContext == true) {
      return AppTexts.incorrectPhoneOrPassword;
    }
    return AppTexts.incorrectEmailOrPassword;
  }

  static bool _isCanonicalLoginFailureMessage(String message) {
    return message == AppTexts.incorrectPhoneOrPassword ||
        message == AppTexts.incorrectEmailOrPassword;
  }

  static bool _isInvalidLoginCredentials(String normalized) {
    final compact = normalized.replaceAll(RegExp(r'[\s_-]+'), '');

    if (compact.contains('incorrect') &&
        (compact.contains('login') ||
            compact.contains('password') ||
            compact.contains('credential'))) {
      return true;
    }
    if (compact.contains('inputlogin') ||
        compact.contains('invalidlogin') ||
        compact.contains('wrongpassword') ||
        compact.contains('failedlogin')) {
      return true;
    }
    if (normalized.contains('authentication failed') ||
        normalized.contains('invalid credentials') ||
        normalized.contains('credentials do not match') ||
        normalized.contains('could not authenticate')) {
      return true;
    }
    if ((normalized.contains('email') || normalized.contains('phone')) &&
        normalized.contains('password') &&
        (normalized.contains('incorrect') ||
            normalized.contains('invalid') ||
            normalized.contains('wrong'))) {
      return true;
    }
    if (normalized.contains('غير صحيح') &&
        (normalized.contains('مرور') ||
            normalized.contains('دخول') ||
            normalized.contains('بريد') ||
            normalized.contains('هاتف') ||
            normalized.contains('رقم'))) {
      return true;
    }
    if (normalized.contains('بيانات') &&
        (normalized.contains('دخول') || normalized.contains('اعتماد'))) {
      return true;
    }

    return false;
  }

  static bool _isTakenPhrase(String normalized) {
    return normalized.contains('already been taken') ||
        normalized.contains('has already been taken') ||
        normalized.contains('already been used') ||
        normalized.contains('already exists') ||
        normalized.contains('already registered') ||
        normalized.contains('must be unique') ||
        normalized.contains('موجود مسبق') ||
        normalized.contains('مستخدم مسبق') ||
        normalized.contains('مسجل مسبق');
  }

  static bool _isEmailTaken(String normalized) {
    final mentionsEmail =
        normalized.contains('email') || normalized.contains('بريد');
    return mentionsEmail && _isTakenPhrase(normalized);
  }

  static bool _isPhoneTaken(String normalized) {
    final mentionsPhone = normalized.contains('phone') ||
        normalized.contains('هاتف') ||
        normalized.contains('جوال');
    return mentionsPhone && _isTakenPhrase(normalized);
  }
}
