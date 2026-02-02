import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/dialoge/app_dialog.dart';
import 'package:mow_events/core/utils/constants/enums/app_dialog_type.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/binding/log_in_binding.dart';
import 'package:mow_events/features/auth/presentation/controller/login_controller.dart';
import 'package:mow_events/features/auth/presentation/screen/log_in_screen.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';

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
    if (!InternetGuard.ensureOnline()) {
      return;
    }
    if (AuthService.isLoggingOut) return;
    AuthService.isLoggingOut = true;

    showAppDialog(
      context: Get.context!,
      type: AppDialogType.logout,
      onCancel: () {
        AuthService.isLoggingOut = false;
      },
      onConfirm: () async {
        Get.back();

        try {
          await _authRepo.logout();
        } catch (e) {
          ErrorHandler.handle(e);
        }

        await AuthService.logout();
        user.value = null;
        isAuthenticated.value = false;

        AppSnackBars.successSnackBar(
          title: AppTexts.success,
          message: AppTexts.logoutSuccess,
        );

        FocusManager.instance.primaryFocus?.unfocus();
        await Future.delayed(const Duration(milliseconds: 100));
        if (Get.isRegistered<LoginController>()) {
          Get.delete<LoginController>(force: true);
        }

        Get.offAll(() => LogInScreen(), binding: LogInBinding());

        AuthService.isLoggingOut = false;
      },
    );
  }
}
