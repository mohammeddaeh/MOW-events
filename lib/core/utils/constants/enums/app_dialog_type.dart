import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

enum AppDialogType {
  delete,
  logout,
  warning,
  info,
  imagePreview,
  deleteCategories,
}

extension AppDialogTypeX on AppDialogType {
  String get title {
    switch (this) {
      case AppDialogType.imagePreview:
        return AppTexts.imagePreviewTitle;
      case AppDialogType.delete:
        return AppTexts.deleteTitle;
      case AppDialogType.logout:
        return AppTexts.logOut;
      case AppDialogType.warning:
        return AppTexts.warningTitle;
      case AppDialogType.info:
        return AppTexts.infoTitle;
      case AppDialogType.deleteCategories:
        return AppTexts.deleteCategories;
    }
  }

  Color get lottieColor {
    switch (this) {
      case AppDialogType.imagePreview:
        return Colors.transparent;
      case AppDialogType.delete:
        return Colors.red;
      case AppDialogType.logout:
        return Colors.orange;
      case AppDialogType.warning:
        return Colors.amber;
      case AppDialogType.info:
        return Colors.blue;
      case AppDialogType.deleteCategories:
        return Colors.redAccent;
    }
  }

  String get description {
    switch (this) {
      case AppDialogType.imagePreview:
        return AppTexts.imagePreviewDescription;
      case AppDialogType.delete:
        return AppTexts.deleteDescription;
      case AppDialogType.logout:
        return AppTexts.logoutDescription;
      case AppDialogType.warning:
        return AppTexts.warningDescription;
      case AppDialogType.info:
        return AppTexts.infoDescription;
      case AppDialogType.deleteCategories:
        return AppTexts.deleteCategoriesDescription;
    }
  }

  String get confirmText {
    switch (this) {
      case AppDialogType.imagePreview:
        return AppTexts.close;
      case AppDialogType.delete:
        return AppTexts.delete;
      case AppDialogType.logout:
        return AppTexts.logOut;
      case AppDialogType.warning:
        return AppTexts.tContinue;
      case AppDialogType.info:
        return AppTexts.oK;
      case AppDialogType.deleteCategories:
        return AppTexts.delete;
    }
  }

  Color get confirmColor {
    switch (this) {
      case AppDialogType.imagePreview:
        return Colors.grey;
      case AppDialogType.delete:
        return Colors.red;
      case AppDialogType.deleteCategories:
        return Colors.redAccent;
      case AppDialogType.logout:
        return Colors.orange;
      case AppDialogType.warning:
        return Colors.amber;
      case AppDialogType.info:
        return Colors.blue;
    }
  }

  bool get barrierDismissible {
    switch (this) {
      case AppDialogType.imagePreview:
      case AppDialogType.delete:
      case AppDialogType.logout:
        return false; // لا يغلق خارجياً
      case AppDialogType.warning:
      case AppDialogType.info:
        return true; // يمكن الإغلاق
      case AppDialogType.deleteCategories:
        return false; // لا يغلق خارجياً
    }
  }

  String? get lottieAsset {
    switch (this) {
      case AppDialogType.imagePreview:
        return null;
      case AppDialogType.delete:
        return "assets/images/animated/delete.json";
      case AppDialogType.logout:
        return "assets/images/animated/logout.json";
      case AppDialogType.warning:
        return "assets/images/animated/warning.json";
      case AppDialogType.info:
        return "assets/images/animated/info .json";
      case AppDialogType.deleteCategories:
        return "assets/images/animated/delete.json";
    }
  }

  bool get isDestructive {
    return this == AppDialogType.delete;
  }
}
