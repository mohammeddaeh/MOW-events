import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/widgets/dialoge/app_dialog.dart';
import 'package:mow_events/core/utils/constants/enums/app_dialog_type.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/controller/login_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/profile_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/category/presentation/controller/categories_controller.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/notifications/presentation/controller/notifications_controller.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo;

  var user = Rx<UserModel?>(null);

  var isAuthenticated = false.obs;

  AuthController({required AuthRepository authRepo}) : _authRepo = authRepo;

  void loadFromLocal() {
    final storedUser = AuthService.currentUser;
    if (storedUser != null) {
      user.value = storedUser;
      isAuthenticated.value = true;
    } else {
      user.value = null;
      isAuthenticated.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    final loggedInUser = await _authRepo.login(email, password);

    user.value = loggedInUser;
    isAuthenticated.value = true;

    AppSnackBars.successSnackBar(
      title: AppTexts.success,
      message: AppTexts.loginSuccess,
    );
  }

  Future<void> logout() async {
    if (AuthService.isLoggingOut || AuthService.isSessionExpiredHandling) return;
    AuthService.isLoggingOut = true;

    final context = Get.context;
    if (context == null) {
      await _logoutAndReset(
        callServerLogout: true,
        showSuccessMessage: true,
      );
      return;
    }

    showAppDialog(
      context: context,
      type: AppDialogType.logout,
      onCancel: () {
        AuthService.isLoggingOut = false;
      },
      onConfirm: () {
        _logoutAndReset(
          callServerLogout: true,
          showSuccessMessage: true,
        );
      },
    );
  }

  Future<void> logoutDueToUnauthorized({String? message}) async {
    if (AuthService.isLoggingOut || AuthService.isSessionExpiredHandling) return;

    AuthService.isLoggingOut = true;
    AuthService.isSessionExpiredHandling = true;

    try {
      AppSnackBars.hideSnackBar();
      await _performLogout(
        callServerLogout: false,
        showSuccessMessage: false,
      );
      await Future.delayed(const Duration(milliseconds: 250));
      AppSnackBars.warningSnackBar(
        title: AppTexts.warningTitle,
        message: _normalizeUnauthorizedMessage(message),
        force: true,
      );
    } finally {
      AuthService.isSessionExpiredHandling = false;
      AuthService.isLoggingOut = false;
    }
  }

  Future<void> _logoutAndReset({
    required bool callServerLogout,
    required bool showSuccessMessage,
  }) async {
    try {
      await _performLogout(
        callServerLogout: callServerLogout,
        showSuccessMessage: showSuccessMessage,
      );
    } finally {
      AuthService.isLoggingOut = false;
    }
  }

  Future<void> _performLogout({
    required bool callServerLogout,
    required bool showSuccessMessage,
  }) async {
    if (callServerLogout) {
      try {
        await _authRepo.logout();
      } catch (_) {}
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    await AuthService.logout();
    user.value = null;
    isAuthenticated.value = false;

    _clearUserControllers();
    AppSnackBars.hideSnackBar();

    if (showSuccessMessage) {
      AppSnackBars.successSnackBar(
        title: AppTexts.success,
        message: AppTexts.logoutSuccess,
      );
    }

    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 150));

    if (Get.isRegistered<LoginController>()) {
      Get.delete<LoginController>(force: true);
    }

    Get.offAllNamed(AppRouter.logInScreen);
  }

  void _clearUserControllers() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>(force: true);
      }
      if (Get.isRegistered<CategoriesController>()) {
        Get.delete<CategoriesController>(force: true);
      }
      if (Get.isRegistered<NotificationsController>()) {
        Get.delete<NotificationsController>(force: true);
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.delete<ProfileController>(force: true);
      }
    } catch (_) {}
  }

  String _normalizeUnauthorizedMessage(String? message) {
    final normalized = message?.trim();
    if (normalized == null ||
        normalized.isEmpty ||
        normalized.toLowerCase() == 'unauthenticated.') {
      return AppTexts.unauthorized;
    }
    return normalized;
  }
}
