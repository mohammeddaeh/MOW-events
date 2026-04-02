import 'package:get/get.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class AppValidator {
  static String normalizePhoneNumber(String? value) {
    return value?.replaceAll(RegExp(r'\D'), '') ?? '';
  }

  static String? validatePhoneNumber(String? value) {
    final rawValue = value?.trim() ?? '';
    final normalized = normalizePhoneNumber(rawValue);

    if (rawValue.isEmpty) return AppTexts.fieldIsRequired;
    if (!RegExp(r'^\d+$').hasMatch(rawValue)) {
      return AppTexts.invalidNumber;
    }
    if (!RegExp(r'^0\d{9}$').hasMatch(normalized)) {
      return AppTexts.invalidNumber;
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return AppTexts.emailIsRequired;
    if (!GetUtils.isEmail(value)) return AppTexts.invalidEmail;
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppTexts.passwordRequired;
    if (value.length < 6) return AppTexts.thePasswordIsTooShort;

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return AppTexts.thePasswordMustContainAtLeastOneCapitalLetter;
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return AppTexts.thePasswordMustContainAtLeastOneLowercaseLetter;
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return AppTexts.thePasswordMustContainAtLeastOneNumber;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return AppTexts.thePasswordMustContainAtLeastOneCharacter;
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppTexts.passwordConfirmationIsRequired;
    }
    if (value != password) return AppTexts.thePasswordAndConfirmationDoNotMatch;
    return null;
  }

  static String? validateOtpCode(String? value, {int length = 5}) {
    if (value == null || value.isEmpty) return AppTexts.codeIsRequired;
    if (value.length != length) {
      return AppTexts.otpLengthError.trParams({'length': '$length'});
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return AppTexts.theCodeMustContainOnlyNumbers;
    }
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppTexts.fieldIsRequired;
    }
    return null;
  }
}
