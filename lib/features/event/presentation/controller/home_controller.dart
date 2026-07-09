import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/dialoge/app_dialog.dart';
import 'package:mow_events/core/utils/local_storage/UserStorage/user_storage.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:mow_events/core/utils/network/internet_guard.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/features/auth/data/models/user_model.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';
import 'package:mow_events/features/auth/presentation/controller/user_access_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/repositories/events_repository.dart';
import 'package:mow_events/core/alarm/event_alarm_service.dart';
import 'package:mow_events/features/event/presentation/controller/reminder_controller.dart';

import '../../../../core/utils/constants/enums/app_dialog_type.dart';

enum SortField { startTime, name, day }

enum SortOrder { asc, desc }

enum PrivacyFilter { all, publicOnly, personalOnly }

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

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final EventsRepository eventRepo;

  HomeController({required this.eventRepo});
  final NetworkManager network = Get.find();
  final UserAccessController accessController = Get.find();

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
  final searchTextController = TextEditingController();
  final searchFocusNode = FocusNode();
  final settings = HomeSettings().obs;
  final userStorage = UserStorage();

  RxBool hasMoreEvents = true.obs;
  RxBool isLoadingMoreEvents = false.obs;

  late TabController tabController;
  UserModel? currentUser;
  int _currentPage = 1;
  final int pageSize = 20;
  static const String settingsKey = 'home_settings';
  Worker? _accessWorker;
  Worker? _networkWorker;
  Worker? _searchWorker;
  Worker? _settingsPersistenceWorker;
  bool _hasUnlockedAccess = false;

  /// آخر وقت تمت فيه مزامنة تلقائية (عند عودة النت) — لتجنب ضغط على السيرفر عند الانترنت المتقطع
  DateTime? _lastAutoSyncTime;
  Timer? _syncDebounceTimer;
  static const Duration _minSyncInterval = Duration(minutes: 5);
  static const Duration _syncDebounceDelay = Duration(seconds: 3);
  static const Duration _searchDebounceDelay = Duration(milliseconds: 250);
  static const Duration _settingsSaveDebounceDelay = Duration(
    milliseconds: 350,
  );

  bool get isAdmin => currentUser?.isAdmin ?? false;
  bool get isManager => currentUser?.department?.isManager ?? false;

  /// أحداث قابلة للعرض (لا تُستبعد بسبب نقص الاسم/الوصف فقط).
  List<EventModel> get validEvents => allEvents
      .where((e) => e.id > 0 && e.startDateTimeSafe != null)
      .toList();

  @override
  void onInit() {
    super.onInit();

    tabController = TabController(length: 4, vsync: this);
    tabController.addListener(_handleTabIndexChanged);
    currentUser = AuthService.currentUser;
    searchTextController.text = searchQuery.value;

    _searchWorker = debounce<String>(
      searchQuery,
      (_) => applySettings(),
      time: _searchDebounceDelay,
    );
    _settingsPersistenceWorker = debounce<HomeSettings>(
      settings,
      (_) => saveSettingsToLocal(),
      time: _settingsSaveDebounceDelay,
    );
  }

  @override
  void onReady() {
    super.onReady();
    _init();
    _accessWorker = ever<UserAccessState>(
      accessController.state,
      _onAccessStateChanged,
    );
    _networkWorker = ever<bool>(network.isOnline, _onConnectivityChanged);
  }

  @override
  void onClose() {
    _accessWorker?.dispose();
    _networkWorker?.dispose();
    _searchWorker?.dispose();
    _settingsPersistenceWorker?.dispose();
    _syncDebounceTimer?.cancel();
    tabController.removeListener(_handleTabIndexChanged);
    tabController.dispose();
    searchFocusNode.dispose();
    searchTextController.dispose();
    super.onClose();
  }

  void _handleTabIndexChanged() {
    if (currentTabIndex.value != tabController.index) {
      currentTabIndex.value = tabController.index;
    }
  }

  void onSearchChanged(String value) {
    if (searchQuery.value == value) {
      return;
    }
    searchQuery.value = value;
  }

  void unfocusSearch() {
    if (searchFocusNode.hasFocus) {
      searchFocusNode.unfocus();
    }
  }

  Future<void> _onAccessStateChanged(UserAccessState state) async {
    if (state != UserAccessState.active) {
      _hasUnlockedAccess = false;
      return;
    }

    if (_hasUnlockedAccess) return;

    _hasUnlockedAccess = true;
    currentUser = AuthService.currentUser;

    await loadUsers();

    if (!network.isOnline.value) return;
    await syncWithServer();
    _lastAutoSyncTime = DateTime.now();
  }

  /// عند تغير حالة النت: تأخير (debounce) وحد أدنى بين مزامنتين لتقليل الضغط على السيرفر عند الانترنت المتقطع
  void _onConnectivityChanged(bool online) {
    _syncDebounceTimer?.cancel();
    if (!accessController.canUseProtectedFeatures) return;
    if (!online) return;
    _syncDebounceTimer = Timer(_syncDebounceDelay, () async {
      _syncDebounceTimer = null;
      if (!network.isOnline.value ||
          !accessController.canUseProtectedFeatures) {
        return;
      }
      await _syncWhenOnlineIfNeeded();
    });
  }

  /// مزامنة تلقائية عند عودة النت فقط إذا مرّت الفترة الدنيا منذ آخر مزامنة (أو أول مرة)
  Future<void> _syncWhenOnlineIfNeeded() async {
    if (!accessController.canUseProtectedFeatures) return;

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

    if (accessController.canUseProtectedFeatures && network.isOnline.value) {
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
      await _syncEventAlarms();
      applySettings();
    } else {
      allEvents.clear();
      processedEvents.clear();
      await _syncEventAlarms();
    }
  }

  Future<void> syncWithServer() async {
    if (!accessController.canUseProtectedFeatures) return;
    if (isLoading.value) return;
    await refreshAllEvents();
  }

  RxMap<String, dynamic> activeFilters = <String, dynamic>{}.obs;
  void applySettings() {
    final s = settings.value;
    final query = searchQuery.value.trim().toLowerCase();

    if (!s.enabled) {
      _updateProcessedEventsIfNeeded(allEvents.toList());
      return;
    }

    final filteredEvents = <EventModel>[];
    for (final event in allEvents) {
      if (_matchesSettings(event: event, settings: s, query: query)) {
        filteredEvents.add(event);
      }
    }

    filteredEvents.sort((a, b) => _compareEvents(a, b, s));
    _updateProcessedEventsIfNeeded(filteredEvents);
  }

  bool _matchesSettings({
    required EventModel event,
    required HomeSettings settings,
    required String query,
  }) {
    if (settings.privacy != PrivacyFilter.all) {
      final matchesPrivacy = settings.privacy == PrivacyFilter.publicOnly
          ? event.isPublic == 1
          : event.isPrivate == 1;
      if (!matchesPrivacy) return false;
    }

    if (settings.categoryId != null &&
        event.category?.id != settings.categoryId) {
      return false;
    }

    if (settings.startAfter != null) {
      final eventStart = event.startDateTimeSafe;
      final filterStart = _startOfDay(settings.startAfter!);
      if (eventStart == null || eventStart.isBefore(filterStart)) {
        return false;
      }
    }

    if (settings.endBefore != null) {
      final eventEnd = event.endDateTimeSafe;
      final filterEnd = _endOfDay(settings.endBefore!);
      if (eventEnd == null || eventEnd.isAfter(filterEnd)) {
        return false;
      }
    }

    if (query.isNotEmpty &&
        !event.name.toLowerCase().contains(query) &&
        !event.description.toLowerCase().contains(query)) {
      return false;
    }

    return true;
  }

  int _compareEvents(EventModel a, EventModel b, HomeSettings settings) {
    int cmp = 0;
    switch (settings.sortField) {
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
    return settings.sortOrder == SortOrder.asc ? cmp : -cmp;
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999);
  }

  void _updateProcessedEventsIfNeeded(List<EventModel> nextEvents) {
    if (listEquals<EventModel>(processedEvents, nextEvents)) {
      return;
    }

    processedEvents.assignAll(nextEvents);
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
    if (!accessController.canUseProtectedFeatures) return;
    if (isLoading.value) return;
    if (!InternetGuard.ensureOnlineForListRefresh()) return;

    _currentPage = 1;
    hasMoreEvents.value = true;
    isLoading.value = true;

    try {
      final allFromServer = await _fetchAllEventsFromServer();
      allEvents
        ..clear()
        ..addAll(allFromServer);
      await ReminderController.to.onEventsLoaded(allEvents);
      await _syncEventAlarms();
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
    if (!accessController.canUseProtectedFeatures) return;
    if (!network.isOnline.value) return;

    _initialized = true;
    await Future.wait([loadUsers(), loadEvents(reset: true)]);
  }

  Future<void> loadUsers({int? departmentId}) async {
    if (!accessController.canUseProtectedFeatures) return;

    currentUser = AuthService.currentUser;
    if (!(isAdmin || isManager)) return;
    if (!network.isOnline.value) return;

    try {
      final list = await eventRepo.getAllUsers(departmentId: departmentId);
      users.assignAll(list);
    } catch (_) {
      // User list fetch is optional for the home flow.
    }
  }

  Future<void> saveEvents() async {
    try {
      final jsonList = allEvents.map((e) => e.toJson()).toList();
      await userStorage.saveEvents(jsonList);
    } catch (_) {}
  }

  Future<void> loadEvents({bool reset = false}) async {
    if (!accessController.canUseProtectedFeatures) return;
    if (isLoading.value || isLoadingMoreEvents.value) return;
    if (!network.isOnline.value) return;
    if (!reset && !hasMoreEvents.value) return;

    if (reset) {
      isLoading.value = true;
    } else {
      isLoadingMoreEvents.value = true;
    }

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

      final existingById = {
        for (final event in allEvents) event.id: event,
      };
      for (final event in eventsPage) {
        existingById[event.id] = event;
      }
      allEvents.assignAll(existingById.values.toList());
      await ReminderController.to.onEventsLoaded(eventsPage);

      await _syncEventAlarms();
      applySettings();

      await saveEvents();

      _currentPage++;
    } catch (e) {
      errorMessage.value = 'Failed to load events: $e';
    } finally {
      if (reset) {
        isLoading.value = false;
      } else {
        isLoadingMoreEvents.value = false;
      }
    }
  }

  Future<void> loadMoreEvents() async {
    await loadEvents();
  }

  Future<void> createEvent(EventModel event) async {
    if (!accessController.canUseProtectedFeatures) return;
    if (!InternetGuard.ensureOnline()) return;

    isLoading.value = true;
    try {
      final created = await eventRepo.createEvent(event);

      allEvents.add(created);
      await ReminderController.to.onEventAdded(created);

      await _syncEventAlarms();
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
    if (!accessController.canUseProtectedFeatures) return;
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
        EventModel merged =
            updated.members.isEmpty && updatedEvent.members.isNotEmpty
            ? updated.copyWith(members: mergedMembers)
            : updated;
        final becamePersonal =
            updatedEvent.isPrivate == 1 && updatedEvent.isPublic == 0;
        if (becamePersonal) {
          // Personal events must not keep stale category/member data on card UI.
          merged = merged.copyWith(category: null, members: []);
        }
        allEvents
          ..removeAt(index)
          ..insert(index, merged);

        allEvents.refresh();

        applySettings();

        await ReminderController.to.onEventUpdated(merged);

        await _syncEventAlarms();
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
    if (!accessController.canUseProtectedFeatures) return;
    if (!InternetGuard.ensureOnline()) return;

    isLoading.value = true;

    try {
      await eventRepo.deleteEvents([id]);
      allEvents.removeWhere((e) => e.id == id);
      await ReminderController.to.onEventDeleted(id.toString());

      await _syncEventAlarms();
      applySettings();
      allEvents.refresh();
      await saveEvents();
    } catch (e) {
      errorMessage.value = 'Failed to delete event: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void changeBottomIndex(int index) {
    unfocusSearch();
    currentIndex.value = index;
  }

  /// الرجوع إلى التبويب اليومي (لزر الرجوع من أسبوع/شهر/سنة)
  void goToDayTab() {
    unfocusSearch();
    if (tabController.index != 0) {
      tabController.animateTo(0);
      currentTabIndex.value = 0;
    }
  }

  /// الرجوع إلى الصفحة الرئيسة والتبويب اليومي (لزر الرجوع من الإعدادات)
  void goToDayScreen() {
    unfocusSearch();
    currentIndex.value = 0;
    if (tabController.index != 0) {
      tabController.animateTo(0);
    }
    currentTabIndex.value = 0;
  }

  Future<void> _syncEventAlarms() async {
    if (!Get.isRegistered<EventAlarmService>()) return;
    await EventAlarmService.to.syncFromEvents(allEvents.toList());
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

  /// جلب الحدث من السيرفر وتحديثه في القائمة المحلية
  Future<EventModel?> refreshEventById(int id) async {
    if (!accessController.canUseProtectedFeatures) return null;
    if (!InternetGuard.ensureOnline()) return null;
    try {
      final updated = await eventRepo.getEventDetails(id);
      final index = allEvents.indexWhere((e) => e.id == id);
      if (index != -1) {
        allEvents
          ..removeAt(index)
          ..insert(index, updated);
        allEvents.refresh();
        applySettings();
        await saveEvents();
      }
      return updated;
    } catch (_) {
      return null;
    }
  }

  /// رفض دعوة حدث — يُرسل الرفض للسيرفر ويُزيل الحدث محلياً فوراً.
  /// لا يجلب تفاصيل الحدث بعد الرفض لأن المستخدم لم يعد يملك صلاحية الوصول.
  Future<void> rejectEventInvitation({
    required int eventId,
    String? descriptionReject,
  }) async {
    if (!accessController.canUseProtectedFeatures) throw Exception('no access');
    if (!InternetGuard.ensureOnline()) throw Exception('offline');
    await eventRepo.changeEventMemberStatus(
      eventId: eventId,
      status: 'reject',
      descriptionReject: descriptionReject,
    );
    allEvents.removeWhere((e) => e.id == eventId);
    applySettings();
  }

  /// قبول دعوة حدث أو أي تغيير حالة آخر — يُرسل للسيرفر ثم يُحدّث الحدث من السيرفر.
  Future<EventModel?> changeEventMemberStatus({
    required int eventId,
    required String status,
    String? descriptionReject,
  }) async {
    if (!accessController.canUseProtectedFeatures) return null;
    if (!InternetGuard.ensureOnline()) return null;
    try {
      await eventRepo.changeEventMemberStatus(
        eventId: eventId,
        status: status,
        descriptionReject: descriptionReject,
      );
      return await refreshEventById(eventId);
    } catch (_) {
      rethrow;
    }
  }
}
