import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/registration_submission_snapshot.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/data/models/user_registration_data.dart';
import 'package:mow_events/features/auth/domin/entities/registration_approval_status.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/register_controller.dart';
import 'package:mow_events/features/auth/presentation/controller/user_access_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/auth/services/registration_approval_service.dart';
import 'package:mow_events/features/notifications/services/notifications_fcm_service.dart';

/// ينتظر قرار الباكند عبر Push، مع تحديث احتياطي من الحالة المحفوظة أو الملف.
class RegistrationPendingController extends GetxController
    with WidgetsBindingObserver {
  final AuthController authController = Get.find<AuthController>();
  final AuthRepository authRepo = Get.find<AuthRepository>();
  final UserAccessController accessController =
      Get.find<UserAccessController>();

  final RxBool isRefreshing = false.obs;
  final RxBool isCompletingApproval = false.obs;
  final Rx<RegistrationApprovalStatus> approvalStatus =
      RegistrationApprovalStatus.pending.obs;
  final RxnString rejectionReason = RxnString();
  final Rxn<RegistrationSubmissionSnapshot> submission =
      Rxn<RegistrationSubmissionSnapshot>();
  final Rxn<UserModel> user = Rxn<UserModel>();

  bool get isRejected =>
      approvalStatus.value == RegistrationApprovalStatus.rejected;

  bool get isPending =>
      approvalStatus.value == RegistrationApprovalStatus.pending;

  String? get displayRejectionReason {
    return UserRegistrationData.normalizeReasonText(rejectionReason.value);
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    syncFromStorage();
    user.value = authController.user.value ?? AuthService.currentUser;
  }

  @override
  void onReady() {
    super.onReady();
    _syncPendingStateFromUser();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkStatusOnEntry());
    });
  }

  /// فحص تلقائي وصامت لحالة الطلب الفعلية عند دخول الشاشة (بدون loader أو
  /// رسائل خطأ) — يصحح أي حالة محلية قديمة (مثال: تم رفض الطلب أو قبوله
  /// أثناء إغلاق التطبيق) دون انتظار ضغط المستخدم على زر التحديث.
  Future<void> _checkStatusOnEntry() async {
    await NotificationsFcmService.processPendingBackgroundAction();
    await refreshSubmittedData(showErrors: false);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(NotificationsFcmService.processPendingBackgroundAction());
      unawaited(_applyStatusFromLocalUser(showFeedback: false));
    }
  }

  void _syncPendingStateFromUser() {
    final current = authController.user.value ?? AuthService.currentUser;
    if (current == null) return;

    final reg = current.registrationData;
    if (reg.isPending &&
        approvalStatus.value == RegistrationApprovalStatus.rejected) {
      applyPendingState();
    }
  }

  void syncFromStorage() {
    approvalStatus.value = RegistrationApprovalService.status;
    rejectionReason.value = RegistrationApprovalService.rejectionReason;
    submission.value = RegistrationApprovalService.snapshot;
    user.value = authController.user.value ?? AuthService.currentUser;
  }

  /// يعيد ضبط الواجهة إلى «قيد المراجعة» (بعد إعادة إرسال الطلب).
  void applyPendingState() {
    approvalStatus.value = RegistrationApprovalStatus.pending;
    rejectionReason.value = null;
    submission.value = RegistrationApprovalService.snapshot;
    user.value = authController.user.value ?? AuthService.currentUser;
  }

  /// إعادة فحص حالة الطلب — الملف الشخصي (`register_status`) هو المصدر الوحيد
  /// للحقيقة. لا نثق بقائمة إشعارات الخادم هنا لأنها سجلّ تاريخي: بعد إعادة
  /// تقديم الطلب يبقى آخر إشعار رفض كما هو رغم أن الحالة الفعلية أصبحت pending.
  Future<void> refreshSubmittedData({required bool showErrors}) async {
    if (!InternetGuard.ensureOnline(showMessage: showErrors)) {
      return;
    }
    if (isRefreshing.value) return;

    isRefreshing.value = true;
    try {
      await NotificationsFcmService.processPendingBackgroundAction();

      try {
        final profile = await authRepo.getProfile();
        await _applyStatusFromUser(
          profile,
          showFeedback: showErrors,
          usedLocalFallback: false,
        );
        return;
      } catch (_) {}

      final local = authController.user.value ?? AuthService.currentUser;
      if (local != null) {
        await _applyStatusFromUser(
          local,
          showFeedback: showErrors,
          usedLocalFallback: true,
        );
        return;
      }

      if (showErrors) {
        AppSnackBars.warningSnackBar(
          title: AppTexts.warningTitle,
          message: AppTexts.registrationRecheckFailed,
        );
      }
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _applyStatusFromLocalUser({required bool showFeedback}) async {
    final local = authController.user.value ?? AuthService.currentUser;
    if (local == null) return;
    await _applyStatusFromUser(
      local,
      showFeedback: showFeedback,
      usedLocalFallback: true,
    );
  }

  Future<void> _applyStatusFromUser(
    UserModel refreshedUser, {
    required bool showFeedback,
    bool usedLocalFallback = false,
  }) async {
    authController.user.value = refreshedUser;
    user.value = refreshedUser;
    await AuthService.saveUser(refreshedUser.toJson());
    await RegistrationApprovalService.syncFromUser(refreshedUser);
    syncFromStorage();

    final reg = refreshedUser.registrationData;

    if (reg.isApproved || !refreshedUser.requiresRegistrationApproval) {
      await completeRegistrationApproval(showLoader: true);
      return;
    }

    if (reg.isRejected) {
      final reason =
          reg.displayRejectionReason ??
          displayRejectionReason ??
          AppTexts.registrationRejectedDefaultReason;
      await applyRejection(reason, showSnackBar: showFeedback);
      return;
    }

    if (!showFeedback || !reg.isPending) return;

    AppSnackBars.successSnackBar(
      title: AppTexts.registrationPendingBadge,
      message: AppTexts.registrationStillUnderReview,
    );
  }

  Future<void> applyRejection(
    String reason, {
    bool showSnackBar = false,
  }) async {
    final cleanReason =
        UserRegistrationData.normalizeReasonText(reason) ?? reason.trim();
    final effectiveReason = cleanReason.isEmpty
        ? AppTexts.registrationRejectedDefaultReason
        : cleanReason;

    approvalStatus.value = RegistrationApprovalStatus.rejected;
    rejectionReason.value = effectiveReason;

    await RegistrationApprovalService.markRejected(effectiveReason);

    final current = user.value ?? authController.user.value;
    if (current != null) {
      final updated = current.copyWith(
        registrationData: UserRegistrationData(
          registerStatus: 'rejected',
          registerDescriptionStatus: effectiveReason,
        ),
      );
      user.value = updated;
      authController.user.value = updated;
      await AuthService.saveUser(updated.toJson());
    }

    syncFromStorage();

    if (showSnackBar &&
        Get.currentRoute != AppRouter.registrationPendingScreen) {
      AppSnackBars.errorSnackBar(
        title: AppTexts.registrationRejectedTitle,
        message:
            displayRejectionReason ??
            AppTexts.registrationRejectedDefaultReason,
      );
    }
  }

  Future<void> completeRegistrationApproval({bool showLoader = false}) async {
    if (isCompletingApproval.value) return;

    if (showLoader) {
      isCompletingApproval.value = true;
    }

    try {
      try {
        final refreshedUser = await authRepo.getProfile();
        authController.user.value = refreshedUser;
        user.value = refreshedUser;
        await AuthService.saveUser(refreshedUser.toJson());
      } catch (_) {}

      await RegistrationApprovalService.clear();
      await accessController.preparePostLoginAccess();

      AppSnackBars.successSnackBar(
        title: AppTexts.success,
        message: AppTexts.registrationApprovedMessage,
      );

      Get.offAllNamed(AppRouter.homeScreen);
    } finally {
      isCompletingApproval.value = false;
    }
  }

  Future<void> goToLogin() async {
    await AuthService.logout();
    authController.user.value = null;
    authController.isAuthenticated.value = false;
    Get.offAllNamed(AppRouter.logInScreen);
  }

  void editAndResubmit() {
    final snapshot = submission.value;
    final args = <String, dynamic>{'isResubmit': true};
    final reason = displayRejectionReason;
    if (reason != null && reason.isNotEmpty) {
      args['rejectionReason'] = reason;
    }
    if (snapshot != null) {
      args['snapshot'] = snapshot.toJson();
    }

    if (Get.isRegistered<RegisterController>()) {
      Get.delete<RegisterController>(force: true);
    }
    Get.offAllNamed(AppRouter.registerScreen, arguments: args);
  }
}
