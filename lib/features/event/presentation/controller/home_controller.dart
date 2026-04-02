import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/dialoge/app_dialog.dart';
import 'package:mow_events/core/utils/local_storage/UserStorage/user_storage.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/repositories/events_repository.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';

import '../../../../core/utils/constants/enums/app_dialog_type.dart';

enum SortField { startTime, name, day }

enum SortOrder { asc, desc }

enum PrivacyFilter { all, publicOnly, privateOnly }

class HomeSettings {
  final bool enabled;
  final SortField sortField;
  final SortOrder sortOrder;
  final PrivacyFilter privacy;
  final int? categoryId;
  final DateTime? startAfter;
  final DateTime? endBefore;

  HomeSettings({
    this.enabled = true,
    this.sortField = SortField.startTime,
    this.sortOrder = SortOrder.asc,
    this.privacy = PrivacyFilter.all,
    this.categoryId,
    this.startAfter,
    this.endBefore,
  });

  HomeSettings copyWith({
    bool? enabled,
    SortField? sortField,
    SortOrder? sortOrder,
    PrivacyFilter? privacy,
    int? categoryId,
    DateTime? startAfter,
    DateTime? endBefore,
  }) {
    return HomeSettings(
      enabled: enabled ?? this.enabled,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      privacy: privacy ?? this.privacy,
      categoryId: categoryId ?? this.categoryId,
      startAfter: startAfter ?? this.startAfter,
      endBefore: endBefore ?? this.endBefore,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'sortField': sortField.index,
    'sortOrder': sortOrder.index,
    'privacy': privacy.index,
    'categoryId': categoryId,
    'startAfter': startAfter?.toIso8601String(),
    'endBefore': endBefore?.toIso8601String(),
  };

  factory HomeSettings.fromJson(Map<String, dynamic> json) => HomeSettings(
    enabled: json['enabled'] ?? true,
    sortField: SortField.values[json['sortField'] ?? 0],
    sortOrder: SortOrder.values[json['sortOrder'] ?? 0],
    privacy: PrivacyFilter.values[json['privacy'] ?? 0],
    categoryId: json['categoryId'],
    startAfter: json['startAfter'] != null
        ? DateTime.parse(json['startAfter'])
        : null,
    endBefore: json['endBefore'] != null
        ? DateTime.parse(json['endBefore'])
        : null,
  );
}

typedef EventFilter = bool Function(EventModel e);

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final EventsRepository eventRepo;

  HomeController({required this.eventRepo});
  final NetworkManager network = Get.find();

  RxList<EventModel> allEvents = <EventModel>[].obs;
  RxList<EventModel> processedEvents = <EventModel>[].obs;

  RxList<UserEntity> users = <UserEntity>[].obs;

  final currentIndex = 0.obs;
  final currentTabIndex = 0.obs;
  bool _initialized = false;
  final Rx<EventModel?> _lastAddedEvent = Rx<EventModel?>(null);
  final Rx<EventModel?> _lastUpdatedEvent = Rx<EventModel?>(null);

  Stream<EventModel?> get onEventAdded => _lastAddedEvent.stream;
  Stream<EventModel?> get onEventUpdated => _lastUpdatedEvent.stream;
  RxBool isLoading = false.obs;
  RxBool isUpdatingEvent = false.obs;
  final errorMessage = ''.obs;
  final searchQuery = ''.obs;
  final settings = HomeSettings().obs;
  final userStorage = UserStorage();

  RxBool hasMoreEvents = true.obs;

  late TabController tabController;
  UserModel? currentUser;
  int _currentPage = 1;
  final int pageSize = 20;
  static const String settingsKey = 'home_settings';

  /// آخر وقت تمت فيه مزامنة تلقائية (عند عودة النت) — لتجنب ضغط على السيرفر عند الانترنت المتقطع
  DateTime? _lastAutoSyncTime;
  Timer? _syncDebounceTimer;
  static const Duration _minSyncInterval = Duration(minutes: 5);
  static const Duration _syncDebounceDelay = Duration(seconds: 3);

  bool get isAdmin => currentUser?.isAdmin ?? false;
  bool get isManager => currentUser?.department?.isManager ?? false;

  List<EventModel> get validEvents => allEvents
      .where((e) => e.name.isNotEmpty && e.description.isNotEmpty)
      .toList();

  @override
  void onInit() {
    super.onInit();

    tabController = TabController(length: 4, vsync: this);
    tabController.addListener(() {
      if (currentTabIndex.value != tabController.index) {
        currentTabIndex.value = tabController.index;
      }
    });
    currentUser = AuthService.currentUser;

    ever(allEvents, (_) => applySettings());
    ever(searchQuery, (_) => applySettings());
    ever(settings, (_) => applySettings());
  }

  @override
  void onReady() {
    super.onReady();
    _init();
    ever(network.isOnline, _onConnectivityChanged);
  }

  @override
  void onClose() {
    _syncDebounceTimer?.cancel();
    super.onClose();
  }

