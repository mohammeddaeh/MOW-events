import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/error/api_message_localizer.dart';
import 'package:mow_events/core/utils/error/app_exciption.dart';
import 'package:mow_events/core/utils/error/validation_exception.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is ValidationException) {
      return _validationErrorMessage(error);
    } else if (error is AppException) {
      return ApiMessageLocalizer.localize(error.message);
    } else if (error is SocketException) {
      return AppTexts.noInternet;
    } else if (error is TimeoutException) {
      return AppTexts.requestTimeout;
    } else if (error is FormatException) {
      return AppTexts.invalidDataFormat;
    } else if (error is HttpException) {
      return AppTexts.serverConnectionFailed;
    } else if (error is Map && error['message'] != null) {
      return ApiMessageLocalizer.localize(error['message'].toString());
    } else if (error.toString().contains('401')) {
      return AppTexts.unauthorized;
    } else {
      return AppTexts.unexpectedError;
    }
  }

  static String _validationErrorMessage(ValidationException error) {
    final fields = error.fieldErrors;
    if (fields == null || fields.isEmpty) {
      return ApiMessageLocalizer.localize(error.message);
    }

    final messages = <String>[];
    for (final entry in fields.entries) {
      for (final raw in entry.value) {
        messages.add(ApiMessageLocalizer.localizeField(entry.key, raw));
      }
    }

    if (messages.isEmpty) {
      return ApiMessageLocalizer.localize(error.message);
    }
    if (messages.length == 1) return messages.first;
    return messages.join('\n');
  }

  static void handle(dynamic error) {
    final message = getErrorMessage(error);
    AppSnackBars.errorSnackBar(title: AppTexts.errorOccurred, message: message);
  }

  static Future<T?> safeCall<T>(
    Future<T> Function() action, {
    bool showSnackbar = true,
  }) async {
    try {
      return await action();
    } catch (error) {
      if (showSnackbar) handle(error);
      return null;
    }
  }
}
