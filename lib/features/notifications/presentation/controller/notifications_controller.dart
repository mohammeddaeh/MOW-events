import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/alarm/alarm_pending_action_store.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/error/api_exceptions.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/presentation/controller/user_access_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/auth/services/registration_approval_service.dart';
import 'package:mow_events/features/notifications/handlers/registration_approval_notification_handler.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';
import 'package:mow_events/features/notifications/data/models/notification_model.dart';
import 'package:mow_events/features/notifications/domin/repositories/notifications_repository.dart';
import 'package:mow_events/features/notifications/fcm/fcm_token_sync_guard.dart';
import 'package:mow_events/features/notifications/utils/registration_notification_display.dart';

class NotificationsController extends GetxController {
  final NotificationsRepository repository;

  NotificationsController({required this.repository});

  static const String _localNotificationPrefix = 'fcm_local_';

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreNotifications = true.obs;
  final Rx<String?> highlightNotificationId = Rx<String?>(null);
  final Rx<int?> autoOpenEventId = Rx<int?>(null);
  final Rx<String?> syncError = Rx<String?>(null);
  final UserAccessController accessController = Get.find();

  int _page = 1;
  bool _hasMore = true;
  Worker? _accessWorker;
  Future<void>? _fetchTask;
  Future<void>? _messagingInitFuture;
  Future<bool>? _tokenSyncInFlight;
  final Set<String> _pendingLocalNotificationKeys = <String>{};

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  HomeController? get _homeControllerOrNull {
    if (!Get.isRegistered<HomeController>()) {
      return null;
    }

    try {
      final controller = Get.find<HomeController>();
      return controller.isClosed ? null : controller;
    } catch (_) {
      return null;
    }
  }

  Future<void> _withHomeController(
    Future<void> Function(HomeController controller) action,
  ) async {
    final controller = _homeControllerOrNull;
    if (controller == null) {
      return;
    }

    await action(controller);
  }

  bool get _shouldSyncPushToken {
    if (!AuthService.authenticated) return false;
    if (accessController.canUseProtectedFeatures) return true;
    if (RegistrationApprovalService.isAwaitingApproval) return true;
    return RegistrationApprovalService.shouldHoldRegistrationApproval(
      AuthService.currentUser,
    );
  }

  @override
  void onInit() {
    super.onInit();
    _initLocalNotifications();
    if (AlarmPendingActionStore.read() != null) {
      _openAlarmScreenFromPending();
    }
    ensurePushSetup().then((_) async {
      final holdRegistration =
          RegistrationApprovalService.isAwaitingApproval ||
          RegistrationApprovalService.shouldHoldRegistrationApproval(
            AuthService.currentUser,
          );

      if (_shouldSyncPushToken && !holdRegistration) {
        await syncFcmTokenWithUser(debugContext: 'onInit');
      }
      if (accessController.canUseProtectedFeatures) {
        await onAccessGranted(syncToken: false);
      }
    });
    _accessWorker = ever<UserAccessState>(
      accessController.state,
      _onAccessStateChanged,
    );
  }

  Future<void> ensurePushSetup() {
    _messagingInitFuture ??= _initFirebaseMessaging();
    return _messagingInitFuture!;
  }

  @override
  void onClose() {
    _accessWorker?.dispose();
    super.onClose();
  }

  Future<void> _onAccessStateChanged(UserAccessState state) async {
    if (state != UserAccessState.active) return;
    await onAccessGranted();
  }

  Future<void> onAccessGranted({bool syncToken = true}) async {
    if (!accessController.canUseProtectedFeatures) return;
    if (syncToken) {
      await syncFcmTokenWithUser(debugContext: 'onAccessGranted');
    }
    await fetchNotifications();
  }

  Future<bool> syncFcmTokenWithUser({
    bool showError = false,
    String? debugContext,
  }) async {
    if (!_shouldSyncPushToken) return false;

    final inFlight = _tokenSyncInFlight;
    if (inFlight != null) return inFlight;

    final task = _syncFcmTokenWithUserImpl(
      showError: showError,
      debugContext: debugContext,
    );
    _tokenSyncInFlight = task;
    try {
      return await task;
    } finally {
      if (identical(_tokenSyncInFlight, task)) {
        _tokenSyncInFlight = null;
      }
    }
  }