  /// عند تغير حالة النت: تأخير (debounce) وحد أدنى بين مزامنتين لتقليل الضغط على السيرفر عند الانترنت المتقطع
  void _onConnectivityChanged(bool online) {
    _syncDebounceTimer?.cancel();
    if (!online) return;
    _syncDebounceTimer = Timer(_syncDebounceDelay, () async {
      _syncDebounceTimer = null;
      if (!network.isOnline.value) return;
      await _syncWhenOnlineIfNeeded();
    });
  }

  /// مزامنة تلقائية عند عودة النت فقط إذا مرّت الفترة الدنيا منذ آخر مزامنة (أو أول مرة)
  Future<void> _syncWhenOnlineIfNeeded() async {
    final now = DateTime.now();
    if (_lastAutoSyncTime != null &&
        now.difference(_lastAutoSyncTime!) < _minSyncInterval) {
      return;
    }
    await syncWithServer();
    _lastAutoSyncTime = DateTime.now();
  }

  Future<void> _init() async {
    await loadFromLocal();

    if (network.isOnline.value) {
      await syncWithServer();
      _lastAutoSyncTime = DateTime.now();
    }
  }

  Future<void> loadFromLocal() async {
    final data = userStorage.events;
    if (data != null && data.isNotEmpty) {
      allEvents.assignAll(data.map((e) => EventModel.fromJson(e)));
      ReminderController.to.cleanOrphanedReminders();
      await ReminderController.to.onEventsLoaded(allEvents);
      await ReminderController.to.rescheduleAllReminders();
      applySettings();
    } else {
      allEvents.clear();
    }
  }

  Future<void> syncWithServer() async {
    if (isLoading.value) return;
    await refreshAllEvents();
  }

