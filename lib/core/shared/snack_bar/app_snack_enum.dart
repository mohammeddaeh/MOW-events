import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

enum AppSnack { success, error, warning, loading }

extension AppSnackExtension on AppSnack {
  Color get color {
    switch (this) {
      case AppSnack.success:
        return Colors.green;
      case AppSnack.error:
        return Colors.red;
      case AppSnack.warning:
        return Colors.orange;
      case AppSnack.loading:
        return Colors.blueGrey;
    }
  }

  IconData get icon {
    switch (this) {
      case AppSnack.success:
        return Icons.check_circle;
      case AppSnack.error:
        return Icons.error;
      case AppSnack.warning:
        return Icons.warning;
      case AppSnack.loading:
        return Icons.hourglass_bottom;
    }
  }

  String get defaultMessage {
    switch (this) {
      case AppSnack.success:
        return AppTexts.theOperationWasSuccessful;
      case AppSnack.error:
        return AppTexts.anUnexpectedErrorOccurred;

      case AppSnack.warning:
        return AppTexts.pleasePayAttention;
      case AppSnack.loading:
        return AppTexts.processing;
    }
  }

  Duration get duration {
    return this == AppSnack.loading
        ? const Duration(seconds: 30)
        : const Duration(seconds: 3);
  }
}
