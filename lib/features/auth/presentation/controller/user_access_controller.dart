import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/domin/repositories/auth_repository.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/notifications/fcm/fcm_token_sync_guard.dart';
import 'package:mow_events/features/auth/services/registration_approval_service.dart';

enum UserAccessState { idle, requiresRefresh, checking, inactive, active }

enum StartupAccessResult { unauthenticated, active, inactive, requiresRefresh }

class UserAccessController extends GetxController with WidgetsBindingObserver {
  final AuthRepository _authRepo;

  UserAccessController({required AuthRepository authRepo})
    : _authRepo = authRepo;

  final AuthController authController = Get.find<AuthController>();
  final NetworkManager networkManager = Get.find<NetworkManager>();

  final Rx<UserAccessState> state = UserAccessState.idle.obs;
  final RxString currentRoute = AppRouter.splash.obs;

  Worker? _authWorker;
  Worker? _networkWorker;
  Timer? _periodicRefreshTimer;

  static const Duration _periodicRefreshInterval = Duration(minutes: 2);
  static const Set<String> _publicRoutes = {
    '',
    AppRouter.splash,
    AppRouter.logInScreen,
    AppRouter.registerScreen,
    AppRouter.registrationPendingScreen,
    AppRouter.forgotPassword,
    AppRouter.verifyCode,
    AppRouter.resetPassword,
    AppRouter.alarmRinging,
  };

  bool get isAuthenticated => authController.isAuthenticated.value;

  /// السماح بالاستخدام من البيانات المحلية ما لم يُؤكَّد إلغاء التفعيل.
  bool get canUseProtectedFeatures =>
      isAuthenticated &&
      state.value != UserAccessState.inactive &&
      state.value != UserAccessState.idle;

  /// الحجب فقط عند إلغاء تفعيل الحساب (ليس عند انقطاع الإنترنت أو فشل مزامنة الحالة).
  bool get shouldBlockProtectedRoutes =>
      isAuthenticated && state.value == UserAccessState.inactive;

  bool get isOnProtectedRoute => !_publicRoutes.contains(currentRoute.value);

  bool get isChecking => state.value == UserAccessState.checking;

  String get actionLabel =>
      isChecking ? AppTexts.processing : AppTexts.refreshStatus;

  String get title {
    switch (state.value) {
      case UserAccessState.inactive:
        return AppTexts.accountDeactivated;
      case UserAccessState.checking:
      case UserAccessState.requiresRefresh:
        return AppTexts.accessRefreshTitle;
      case UserAccessState.idle:
      case UserAccessState.active:
        return '';
    }
  }