  RxMap<String, dynamic> activeFilters = <String, dynamic>{}.obs;
  void applySettings() {
    List<EventModel> list = allEvents.toList();
    final s = settings.value;

    if (!s.enabled) {
      processedEvents.assignAll(list);
      return;
    }

    final List<EventFilter> filters = [];

    if (s.privacy != PrivacyFilter.all) {
      filters.add(
        (e) => s.privacy == PrivacyFilter.publicOnly
            ? e.isPublic == 1
            : e.isPrivate == 1,
      );
    }
    if (s.categoryId != null) {
      filters.add((e) => e.category?.id == s.categoryId);
    }
    if (s.startAfter != null) {
      filters.add((e) => e.startDateTimeSafe?.isAfter(s.startAfter!) ?? false);
    }
    if (s.endBefore != null) {
      filters.add((e) => e.endDateTimeSafe?.isBefore(s.endBefore!) ?? false);
    }
    final q = searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      filters.add(
        (e) =>
            e.name.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q),
      );
    }

    for (final f in filters) {
      list = list.where(f).toList();
    }

    list.sort((a, b) {
      int cmp = 0;
      switch (s.sortField) {
        case SortField.startTime:
          cmp = (a.startDateTimeSafe ?? DateTime(0)).compareTo(
            b.startDateTimeSafe ?? DateTime(0),
          );
          break;
        case SortField.name:
          cmp = a.name.compareTo(b.name);
          break;
        case SortField.day:
          cmp =
              DateTime(
                a.startDateTimeSafe?.year ?? 0,
                a.startDateTimeSafe?.month ?? 0,
                a.startDateTimeSafe?.day ?? 0,
              ).compareTo(
                DateTime(
                  b.startDateTimeSafe?.year ?? 0,
                  b.startDateTimeSafe?.month ?? 0,
                  b.startDateTimeSafe?.day ?? 0,
                ),
              );
          break;
      }
      return s.sortOrder == SortOrder.asc ? cmp : -cmp;
    });

    processedEvents.assignAll(list);

    saveSettingsToLocal();
  }

  void resetSettings() {
    settings.value = HomeSettings();
    applySettings();
  }

  void saveSettingsToLocal() {
    final storage = Get.find<AppLocalStorage>();

    storage.write(settingsKey, settings.value.toJson());
  }

  void loadSettingsFromLocal() {
    final storage = Get.find<AppLocalStorage>();
    final data = storage.read<Map<String, dynamic>>(settingsKey);
    if (data != null) {
      settings.value = HomeSettings.fromJson(data);
    }
  }

  Future<void> refreshAllEvents() async {
    if (isLoading.value) return;
    if (!network.isOnline.value) return;

    _currentPage = 1;
    hasMoreEvents.value = true;
    isLoading.value = true;

    try {
      final allFromServer = await _fetchAllEventsFromServer();
      allEvents
        ..clear()
        ..addAll(allFromServer);
      ReminderController.to.onEventsLoaded(allEvents);
      applySettings();
      await saveEvents();
      hasMoreEvents.value = false;
      _currentPage = (allFromServer.length / pageSize).ceil() + 1;
    } catch (e) {
      errorMessage.value = 'Failed to refresh events: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب كل الأحداث من السيرفر (جميع الصفحات) لضمان حفظ القائمة الكاملة في التخزين المحلي عند المزامنة
  Future<List<EventModel>> _fetchAllEventsFromServer() async {
    final result = <EventModel>[];
    int page = 1;
    while (true) {
      final list = await eventRepo.getEvents(page: page);
      final eventsPage = list.cast<EventModel>();
      if (eventsPage.isEmpty) break;
      result.addAll(eventsPage);
      if (eventsPage.length < pageSize) break;
      page++;
    }
    return result;
  }

  Future<void> loadInitialData({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) return;
    if (!network.isOnline.value) return;

    _initialized = true;
    await Future.wait([loadUsers(), loadEvents(reset: true)]);
  }

  Future<void> loadUsers({int? departmentId}) async {
    if (!(isAdmin || isManager)) return;
    if (!network.isOnline.value) return;

    try {
      final list = await eventRepo.getAllUsers(departmentId: departmentId);
      users.assignAll(list);
    } catch (e) {}
  }

  Future<void> saveEvents() async {
    try {
      final jsonList = allEvents.map((e) => e.toJson()).toList();
      await userStorage.saveEvents(jsonList);
    } catch (_) {}
  }

  Future<void> loadEvents({bool reset = false}) async {
    if (isLoading.value) return;
    if (!network.isOnline.value) return;

    isLoading.value = true;

    if (reset) {
      _currentPage = 1;
      hasMoreEvents.value = true;
    }

    try {
      final list = await eventRepo.getEvents(page: _currentPage);
      final eventsPage = list.cast<EventModel>();

      if (eventsPage.length < pageSize) {
        hasMoreEvents.value = false;
      }

      allEvents.addAll(eventsPage);
      await ReminderController.to.onEventsLoaded(eventsPage);

      applySettings();

      await saveEvents();

      _currentPage++;
    } catch (e) {
      errorMessage.value = 'Failed to load events: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createEvent(EventModel event) async {
    if (!InternetGuard.ensureOnline()) return;

    isLoading.value = true;
    try {
      final created = await eventRepo.createEvent(event);

      allEvents.add(created);
      ReminderController.to.onEventAdded(created);

      applySettings();
      allEvents.refresh();
      await saveEvents();

      _lastAddedEvent.value = created;
    } catch (e) {
      errorMessage.value = 'Failed to create event: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateEvent(int id, EventModel updatedEvent) async {
    if (!InternetGuard.ensureOnline()) return;

    isUpdatingEvent.value = true;
    try {
      final updated = await eventRepo.updateEvent(id: id, event: updatedEvent);
      final index = allEvents.indexWhere((e) => e.id == id);
      if (index != -1) {
        List<int> mergedMembers = updated.members;
        if (mergedMembers.isEmpty && updatedEvent.members.isNotEmpty) {
          mergedMembers = List.from(updatedEvent.members);
          final currentUserId = AuthService.currentUser?.id;
          if (currentUserId != null && !mergedMembers.contains(currentUserId)) {
            mergedMembers = [...mergedMembers, currentUserId];
          }
        }
        final merged =
            updated.members.isEmpty && updatedEvent.members.isNotEmpty
            ? updated.copyWith(members: mergedMembers)
            : updated;
        allEvents
          ..removeAt(index)
          ..insert(index, merged);

        allEvents.refresh();

        applySettings();

        ReminderController.to.onEventUpdated(merged);

        await saveEvents();

        _lastUpdatedEvent.value = merged;
      }
    } catch (e) {
      errorMessage.value = 'Failed to update event: $e';
      rethrow;
    } finally {
      isUpdatingEvent.value = false;
    }
  }

  Future<void> deleteEvent(int id) async {
    if (!InternetGuard.ensureOnline()) return;

    isLoading.value = true;

    try {
      await eventRepo.deleteEvents([id]);
      allEvents.removeWhere((e) => e.id == id);
      ReminderController.to.onEventDeleted(id.toString());

      applySettings();
      allEvents.refresh();
      await saveEvents();
    } catch (e) {
      errorMessage.value = 'Failed to delete event: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void changeBottomIndex(int index) => currentIndex.value = index;

  /// الرجوع إلى التبويب اليومي (لزر الرجوع من أسبوع/شهر/سنة)
  void goToDayTab() {
    if (tabController.index != 0) {
      tabController.animateTo(0);
      currentTabIndex.value = 0;
    }
  }

  /// الرجوع إلى الصفحة الرئيسة والتبويب اليومي (لزر الرجوع من الإعدادات)
  void goToDayScreen() {
    currentIndex.value = 0;
    if (tabController.index != 0) {
      tabController.animateTo(0);
    }
    currentTabIndex.value = 0;
  }

  Future<void> confirmDelete(EventModel event) async {
    if (!InternetGuard.ensureOnline()) return;

    await showAppDialog(
      context: Get.context!,
      type: AppDialogType.delete,
      onConfirm: () async {
        await deleteEvent(event.id);
      },
      onCancel: () {},
    );
  }
}
