import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/widgets/dialoge/app_dialog.dart';
import 'package:mow_events/core/utils/constants/enums/app_dialog_type.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/popups_loaders/app_loader.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/controller/login_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/profile_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mow_events/features/notifications/fcm/fcm_token_sync_guard.dart';
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

  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required int departmentId,
    required bool isManager,
  }) async {
    final registeredUser = await _authRepo.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
      departmentId: departmentId,
      isManager: isManager,
    );

    user.value = registeredUser;
    isAuthenticated.value = true;

    AppSnackBars.successSnackBar(
      title: AppTexts.success,
      message: AppTexts.registrationSubmittedMessage,
    );

    return registeredUser;
  }

  Future<UserModel> updateRegistration({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required int departmentId,
    required bool isManager,
  }) async {
    final updatedUser = await _authRepo.updateRegistration(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
      departmentId: departmentId,
      isManager: isManager,
    );

    user.value = updatedUser;
    isAuthenticated.value = true;

    AppSnackBars.successSnackBar(
      title: AppTexts.success,
      message: AppTexts.registrationResubmittedMessage,
    );

    return updatedUser;
  }

  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final loggedInUser = await _authRepo.login(
      identifier: identifier,
      password: password,
    );

    user.value = loggedInUser;
    isAuthenticated.value = true;

    return loggedInUser;
  }

  Future<void> logout() async {
    if (AuthService.isLoggingOut || AuthService.isSessionExpiredHandling) {
      return;
    }
    AuthService.isLoggingOut = true;

    final context = Get.context;
    if (context == null) {
      await _logoutWithLoader(
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
        _logoutWithLoader(callServerLogout: true, showSuccessMessage: true);
      },
    );
  }

  Future<void> logoutDueToUnauthorized({String? message}) async {
    if (AuthService.isLoggingOut || AuthService.isSessionExpiredHandling) {
      return;
    }

    AuthService.isLoggingOut = true;
    AuthService.isSessionExpiredHandling = true;

    AppLoader.show(message: AppTexts.loggingOut);
    try {
      AppSnackBars.hideSnackBar();
      await _performLogout(callServerLogout: false, showSuccessMessage: false);
      await Future.delayed(const Duration(milliseconds: 250));
      AppSnackBars.warningSnackBar(
        title: AppTexts.warningTitle,
        message: _normalizeUnauthorizedMessage(message),
        force: true,
      );
    } finally {
      AppLoader.hide();
      AuthService.isSessionExpiredHandling = false;
      AuthService.isLoggingOut = false;
    }
  }

  Future<void> _logoutWithLoader({
    required bool callServerLogout,
    required bool showSuccessMessage,
  }) async {
    AppLoader.show(message: AppTexts.loggingOut);
    try {
      await _performLogout(
        callServerLogout: callServerLogout,
        showSuccessMessage: showSuccessMessage,
      );
    } finally {
      AppLoader.hide();
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

    FcmTokenSyncGuard.reset();

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
