import 'package:mow_events/core/utils/error/api_exceptions.dart';
import 'package:mow_events/core/utils/error/validation_exception.dart';
import 'package:mow_events/features/auth/data/models/register_conflict_type.dart';

/// يستخرج نوع التعارض من استجابة التسجيل (422 أو رسالة الباكند).
class RegisterConflictParser {
  RegisterConflictParser._();

  static RegisterConflictType? fromError(dynamic error) {
    if (error is ValidationException) {
      return _fromValidation(error);
    }
    if (error is ApiException) {
      return _fromMessage(error.message);
    }
    return _fromMessage(error?.toString());
  }

  static RegisterConflictType? fromRegisterResponse(Map<String, dynamic> res) {
    if (res['status'] == true) return null;

    final code = res['code']?.toString().toLowerCase() ?? '';
    if (_isPendingCode(code)) {
      return RegisterConflictType.emailPendingReview;
    }

    final data = res['data'];
    if (data is Map) {
      final status =
          data['register_status']?.toString().toLowerCase() ??
          data['status']?.toString().toLowerCase();
      if (status == 'pending') {
        return RegisterConflictType.emailPendingReview;
      }
    }

    return _fromMessage(res['message']?.toString() ?? res['error']?.toString());
  }

  static RegisterConflictType? _fromValidation(ValidationException error) {
    final fields = error.fieldErrors;
    if (fields != null) {
      for (final entry in fields.entries) {
        final key = entry.key.toLowerCase();
        for (final raw in entry.value) {
          final kind = _fromMessage(raw, field: key);
          if (kind != null) return kind;
        }
      }
    }
    return _fromMessage(error.message);
  }

  static RegisterConflictType? _fromMessage(String? message, {String? field}) {
    if (message == null) return null;
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    if (_isPendingMessage(normalized)) {
      return RegisterConflictType.emailPendingReview;
    }

    final fieldKey = field?.toLowerCase() ?? '';
    final mentionsEmail = fieldKey == 'email' || normalized.contains('email');
    final mentionsPhone = fieldKey == 'phone' || normalized.contains('phone');

    if (mentionsEmail && _isTakenPhrase(normalized)) {
      return RegisterConflictType.emailTaken;
    }
    if (mentionsPhone && _isTakenPhrase(normalized)) {
      return RegisterConflictType.phoneTaken;
    }

    return null;
  }

  static bool _isPendingCode(String code) {
    return code == 'registration_pending' ||
        code == 'account_pending' ||
        code == 'pending_registration' ||
        code == 'email_pending_review';
  }

  static bool _isPendingMessage(String normalized) {
    return normalized.contains('pending') ||
        normalized.contains('under review') ||
        normalized.contains('awaiting approval') ||
        normalized.contains('waiting for approval');
  }

  static bool _isTakenPhrase(String normalized) {
    return normalized.contains('already been taken') ||
        normalized.contains('has already been taken') ||
        normalized.contains('already been used') ||
        normalized.contains('already exists') ||
        normalized.contains('already registered') ||
        normalized.contains('must be unique');
  }
}
