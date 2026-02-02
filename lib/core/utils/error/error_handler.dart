import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/error/app_exciption.dart';
import 'package:mow_events/core/utils/error/validation_exception.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is ValidationException) {
      // رسائل الحقول المفصلة
      if (error.fieldErrors != null && error.fieldErrors!.isNotEmpty) {
        final fieldMessages = error.fieldErrors!.entries
            .map((e) => '${e.key}: ${e.value.join(', ')}')
            .join('\n');
        return '${error.message}\n$fieldMessages';
      }
      return error.message;
    } else if (error is AppException) {
      return error.message;
    } else if (error is SocketException) {
      return AppTexts.noInternet;
    } else if (error is TimeoutException) {
      return AppTexts.requestTimeout;
    } else if (error is FormatException) {
      return AppTexts.invalidDataFormat;
    } else if (error is HttpException) {
      return AppTexts.serverConnectionFailed;
    } else if (error is Map && error['message'] != null) {
      return error['message'];
    } else if (error.toString().contains('401')) {
      return AppTexts.unauthorized;
    } else {
      return AppTexts.unexpectedError;
    }
  }

  static void handle(dynamic error) {
    final message = getErrorMessage(error);
    debugPrint('[ErrorHandler] $error');
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