  Future<bool> _syncFcmTokenWithUserImpl({
    required bool showError,
    String? debugContext,
  }) async {
    try {
      await ensurePushSetup();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        if (showError) {
          AppSnackBars.errorSnackBar(
            title: AppTexts.warningTitle,
            message: AppTexts.fcmTokenUnavailable,
          );
        }
        return false;
      }

      return await _pushDeviceTokenIfNeeded(
        token,
        debugContext: debugContext ?? 'syncFcmTokenWithUser',
      );
    } catch (e, stackTrace) {
      _reportSyncError('FCM token sync failed', e, stackTrace);
      if (showError) {
        AppSnackBars.errorSnackBar(
          title: AppTexts.warningTitle,
          message: AppTexts.fcmTokenSyncFailed,
        );
      }
      return false;
    }
  }

  Future<bool> _pushDeviceTokenIfNeeded(
    String token, {
    bool force = false,
    String? debugContext,
  }) {
    return FcmTokenSyncGuard.pushIfNeeded(
      repository.setFcmToken,
      token,
      force: force,
      debugContext: debugContext,
    );
  }

  Future<void> showRegistrationPushAlert({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic> data = const {},
  }) async {
    await ensurePushSetup();
    final content = RegistrationNotificationDisplay.resolve(
      type: type,
      data: data,
      title: title,
      body: body,
    );
    final model = NotificationModel(
      id: '${_localNotificationPrefix}registration_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: content.title,
      body: content.body,
      data: data,
      eventId: 0,
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _showLocalNotification(model);
  }

  Future<void> _initFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (!_shouldSyncPushToken) return;
      try {
        await _pushDeviceTokenIfNeeded(
          newToken,
          force: true,
          debugContext: 'onTokenRefresh',
        );
      } catch (e, stackTrace) {
        _reportSyncError('FCM token refresh sync failed', e, stackTrace);
      }
    });

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleFcmMessage(message, foreground: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleFcmMessage(message, clicked: true);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleFcmMessage(initialMessage, clicked: true);
      });
    }
  }

  void setPendingFromArguments(Map<String, dynamic>? args) {
    if (args == null) return;
    final highlightId = args['highlightId'] as String?;
    final eventId = args['eventId'] as int?;
    if (highlightId != null) highlightNotificationId.value = highlightId;
    if (eventId != null && eventId > 0) autoOpenEventId.value = eventId;
  }

  void clearHighlight() {
    highlightNotificationId.value = null;
    autoOpenEventId.value = null;
  }

  void _handleFcmMessage(
    RemoteMessage message, {
    bool foreground = false,
    bool clicked = false,
  }) async {
    try {
      final model = _buildNotificationFromRemoteMessage(message);
      final type = model.resolvedType;

      if (RegistrationApprovalNotificationHandler.canHandle(message.data) ||
          type.isRegistrationApproval) {
        await RegistrationApprovalNotificationHandler.handle(
          message,
          clicked: clicked,
          foreground: foreground,
        );
        return;
      }

      if (!accessController.canUseProtectedFeatures) return;
      _upsertLocalNotification(model);

      final reminderCtrl = ReminderController.to;
      switch (model.resolvedType) {
        case NotificationType.eventInvitation:
        case NotificationType.updateEvent:
          await _syncEvent(model.eventId);
          break;
        case NotificationType.deleteEvent:
          await reminderCtrl.onEventDeleted(model.eventId.toString());
          await _withHomeController((homeController) async {
            homeController.allEvents.removeWhere((e) => e.id == model.eventId);
            homeController.allEvents.refresh();
            homeController.applySettings();
            homeController.processedEvents.refresh();
            await homeController.saveEvents();
          });
          break;
        case NotificationType.acceptUserRegistration:
        case NotificationType.rejectUserRegistration:
          break;
      }

      if (foreground) {
        await _showLocalNotification(model);
      }

      if (clicked) {
        await fetchNotifications();
        final highlightId = _resolveNotificationIdForNavigation(model);
        Get.toNamed(
          AppRouter.notifications,
          arguments: {'highlightId': highlightId, 'eventId': model.eventId},
        );
      }
    } catch (e, stackTrace) {
      _reportSyncError('fcm notification handling failed', e, stackTrace);
    }
  }

  void _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload == null || response.payload!.isEmpty) return;

        try {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;

          if (data['kind'] == 'event_alarm') {
            await AlarmPendingActionStore.save(data);
            _openAlarmScreenFromPending();
            return;
          }

          final eventId =
              int.tryParse(data['event_id']?.toString() ?? '0') ?? 0;
          final reference = _buildNotificationFromPayload(data);
          await fetchNotifications();
          final highlightId = _resolveNotificationIdForNavigation(reference);
          Get.toNamed(
            AppRouter.notifications,
            arguments: {
              if (highlightId != null) 'highlightId': highlightId,
              if (eventId > 0) 'eventId': eventId,
            },
          );
        } catch (e, stackTrace) {
          _reportSyncError(
            'local notification response handling failed',
            e,
            stackTrace,
          );
        }
      },
    );
  }

  void _openAlarmScreenFromPending() {
    final payload = AlarmPendingActionStore.read();
    if (payload == null) return;
    AlarmPendingActionStore.clear();
    Get.toNamed(AppRouter.alarmRinging, arguments: payload);
  }

  Future<void> _syncEvent(int eventId) async {
    if (!accessController.canUseProtectedFeatures) return;
    if (eventId <= 0) return;

    final homeController = _homeControllerOrNull;
    if (homeController == null) return;

    try {
      final event = await homeController.eventRepo.getEventDetails(eventId);

      final index = homeController.allEvents.indexWhere((e) => e.id == eventId);
      if (index == -1) {
        homeController.allEvents.add(event);
        homeController.allEvents.refresh();
        await ReminderController.to.onEventAdded(event);
      } else {
        homeController.allEvents[index] = event;
        homeController.allEvents.refresh();
        await ReminderController.to.onEventUpdated(event);
      }

      homeController.applySettings();
      homeController.processedEvents.refresh();
      await homeController.saveEvents();
    } on NotFoundException catch (e, stackTrace) {
      homeController.allEvents.removeWhere((e) => e.id == eventId);
      homeController.allEvents.refresh();
      await ReminderController.to.onEventDeleted(eventId.toString());
      homeController.applySettings();
      homeController.processedEvents.refresh();
      await homeController.saveEvents();
      _reportSyncError(
        'notification event not found during sync',
        e,
        stackTrace,
      );
    } catch (e, stackTrace) {
      _reportSyncError('notification event sync failed', e, stackTrace);
    }
  }

  Future<void> _showLocalNotification(NotificationModel model) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fcm_channel_id',
          'App Notifications',
          channelDescription: 'Foreground notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    final payload = {
      ...model.data,
      'id': model.id,
      'event_id': model.eventId.toString(),
      'title': model.title,
      'body': model.body,
      'created_at': model.createdAt,
      'notification_type': model.resolvedType.wireValue,
    };

    final showTitle = model.resolvedType.isRegistrationApproval
        ? model.displayTitle
        : model.title;
    final showBody = model.resolvedType.isRegistrationApproval
        ? model.displayBody
        : model.body;

    await _flutterLocalNotificationsPlugin.show(
      model.id.hashCode,
      showTitle,
      showBody,
      details,
      payload: jsonEncode(payload),
    );
  }

  Future<void> fetchNotifications({bool loadMore = false}) {
    if (_fetchTask != null) {
      return _fetchTask!;
    }

    _fetchTask = _fetchNotificationsInternal(
      loadMore: loadMore,
    ).whenComplete(() => _fetchTask = null);
    return _fetchTask!;
  }

  Future<void> _fetchNotificationsInternal({bool loadMore = false}) async {
    if (!accessController.canUseProtectedFeatures) return;
    if (loadMore && (!_hasMore || isLoadingMore.value || isLoading.value)) {
      return;
    }

    if (loadMore) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }
    syncError.value = null;

    try {
      if (!loadMore) {
        _page = 1;
      }

      final res = await repository.getAllNotifications(page: _page);
      _mergeServerNotifications(res.items, resetList: !loadMore);
      _hasMore = res.hasMorePages;
      hasMoreNotifications.value = res.hasMorePages;
      _page++;
    } catch (e, stackTrace) {
      _reportSyncError('fetch notifications failed', e, stackTrace);
    } finally {
      if (loadMore) {
        isLoadingMore.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }

  void loadMore() {
    fetchNotifications(loadMore: true);
  }

  void loadMoreIfNeeded(int index, {int preloadThreshold = 2}) {
    if (!hasMoreNotifications.value || isLoadingMore.value || isLoading.value) {
      return;
    }

    final triggerIndex = notifications.length - preloadThreshold;
    if (index >= triggerIndex) {
      loadMore();
    }
  }

  /// أحدث إشعار قبول/رفض تسجيل من الخادم (لإعادة فحص حالة الطلب).
  Future<NotificationModel?> fetchLatestRegistrationDecision() async {
    try {
      final res = await repository.getAllNotifications(page: 1);
      final decisions = res.items
          .where((n) => n.resolvedType.isRegistrationApproval)
          .toList();
      if (decisions.isEmpty) return null;

      decisions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return decisions.first;
    } catch (e, stackTrace) {
      _reportSyncError('fetch registration decision failed', e, stackTrace);
      return null;
    }
  }

  Future<void> markAsRead(String id) async {
    if (!accessController.canUseProtectedFeatures) return;

    try {
      await repository.markAsRead(id);
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
      }
    } catch (e, stackTrace) {
      _reportSyncError('mark notification as read failed', e, stackTrace);
    }
  }

  NotificationModel _buildNotificationFromRemoteMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final notification = message.notification;
    final type = NotificationTypeExtension.fromPayload(
      type: data['notification_type']?.toString(),
      data: data,
      title: notification?.title,
      body: notification?.body,
    );
    final eventId = int.tryParse(data['event_id']?.toString() ?? '0') ?? 0;
    final createdAt =
        data['created_at']?.toString() ??
        message.sentTime?.toIso8601String() ??
        DateTime.now().toIso8601String();
    final remoteId = _readNotificationId(data);

    final rawTitle = notification?.title ?? '';
    final rawBody = notification?.body ?? '';
    final display = type.isRegistrationApproval
        ? RegistrationNotificationDisplay.resolve(
            type: type,
            data: data,
            title: rawTitle,
            body: rawBody,
          )
        : null;

    return NotificationModel(
      id:
          remoteId ??
          _buildLocalNotificationId(
            eventId: eventId,
            type: type,
            title: display?.title ?? rawTitle,
            body: display?.body ?? rawBody,
            createdAt: createdAt,
            messageId: message.messageId,
          ),
      type: type,
      title: display?.title ?? rawTitle,
      body: display?.body ?? rawBody,
      data: data,
      eventId: eventId,
      isRead: false,
      createdAt: createdAt,
    );
  }

  NotificationModel _buildNotificationFromPayload(Map<String, dynamic> data) {
    final type = NotificationTypeExtension.fromPayload(
      type: data['notification_type']?.toString() ?? data['type']?.toString(),
      data: data,
      title: data['title']?.toString(),
      body: data['body']?.toString(),
    );
    final eventId = int.tryParse(data['event_id']?.toString() ?? '0') ?? 0;
    final createdAt =
        data['created_at']?.toString() ?? DateTime.now().toIso8601String();

    return NotificationModel(
      id:
          _readNotificationId(data) ??
          _buildLocalNotificationId(
            eventId: eventId,
            type: type,
            title: data['title']?.toString() ?? '',
            body: data['body']?.toString() ?? '',
            createdAt: createdAt,
          ),
      type: type,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      data: data,
      eventId: eventId,
      isRead: false,
      createdAt: createdAt,
    );
  }

  void _upsertLocalNotification(NotificationModel model) {
    final normalized = _normalizeNotification(model);
    _pendingLocalNotificationKeys.add(_notificationDedupKey(normalized));
    _upsertNotification(normalized, prependIfNew: true);
  }

  void _mergeServerNotifications(
    List<NotificationModel> serverItems, {
    required bool resetList,
  }) {
    final normalizedServer = serverItems.map(_normalizeNotification).toList();
    final merged = <NotificationModel>[
      if (!resetList) ...notifications,
      ...normalizedServer,
    ];

    if (resetList) {
      final pendingLocal = notifications.where((notification) {
        final key = _notificationDedupKey(notification);
        if (!_pendingLocalNotificationKeys.contains(key)) {
          return false;
        }

        return normalizedServer.every(
          (serverItem) => !_areSameNotification(serverItem, notification),
        );
      });

      merged.insertAll(0, pendingLocal.map(_normalizeNotification));
    }

    for (final serverItem in normalizedServer) {
      _pendingLocalNotificationKeys.remove(_notificationDedupKey(serverItem));
    }

    notifications.assignAll(_deduplicateAndSort(merged));
  }

  List<NotificationModel> _deduplicateAndSort(List<NotificationModel> items) {
    final deduplicated = <NotificationModel>[];

    for (final item in items) {
      final index = deduplicated.indexWhere(
        (existing) => _areSameNotification(existing, item),
      );

      if (index == -1) {
        deduplicated.add(item);
      } else {
        deduplicated[index] = _mergeNotificationModels(
          deduplicated[index],
          item,
        );
      }
    }

    deduplicated.sort(_compareNotifications);
    return deduplicated;
  }

  void _upsertNotification(
    NotificationModel notification, {
    bool prependIfNew = false,
  }) {
    final current = notifications.toList();
    final index = current.indexWhere(
      (existing) => _areSameNotification(existing, notification),
    );

    if (index == -1) {
      if (prependIfNew) {
        current.insert(0, notification);
      } else {
        current.add(notification);
      }
    } else {
      current[index] = _mergeNotificationModels(current[index], notification);
    }

    current.sort(_compareNotifications);
    notifications.assignAll(current);
  }

  NotificationModel _mergeNotificationModels(
    NotificationModel existing,
    NotificationModel incoming,
  ) {
    final existingId = _readNotificationId(existing.data) ?? existing.id;
    final incomingId = _readNotificationId(incoming.data) ?? incoming.id;
    final chosenId =
        _isLocalNotificationId(existingId) &&
            !_isLocalNotificationId(incomingId)
        ? incomingId
        : existingId;

    return NotificationModel(
      id: chosenId,
      type: incoming.type,
      title: incoming.title.isNotEmpty ? incoming.title : existing.title,
      body: incoming.body.isNotEmpty ? incoming.body : existing.body,
      eventId: incoming.eventId > 0 ? incoming.eventId : existing.eventId,
      data: incoming.data.isNotEmpty ? incoming.data : existing.data,
      isRead: existing.isRead || incoming.isRead,
      createdAt: incoming.createdAt.isNotEmpty
          ? incoming.createdAt
          : existing.createdAt,
    );
  }

  bool _areSameNotification(NotificationModel first, NotificationModel second) {
    final firstId = _readNotificationId(first.data) ?? first.id;
    final secondId = _readNotificationId(second.data) ?? second.id;

    if (firstId.isNotEmpty &&
        secondId.isNotEmpty &&
        !_isLocalNotificationId(firstId) &&
        !_isLocalNotificationId(secondId)) {
      return firstId == secondId;
    }

    return _notificationDedupKey(first) == _notificationDedupKey(second);
  }

  String _notificationDedupKey(NotificationModel notification) {
    final normalizedTitle = notification.title.trim().toLowerCase();
    final normalizedBody = notification.body.trim().toLowerCase();
    final createdAt = _normalizeCreatedAt(notification.createdAt);

    return [
      notification.eventId,
      notification.resolvedType.wireValue,
      normalizedTitle,
      normalizedBody,
      createdAt,
    ].join('|');
  }

  String _normalizeCreatedAt(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value.trim();
    }

    return parsed.toUtc().toIso8601String();
  }

  NotificationModel _normalizeNotification(NotificationModel notification) {
    var title = notification.title.trim();
    var body = notification.body.trim();
    final resolvedType = notification.resolvedType;

    if (resolvedType.isRegistrationApproval) {
      final content = RegistrationNotificationDisplay.resolve(
        type: resolvedType,
        data: notification.data,
        title: title,
        body: body,
      );
      title = content.title;
      body = content.body;
    }

    return NotificationModel(
      id: notification.id.trim(),
      type: notification.type,
      title: title,
      body: body,
      eventId: notification.eventId,
      data: Map<String, dynamic>.from(notification.data),
      isRead: notification.isRead,
      createdAt: notification.createdAt.trim(),
    );
  }

  int _compareNotifications(NotificationModel first, NotificationModel second) {
    final secondTime =
        DateTime.tryParse(second.createdAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final firstTime =
        DateTime.tryParse(first.createdAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return secondTime.compareTo(firstTime);
  }

  String _buildLocalNotificationId({
    required int eventId,
    required NotificationType type,
    required String title,
    required String body,
    required String createdAt,
    String? messageId,
  }) {
    final stableSeed = [
      messageId ?? '',
      eventId,
      type.wireValue,
      title.trim().toLowerCase(),
      body.trim().toLowerCase(),
      _normalizeCreatedAt(createdAt),
    ].join('|');

    return '$_localNotificationPrefix${stableSeed.hashCode.abs()}';
  }

  String? _readNotificationId(Map<String, dynamic> data) {
    final value = data['id']?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  bool _isLocalNotificationId(String value) =>
      value.trim().startsWith(_localNotificationPrefix);

  String? _resolveNotificationIdForNavigation(NotificationModel reference) {
    final match = notifications.firstWhereOrNull(
      (notification) => _areSameNotification(notification, reference),
    );
    return match?.id ?? (reference.id.isEmpty ? null : reference.id);
  }

  void _reportSyncError(String context, Object error, StackTrace stackTrace) {
    syncError.value = '$context: $error';
  }
}