  String get description {
    switch (state.value) {
      case UserAccessState.requiresRefresh:
        return AppTexts.accessRefreshDescription;
      case UserAccessState.checking:
        return AppTexts.accessCheckingDescription;
      case UserAccessState.inactive:
        return AppTexts.accountDeactivatedDescription;
      case UserAccessState.idle:
      case UserAccessState.active:
        return '';
    }
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    _authWorker = ever<UserModel?>(authController.user, _handleUserChanged);
    _networkWorker = ever<bool>(
      networkManager.isOnline,
      _handleConnectivityChanged,
    );

    _handleUserChanged(authController.user.value);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _authWorker?.dispose();
    _networkWorker?.dispose();
    _stopPeriodicRefresh();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshInBackground();
    }
  }

  Future<StartupAccessResult> resolveStartupAccess() async {
    final localUser = authController.user.value ?? AuthService.currentUser;

    if (RegistrationApprovalService.shouldHoldRegistrationApproval(localUser)) {
      return StartupAccessResult.unauthenticated;
    }

    if (!isAuthenticated || localUser == null) {
      _setIdleState();
      return StartupAccessResult.unauthenticated;
    }

    if (!networkManager.isOnline.value) {
      if (!localUser.isActive) {
        state.value = UserAccessState.inactive;
        AuthService.isInactiveAccountHandling = true;
        return StartupAccessResult.inactive;
      }

      state.value = UserAccessState.active;
      AuthService.isInactiveAccountHandling = false;
      return StartupAccessResult.active;
    }

    final refreshed = await _refreshUserStatus(
      allowBackgroundFailure: false,
      logServerUser: true,
      source: 'startup',
    );

    if (!isAuthenticated) {
      return StartupAccessResult.unauthenticated;
    }

    if (state.value == UserAccessState.inactive) {
      return StartupAccessResult.inactive;
    }

    return refreshed
        ? StartupAccessResult.active
        : StartupAccessResult.requiresRefresh;
  }

  Future<bool> refreshStatus() async {
    if (!InternetGuard.ensureOnline()) return false;

    return _refreshUserStatus(
      allowBackgroundFailure: false,
      logServerUser: false,
      source: 'manual',
    );
  }

  /// تسجيل خروج من شاشة الحساب غير المفعّل للانتقال إلى تسجيل الدخول.
  Future<void> logoutToLoginScreen() async {
    if (AuthService.isLoggingOut || AuthService.isSessionExpiredHandling) {
      return;
    }

    AuthService.isLoggingOut = true;
    AuthService.isInactiveAccountHandling = false;

    try {
      AppSnackBars.hideSnackBar();
      try {
        await _authRepo.logout(
          deviceToken: await FcmTokenSyncGuard.currentDeviceToken(),
        );
      } catch (_) {}
      await FcmTokenSyncGuard.clearDeviceToken();

      await AuthService.logout();
      authController.user.value = null;
      authController.isAuthenticated.value = false;
      _setIdleState();
      Get.offAllNamed(AppRouter.logInScreen);
    } finally {
      AuthService.isLoggingOut = false;
    }
  }

  Future<void> preparePostLoginAccess() async {
    if (!isAuthenticated) {
      _setIdleState();
      return;
    }

    if (RegistrationApprovalService.shouldHoldRegistrationApproval(
      authController.user.value ?? AuthService.currentUser,
    )) {
      return;
    }

    final localUser = authController.user.value ?? AuthService.currentUser;
    if (localUser == null) {
      _setIdleState();
      return;
    }

    if (!networkManager.isOnline.value) {
      if (!localUser.isActive) {
        await markAccountInactive(source: 'login-local');
      } else {
        state.value = UserAccessState.active;
        AuthService.isInactiveAccountHandling = false;
      }
      return;
    }

    final refreshed = await _refreshUserStatus(
      allowBackgroundFailure: false,
      logServerUser: true,
      source: 'login',
    );

    if (!refreshed && state.value == UserAccessState.idle) {
      requireRefreshBeforeUse(source: 'login-fallback');
    }
  }

  void updateCurrentRoute(String? route) {
    currentRoute.value = route ?? '';
  }

  void requireRefreshBeforeUse({String source = 'login'}) {
    if (!isAuthenticated) return;

    AuthService.isInactiveAccountHandling = false;
    AppSnackBars.hideSnackBar();
    _stopPeriodicRefresh();
    state.value = UserAccessState.requiresRefresh;
  }

  Future<bool> _refreshUserStatus({
    required bool allowBackgroundFailure,
    required bool logServerUser,
    required String source,
  }) async {
    if (!isAuthenticated) {
      _setIdleState();
      return false;
    }

    if (RegistrationApprovalService.shouldHoldRegistrationApproval(
      authController.user.value ?? AuthService.currentUser,
    )) {
      return false;
    }

    if (state.value == UserAccessState.checking) return false;

    if (!InternetGuard.ensureOnline(showMessage: !allowBackgroundFailure)) {
      return false;
    }

    final previousState = state.value;
    final shouldShowCheckingState =
        !(allowBackgroundFailure && previousState == UserAccessState.active);
    if (shouldShowCheckingState) {
      state.value = UserAccessState.checking;
    }

    try {
      final updatedUser = await _authRepo.getProfile();
      if (logServerUser) {}
      await _applyUpdatedUser(updatedUser);

      if (!updatedUser.isActive) {
        await markAccountInactive(source: source);
        return false;
      }

      state.value = UserAccessState.active;
      _startPeriodicRefresh();
      return true;
    } catch (error) {
      if (_isInactiveAccountError(error)) {
        await markAccountInactive(source: source, error: error);
        return false;
      }

      if (allowBackgroundFailure && previousState == UserAccessState.active) {
        state.value = UserAccessState.active;
        return false;
      }

      final cachedUser = authController.user.value ?? AuthService.currentUser;
      state.value = cachedUser?.isActive == false
          ? UserAccessState.inactive
          : UserAccessState.requiresRefresh;
      AuthService.isInactiveAccountHandling =
          state.value == UserAccessState.inactive;
      return false;
    }
  }

  void _handleUserChanged(UserModel? user) {
    if (user == null || !isAuthenticated) {
      _setIdleState();
      return;
    }

    if (RegistrationApprovalService.shouldHoldRegistrationApproval(user)) {
      return;
    }

    if (!user.isActive) {
      AuthService.isInactiveAccountHandling = true;
      state.value = UserAccessState.inactive;
      _stopPeriodicRefresh();
      return;
    }

    AuthService.isInactiveAccountHandling = false;
    if (state.value == UserAccessState.idle) {
      state.value = UserAccessState.active;
      if (networkManager.isOnline.value) {
        _refreshInBackground();
      }
    }
  }

  void _handleConnectivityChanged(bool isOnline) {
    if (!isOnline) return;
    _refreshInBackground();
  }

  Future<void> _refreshInBackground() async {
    if (RegistrationApprovalService.shouldHoldRegistrationApproval(
      authController.user.value ?? AuthService.currentUser,
    )) {
      return;
    }
    if (!canUseProtectedFeatures || !networkManager.isOnline.value) return;

    await _refreshUserStatus(
      allowBackgroundFailure: true,
      logServerUser: false,
      source: 'background',
    );
  }

  Future<void> _applyUpdatedUser(UserModel updatedUser) async {
    AuthService.isInactiveAccountHandling = false;
    authController.user.value = updatedUser;
    authController.isAuthenticated.value = true;
    await AuthService.saveUser(updatedUser.toJson());
  }

  Future<void> markAccountInactive({
    required String source,
    dynamic error,
  }) async {
    final message = error == null ? null : ErrorHandler.getErrorMessage(error);
    if (message != null && message.isNotEmpty) {}

    AuthService.isInactiveAccountHandling = true;
    AppSnackBars.hideSnackBar();
    state.value = UserAccessState.inactive;
    _stopPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(_periodicRefreshInterval, (_) {
      _refreshInBackground();
    });
  }

  void _stopPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
  }

  void _setIdleState() {
    AuthService.isInactiveAccountHandling = false;
    state.value = UserAccessState.idle;
    _stopPeriodicRefresh();
  }

  bool _isInactiveAccountError(dynamic error) {
    final message = ErrorHandler.getErrorMessage(error);
    return isInactiveAccountMessage(message);
  }

  static bool isInactiveAccountMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return false;

    return normalized.contains('not active') ||
        normalized.contains('inactive') ||
        normalized.contains('account inactive') ||
        normalized.contains('account is inactive') ||
        normalized.contains('does not account active') ||
        normalized.contains('account active') ||
        normalized.contains('غير مفعل') ||
        normalized.contains('غير مفعّل') ||
        normalized.contains('تم إيقاف') ||
        normalized.contains('تم ايقاف');
  }
}
