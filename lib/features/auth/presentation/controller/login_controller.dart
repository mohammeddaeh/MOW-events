import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/utils/error/api_message_localizer.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/utils/local_storage/AppStorage/app_storage.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/validator.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/user_access_controller.dart';
import 'package:mow_events/features/auth/services/registration_approval_service.dart';
import 'package:mow_events/features/notifications/services/notifications_fcm_service.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();
  RxBool rememberMe = false.obs;
  RxBool isLoading = false.obs;
  final isPhoneLogin = false.obs;

  final emailFocus = FocusNode();
  final phoneFocus = FocusNode();
  final passwordFocus = FocusNode();

  final appStorage = AppStorage();
  final AuthController authController = Get.find<AuthController>();
  final UserAccessController accessController =
      Get.find<UserAccessController>();

  String? Function(String?) get emailValidator => AppValidator.validateEmail;
  String? Function(String?) get phoneValidator =>
      AppValidator.validateSyrianPhoneNumber;
  String? Function(String?) get passwordValidator =>
      AppValidator.validatePassword;

  TextEditingController get identifierController =>
      isPhoneLogin.value ? phoneController : emailController;

  FocusNode get identifierFocus => isPhoneLogin.value ? phoneFocus : emailFocus;

  String get identifierLabel =>
      isPhoneLogin.value ? AppTexts.phoneNumber : AppTexts.email;

  String get identifierHint => isPhoneLogin.value
      ? AppTexts.syrianPhonePlaceholder
      : AppTexts.emailPlaceholder;

  String get switchLoginMethodLabel =>
      isPhoneLogin.value ? AppTexts.logInEmail : AppTexts.logInPhone;

  @override
  void onInit() {
    super.onInit();
    rememberMe.value = false;
  }

  @override
  void onReady() {
    super.onReady();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    rememberMe.value = false;
  }

  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    passwordFocus.dispose();
    super.onClose();
  }

  void setPhoneLogin(bool value) {
    if (isPhoneLogin.value == value) return;

    isPhoneLogin.value = value;
    loginFormKey.currentState?.reset();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (value) {
        phoneFocus.requestFocus();
      } else {
        emailFocus.requestFocus();
      }
    });
  }

  void toggleLoginMethod() => setPhoneLogin(!isPhoneLogin.value);

  String get normalizedIdentifier => isPhoneLogin.value
      ? AppValidator.normalizePhoneNumber(phoneController.text)
      : emailController.text.trim();

  void openRegister() {
    Get.toNamed(AppRouter.registerScreen);
  }

  void prefillAfterRegistration({
    required String email,
    required String phone,
  }) {
    setPhoneLogin(false);
    emailController.text = email;
    phoneController.text = phone;
    passwordController.clear();
  }

  void login() async {
    if (!loginFormKey.currentState!.validate()) return;
    if (!InternetGuard.ensureOnline()) return;

    Get.focusScope?.unfocus();
    isLoading.value = true;

    try {
      final loggedInUser = await ApiMessageLocalizer.runWithPhoneLoginMessage(
        isPhoneLogin.value,
        () => ErrorHandler.safeCall(
          () => authController.login(
            identifier: normalizedIdentifier,
            password: passwordController.text.trim(),
          ),
        ),
      );
      await appStorage.setRememberMe(rememberMe.value);

      if (loggedInUser == null) return;

      await RegistrationApprovalService.syncFromUser(loggedInUser);
      await RegistrationApprovalService.reconcileLocalStateWithUser(
        loggedInUser,
      );

      if (RegistrationApprovalService.shouldHoldRegistrationApproval(
        loggedInUser,
      )) {
        NotificationsFcmService.ensureController();
        await NotificationsFcmService.preparePendingRegistration(loggedInUser);
        await NotificationsFcmService.logDeviceToken('تسجيل الدخول');

        final accountContact = loggedInUser.email.trim().isNotEmpty
            ? loggedInUser.email.trim()
            : (loggedInUser.phone.trim().isNotEmpty
                  ? loggedInUser.phone.trim()
                  : normalizedIdentifier);

        final reg = loggedInUser.registrationData;
        final isRejected = reg.isRejected;

        AppSnackBars.navigateAfterClosingSnackbars(() {
          Get.offAllNamed(AppRouter.registrationPendingScreen);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isRejected) {
              AppSnackBars.warningSnackBar(
                title: AppTexts.loginRegistrationRejectedTitle,
                message: AppTexts.loginRegistrationRejectedMessage.trParams({
                  'email': accountContact,
                }),
              );
            } else {
              AppSnackBars.successSnackBar(
                title: AppTexts.loginRegistrationPendingTitle,
                message: AppTexts.loginRegistrationPendingMessage.trParams({
                  'email': accountContact,
                }),
              );
            }
          });
        });
        return;
      }

      AppSnackBars.successSnackBar(
        title: AppTexts.success,
        message: AppTexts.loginSuccess,
      );

      await RegistrationApprovalService.reconcileLocalStateWithUser(
        loggedInUser,
      );

      NotificationsFcmService.ensureController();
      await NotificationsFcmService.syncPushTokenWithRetries(
        debugContext: 'loginActive',
      );
      await NotificationsFcmService.logDeviceToken('تسجيل الدخول');

      await accessController.preparePostLoginAccess();
      Get.offAllNamed(AppRouter.homeScreen);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleRememberMe(bool value) {
    rememberMe.value = value;
  }
}
