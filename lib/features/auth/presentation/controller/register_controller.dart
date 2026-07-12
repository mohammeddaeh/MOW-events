import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/core/utils/validator/validator.dart';
import 'package:mow_events/features/auth/data/data_sources/back_end_laravel.dart';
import 'package:mow_events/features/auth/data/models/department.dart';
import 'package:mow_events/features/auth/data/models/register_conflict_type.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/data/models/registration_submission_snapshot.dart';
import 'package:mow_events/features/auth/utils/register_conflict_parser.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/login_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/registration_pending_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/auth/services/registration_approval_service.dart';
import 'package:mow_events/features/notifications/services/notifications_fcm_service.dart';

class RegisterController extends GetxController {
  final registerFormKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final firstNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final emailFocus = FocusNode();
  final phoneFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();

  final AuthController authController = Get.find<AuthController>();
  final BackEndLaravel _backend = Get.find<BackEndLaravel>();

  final RxBool isLoading = false.obs;
  final RxBool isLoadingDepartments = false.obs;
  final RxList<Department> departments = <Department>[].obs;
  final RxnInt selectedDepartmentId = RxnInt();
  final RxBool isManager = false.obs;
  final RxnString departmentsLoadError = RxnString();
  final RxnString rejectionNotice = RxnString();
  final RxBool isResubmitMode = false.obs;

  String? Function(String?) get firstNameValidator => AppValidator.required;
  String? Function(String?) get lastNameValidator => AppValidator.required;
  String? Function(String?) get emailValidator => AppValidator.validateEmail;
  String? Function(String?) get phoneValidator =>
      AppValidator.validatePhoneNumber;
  String? Function(String?) get passwordValidator =>
      AppValidator.validatePassword;

  String? confirmPasswordValidator(String? value) {
    return AppValidator.validateConfirmPassword(
      value,
      passwordController.text.trim(),
    );
  }

  String? departmentValidator(int? value) {
    if (value == null) {
      return AppTexts.departmentRequired;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    _applyResubmitArguments();
    loadDepartments();
  }

  void _applyResubmitArguments() {
    final args = Get.arguments;
    if (args is! Map) return;

    isResubmitMode.value = args['isResubmit'] == true;

    final snapshotRaw = args['snapshot'];
    if (snapshotRaw is! Map) return;

    final snapshot = RegistrationSubmissionSnapshot.fromJson(
      Map<String, dynamic>.from(snapshotRaw),
    );

    firstNameController.text = snapshot.firstName;
    lastNameController.text = snapshot.lastName;
    emailController.text = snapshot.email;
    phoneController.text = snapshot.phone;
    selectedDepartmentId.value = snapshot.departmentId;
    isManager.value = snapshot.isManager;

    final reason = args['rejectionReason']?.toString().trim();
    if (reason != null && reason.isNotEmpty) {
      rejectionNotice.value = reason;
    }
  }

  Future<void> loadDepartments({bool showSnackBarOnError = false}) async {
    if (!InternetGuard.ensureOnline()) {
      departmentsLoadError.value = AppTexts.noInternetConnection;
      return;
    }

    departmentsLoadError.value = null;
    isLoadingDepartments.value = true;

    try {
      final list = await _backend.fetchDepartmentsForRegistration();
      departments.assignAll(list);

      if (list.isEmpty) {
        departmentsLoadError.value = AppTexts.noDepartmentsAvailable;
      }
    } catch (error) {
      departments.clear();
      selectedDepartmentId.value = null;
      final message = ErrorHandler.getErrorMessage(error);
      departmentsLoadError.value = message;

      if (showSnackBarOnError) {
        AppSnackBars.errorSnackBar(
          title: AppTexts.warningTitle,
          message: message,
        );
      }
    } finally {
      isLoadingDepartments.value = false;
    }
  }

  Future<void> onDepartmentFieldTap() async {
    if (isLoadingDepartments.value) return;

    final needsReload =
        departments.isEmpty || departmentsLoadError.value != null;
    if (!needsReload) return;

    await loadDepartments(showSnackBarOnError: true);
  }

  void goToLogin() {
    Get.offAllNamed(AppRouter.logInScreen);
  }

  void _openLoginAfterPendingEmailConflict() {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    AppSnackBars.warningSnackBar(
      title: AppTexts.loginRegistrationPendingTitle,
      message:
          '${AppTexts.emailPendingAdminReview}\n${AppTexts.emailPendingAdminReviewAction}',
    );
    Get.offAllNamed(AppRouter.logInScreen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<LoginController>()) return;
      Get.find<LoginController>().prefillAfterRegistration(
        email: email,
        phone: phone,
      );
    });
  }

  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) return;
    if (!InternetGuard.ensureOnline()) return;

    if (departments.isEmpty) {
      final message =
          departmentsLoadError.value ?? AppTexts.failedToLoadDepartments;
      AppSnackBars.errorSnackBar(
        title: AppTexts.warningTitle,
        message: message,
      );
      await loadDepartments(showSnackBarOnError: true);
      return;
    }

    final departmentId = selectedDepartmentId.value;
    if (departmentId == null) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.warningTitle,
        message: AppTexts.departmentRequired,
      );
      return;
    }

    if (isResubmitMode.value && AuthService.token.isEmpty) {
      AppSnackBars.warningSnackBar(
        title: AppTexts.warningTitle,
        message: AppTexts.registrationResubmitRequiresLogin,
      );
      goToLogin();
      return;
    }

    Get.focusScope?.unfocus();
    isLoading.value = true;

    try {
      final normalizedPhone = AppValidator.normalizePhoneNumber(
        phoneController.text,
      );

      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      late final UserModel submittedUser;

      if (isResubmitMode.value) {
        submittedUser = await authController.updateRegistration(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: normalizedPhone,
          password: password,
          departmentId: departmentId,
          isManager: isManager.value,
        );
      } else {
        submittedUser = await authController.register(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: normalizedPhone,
          password: password,
          departmentId: departmentId,
          isManager: isManager.value,
        );
      }

      rejectionNotice.value = null;

      final pendingUser = await RegistrationApprovalService.applyPendingAfterResubmit(
        submittedUser,
      );
      authController.user.value = pendingUser;
      await AuthService.saveUser(pendingUser.toJson());

      NotificationsFcmService.ensureController();
      await NotificationsFcmService.preparePendingRegistration(pendingUser);
      await NotificationsFcmService.logDeviceToken('إنشاء حساب');

      if (Get.isRegistered<RegistrationPendingController>()) {
        Get.delete<RegistrationPendingController>(force: true);
      }
      Get.offAllNamed(AppRouter.registrationPendingScreen);
    } catch (error) {
      final conflict = RegisterConflictParser.fromError(error);
      if (conflict == RegisterConflictType.emailPendingReview) {
        _openLoginAfterPendingEmailConflict();
        return;
      }
      ErrorHandler.handle(error);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.onClose();
  }
}
