import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/local_storage/UserStorage/user_storage.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
import 'package:mow_events/core/utils/local_storage/storage_keys.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/domin/entities/reminder_entity.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

enum ReminderAction { add, update, remove }

class ReminderController extends GetxController {
  static ReminderController get to => Get.find();

  static const MethodChannel _channel = MethodChannel('alarm_channel');

  final UserStorage userStorage = UserStorage();
  final AppLocalStorage storage = AppLocalStorage();

  HomeController get _home => Get.find<HomeController>();

  List<EventModel> get _events => _home.allEvents;

  RxMap<String, List<ReminderEntity>> remindersMap =
      <String, List<ReminderEntity>>{}.obs;
  RxList<DefaultReminder> defaultReminders = <DefaultReminder>[].obs;
  RxMap<String, Set<String>> ignoredDefaultReminders =
      <String, Set<String>>{}.obs;

  late final Stream<DateTime> ticker;

  @override
  void onInit() {
    super.onInit();
    loadDefaultReminders();
    loadIgnoredDefaultReminders();
    loadScheduledReminders();

    ticker = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    ).asBroadcastStream();
  }

  Future<void> clearUserScopedState({bool cancelAlarms = true}) async {
    if (cancelAlarms) {
      for (final reminders in remindersMap.values) {
        for (final reminder in reminders) {
          await cancelAlarmNative(reminder.alarmId);
        }
      }
    }

    remindersMap.clear();
    defaultReminders.clear();
    ignoredDefaultReminders.clear();

    remindersMap.refresh();
    defaultReminders.refresh();
    ignoredDefaultReminders.refresh();
  }

  void reloadUserScopedState() {
    remindersMap.clear();
    defaultReminders.clear();
    ignoredDefaultReminders.clear();

    loadDefaultReminders();
    loadIgnoredDefaultReminders();
    loadScheduledReminders();

    remindersMap.refresh();
    defaultReminders.refresh();
    ignoredDefaultReminders.refresh();
  }

  List<ReminderEntity> getReminders(String eventId) =>
      remindersMap[eventId]?.toList() ?? [];

  void validateDefaultReminder({
    required ReminderType type,
    required int value,
    int? editingIndex,
  }) {
    if (value < 0) {
      throw ArgumentError(AppTexts.reminderValueCannotBeNegative);
    }

    if (value == 0) {
      if (ReminderEntity.isReservedAtStartReminder(type, value)) {
        throw ArgumentError(AppTexts.reminderAtStartReserved);
      }

      throw ArgumentError(AppTexts.mustBeGreaterThanZero);
    }

    for (int i = 0; i < defaultReminders.length; i++) {
      if (editingIndex != null && i == editingIndex) continue;

      final reminder = defaultReminders[i];
      if (reminder.type == type && reminder.value == value) {
        throw ArgumentError(AppTexts.reminderAlreadyExists);
      }
    }
  }

  /// كل التنبيهات المجدولة لجميع الأحداث مرتبة حسب وقت التنبيه (لعرضها في الشاشة اليومية)
  List<ScheduledReminderInfo> getAllScheduledRemindersSorted() {
    final List<ScheduledReminderInfo> result = [];
    for (final entry in remindersMap.entries) {
      final eventId = entry.key;
      final event = _events.firstWhereOrNull((e) => e.id.toString() == eventId);
      for (final r in entry.value) {
        result.add(ScheduledReminderInfo(reminder: r, event: event));
      }
    }
    result.sort(
      (a, b) => a.reminder.reminderTime.compareTo(b.reminder.reminderTime),
    );
    return result;
  }

  static int _toSafeRequestCode(int id) =>
      (id & 0x7FFFFFFF) != 0 ? (id & 0x7FFFFFFF) : 1;

  Future<void> applyReminderChange({
    required ReminderAction action,
    required String eventId,
    ReminderEntity? reminder,
  }) async {
    if (reminder?.source == ReminderSource.default_) {
      return;
    }
    final nextList = List<ReminderEntity>.from(remindersMap[eventId] ?? []);

    if (reminder != null &&
        reminder.isCustom &&
        (action == ReminderAction.add || action == ReminderAction.update)) {
      ReminderEntity.validateCustom(
        type: reminder.type,
        value: reminder.value,
        existingReminders: nextList,
        editingReminderId: action == ReminderAction.update ? reminder.id : null,
      );
    }

    switch (action) {
      case ReminderAction.add:
        if (reminder == null) return;
        final safeReminder = _normalizeReminder(reminder);
        nextList.removeWhere((r) => r.id == safeReminder.id);
        nextList.add(safeReminder);
        break;

      case ReminderAction.update:
        if (reminder == null) return;
        final safeReminder = _normalizeReminder(reminder);
        nextList.removeWhere((r) => r.id == safeReminder.id);
        nextList.add(safeReminder);
        break;

      case ReminderAction.remove:
        if (reminder == null) return;
        nextList.removeWhere((r) => r.id == reminder.id);
        break;
    }

    await _updateEventRemindersSafely(eventId: eventId, nextList: nextList);
  }

  /// إضافة تذكير افتراضي. إذا [applyToAllEvents] = true يُحمَّل كل الأحداث من السيرفر ثم يُطبَّق على الجميع.
  /// إذا [applyToAllEvents] = false يُطبَّق على الأحداث المستقبلية فقط (التي لم تبدأ بعد).
  Future<void> addDefaultReminder(
    DefaultReminder reminder, {
    bool applyToAllEvents = false,
  }) async {
    validateDefaultReminder(type: reminder.type, value: reminder.value);
    defaultReminders.add(reminder);
    saveDefaultReminders();

    if (applyToAllEvents) {
      try {
        await _home.refreshAllEvents();
      } catch (_) {
        // عند عدم توفر الشبكة نطبّق على الأحداث المحمّلة حالياً
      }
      await applySingleDefaultToAllEvents(reminder, futureOnly: false);
    } else {
      await applySingleDefaultToAllEvents(reminder, futureOnly: true);
    }
  }

  /// تطبيق تذكير افتراضي واحد على الأحداث. [futureOnly] = true يعني فقط الأحداث التي تاريخ بدئها بعد الآن.
  Future<void> applySingleDefaultToAllEvents(
    DefaultReminder def, {
    String? oldKey,
    bool futureOnly = false,
  }) async {
    final key = '${def.type.name}_${def.value}';
    final now = DateTime.now();

    for (final event in _events) {
      final start = event.startDateTimeSafe;
      if (start == null) continue;
      if (futureOnly && !start.isAfter(now)) continue;

      final eventId = event.id.toString();
      final nextList = List<ReminderEntity>.from(remindersMap[eventId] ?? []);
      var changed = false;

      if (oldKey != null) {
        final removedCount = nextList
            .where(
              (r) =>
                  r.source == ReminderSource.default_ && r.defaultKey == oldKey,
            )
            .length;
        nextList.removeWhere(
          (r) => r.source == ReminderSource.default_ && r.defaultKey == oldKey,
        );
        ignoredDefaultReminders[eventId]?.remove(oldKey);
        changed = removedCount > 0;
      }

      if (ignoredDefaultReminders[eventId]?.contains(key) == true) {
        if (changed) {
          await _updateEventRemindersSafely(
            eventId: eventId,
            nextList: nextList,
          );
        }
        continue;
      }

      final exists = nextList.any(
        (r) => r.source == ReminderSource.default_ && r.defaultKey == key,
      );

      if (!exists) {
        nextList.add(def.toReminderEntity(eventId, start));
        changed = true;
      }

      if (changed) {
        await _updateEventRemindersSafely(eventId: eventId, nextList: nextList);
      }
    }

    saveScheduledReminders();
  }

  Future<void> updateDefaultReminder(
    int index,
    ReminderType type,
    int value, {
    required bool applyToAllEvents,
  }) async {
    if (index < 0 || index >= defaultReminders.length) return;
    validateDefaultReminder(type: type, value: value, editingIndex: index);

    final old = defaultReminders[index];
    final updated = old.copyWith(type: type, value: value);
    final keyOld = '${old.type.name}_${old.value}';
    final keyUpdated = '${updated.type.name}_${updated.value}';

    defaultReminders[index] = updated;
    saveDefaultReminders();

    final now = DateTime.now();

    for (final event in _events) {
      final start = event.startDateTimeSafe;
      if (start == null) continue;
      final eventId = event.id.toString();
      final nextList = List<ReminderEntity>.from(remindersMap[eventId] ?? []);
      var changed = false;

      if (applyToAllEvents) {
        final hadOld = nextList.any(
          (r) =>
              r.source == ReminderSource.default_ &&
              r.defaultKey == keyOld &&
              ignoredDefaultReminders[eventId]?.contains(keyOld) != true,
        );

        if (hadOld) {
          nextList.removeWhere(
            (r) =>
                r.source == ReminderSource.default_ &&
                r.defaultKey == keyOld &&
                ignoredDefaultReminders[eventId]?.contains(keyOld) != true,
          );
          nextList.add(updated.toReminderEntity(eventId, start));
          changed = true;
        }
      } else {
        if (start.isAfter(now)) {
          final hasOld = nextList.any(
            (r) =>
                r.source == ReminderSource.default_ &&
                r.defaultKey == keyOld &&
                ignoredDefaultReminders[eventId]?.contains(keyOld) != true,
          );
          if (hasOld) {
            nextList.removeWhere(
              (r) =>
                  r.source == ReminderSource.default_ &&
                  r.defaultKey == keyOld &&
                  ignoredDefaultReminders[eventId]?.contains(keyOld) != true,
            );
            nextList.add(updated.toReminderEntity(eventId, start));
            changed = true;
          } else {
            final exists = nextList.any(
              (r) =>
                  r.source == ReminderSource.default_ &&
                  r.defaultKey == keyUpdated,
            );
            if (!exists) {
              nextList.add(updated.toReminderEntity(eventId, start));
              changed = true;
            }
          }
        }
      }

      if (changed) {
        await _updateEventRemindersSafely(eventId: eventId, nextList: nextList);
      }
    }

    saveScheduledReminders();
  }

  Future<void> removeDefaultReminder(
    int index, {
    bool applyToAllEvents = false,
  }) async {
    if (index < 0 || index >= defaultReminders.length) return;

    final removed = defaultReminders.removeAt(index);
    final key = '${removed.type.name}_${removed.value}';

    saveDefaultReminders();

    final now = DateTime.now();

    for (final eventId in remindersMap.keys.toList()) {
      final nextList = List<ReminderEntity>.from(remindersMap[eventId] ?? []);

      final event = _events.firstWhereOrNull((e) => e.id.toString() == eventId);

      if (event == null || event.startDateTimeSafe == null) {
        continue;
      }

      final eventStart = event.startDateTimeSafe!;

      if (applyToAllEvents || eventStart.isAfter(now)) {
        ignoredDefaultReminders.putIfAbsent(eventId, () => {}).add(key);
        nextList.removeWhere(
          (r) => r.source == ReminderSource.default_ && r.defaultKey == key,
        );
        await _updateEventRemindersSafely(eventId: eventId, nextList: nextList);
      }
    }

    saveIgnoredDefaultReminders();
    saveScheduledReminders();
  }

  Future<void> rescheduleAllReminders() async {
    for (final eventId in remindersMap.keys.toList()) {
      final event = _events.firstWhereOrNull((e) => e.id.toString() == eventId);
      if (event != null && event.startDateTimeSafe != null) {
        await _rescheduleEvent(eventId);
      }
    }
  }

  void cleanOrphanedReminders() {
    final toRemove = <String>[];
    for (final eventId in remindersMap.keys) {
      final event = _events.firstWhereOrNull((e) => e.id.toString() == eventId);
      if (event == null || event.startDateTimeSafe == null) {
        toRemove.add(eventId);
      }
    }
    for (final eventId in toRemove) {
      for (final r in remindersMap[eventId] ?? []) {
        cancelAlarmNative(r.alarmId);
      }
      remindersMap.remove(eventId);
      ignoredDefaultReminders.remove(eventId);
    }
    if (toRemove.isNotEmpty) {
      remindersMap.refresh();
      saveScheduledReminders();
      saveIgnoredDefaultReminders();
    }
  }

  Future<void> onEventsLoaded(List<EventModel> events) async {
    cleanOrphanedReminders();

    var anyScheduled = false;
    for (final event in events) {
      final eventId = event.id.toString();
      final eventStart = event.startDateTimeSafe;

      if (eventStart == null) {
        if (remindersMap.containsKey(eventId)) {
          await onEventDeleted(eventId);
        }
        continue;
      }

      final hadExistingReminders = remindersMap.containsKey(eventId);
      final currentList = List<ReminderEntity>.from(
        remindersMap[eventId] ?? [],
      );
      final syncedList = _buildSyncedRemindersForEvent(
        event: event,
        eventId: eventId,
        eventStart: eventStart,
        currentList: currentList,
      );

      if (_areReminderListsEquivalent(currentList, syncedList)) {
        continue;
      }

      await _updateEventRemindersSafely(eventId: eventId, nextList: syncedList);

      if (!hadExistingReminders && syncedList.isNotEmpty) {
        anyScheduled = true;
      }
    }

    saveScheduledReminders();
    if (anyScheduled) {
      AppSnackBars.successSnackBar(
        title: AppTexts.reminders,
        message: AppTexts.remindersWillBeSetForEvents,
      );
    }
  }

  Future<void> onEventAdded(EventModel event) async {
    final eventStart = event.startDateTimeSafe;
    if (eventStart == null) return;
    final eventId = event.id.toString();
    final syncedList = _buildSyncedRemindersForEvent(
      event: event,
      eventId: eventId,
      eventStart: eventStart,
      currentList: const [],
    );

    await _updateEventRemindersSafely(eventId: eventId, nextList: syncedList);
  }

  Future<void> ignoreDefaultReminder(
    String eventId,
    ReminderEntity reminder,
  ) async {
    ignoredDefaultReminders
        .putIfAbsent(eventId, () => {})
        .add(reminder.defaultKey!);

    final nextList = List<ReminderEntity>.from(remindersMap[eventId] ?? [])
      ..removeWhere((r) => r.id == reminder.id);

    await _updateEventRemindersSafely(eventId: eventId, nextList: nextList);
    saveIgnoredDefaultReminders();
  }

  Future<void> onEventUpdated(EventModel event) async {
    final newStart = event.startDateTimeSafe;
    if (newStart == null) {
      await onEventDeleted(event.id.toString());
      return;
    }
    final eventId = event.id.toString();
    final currentList = List<ReminderEntity>.from(remindersMap[eventId] ?? []);
    final syncedList = _buildSyncedRemindersForEvent(
      event: event,
      eventId: eventId,
      eventStart: newStart,
      currentList: currentList,
    );

    await _updateEventRemindersSafely(eventId: eventId, nextList: syncedList);
  }

  Future<void> onEventDeleted(String eventId) async {
    for (final r in remindersMap[eventId] ?? []) {
      await cancelAlarmNative(r.alarmId);
    }

    remindersMap.remove(eventId);
    ignoredDefaultReminders.remove(eventId);

    saveScheduledReminders();
    saveIgnoredDefaultReminders();
  }

  ReminderEntity _buildBackendReminder({
    required String eventId,
    required DateTime eventStart,
    required ReminderEntity reminder,
  }) {
    final id = 'backend_${eventId}_${reminder.type.name}_${reminder.value}';
    final alarmId = (Object.hash(eventId, id) & 0x7FFFFFFF);

    return reminder.copyWith(
      id: id,
      source: ReminderSource.backend,
      reminderTime: ReminderEntity.calculateTime(
        eventStart,
        reminder.type,
        reminder.value,
      ),
      alarmId: alarmId == 0 ? 1 : alarmId,
    );
  }

  List<ReminderEntity> _buildSyncedRemindersForEvent({
    required EventModel event,
    required String eventId,
    required DateTime eventStart,
    required List<ReminderEntity> currentList,
  }) {
    final list = <ReminderEntity>[];

    for (final reminder in currentList) {
      if (!reminder.isCustom) continue;

      list.add(
        _normalizeReminder(
          reminder.copyWith(
            reminderTime: ReminderEntity.calculateTime(
              eventStart,
              reminder.type,
              reminder.value,
            ),
          ),
        ),
      );
    }

    for (final reminder in event.reminders) {
      list.add(
        _normalizeReminder(
          _buildBackendReminder(
            eventId: eventId,
            eventStart: eventStart,
            reminder: reminder,
          ),
        ),
      );
    }

    for (final def in defaultReminders) {
      final key = '${def.type.name}_${def.value}';
      if (ignoredDefaultReminders[eventId]?.contains(key) == true) continue;

      list.add(_normalizeReminder(def.toReminderEntity(eventId, eventStart)));
    }

    _ensureAtStartReminder(eventId, eventStart, list);
    return _normalizeReminderList(list);
  }

  ReminderEntity _normalizeReminder(ReminderEntity reminder) {
    final safeAlarmId =
        (Object.hash(reminder.eventId, reminder.id) & 0x7FFFFFFF);

    return reminder.copyWith(alarmId: safeAlarmId == 0 ? 1 : safeAlarmId);
  }

  List<ReminderEntity> _normalizeReminderList(List<ReminderEntity> reminders) {
    final normalizedById = <String, ReminderEntity>{};

    for (final reminder in reminders) {
      final normalized = _normalizeReminder(reminder);
      normalizedById[normalized.id] = normalized;
    }

    final normalizedList = normalizedById.values.toList()
      ..sort(_compareReminderEntries);

    return normalizedList;
  }

  int _compareReminderEntries(ReminderEntity a, ReminderEntity b) {
    final byTime = a.reminderTime.compareTo(b.reminderTime);
    if (byTime != 0) return byTime;

    final bySource = a.source.index.compareTo(b.source.index);
    if (bySource != 0) return bySource;

    final byType = a.type.index.compareTo(b.type.index);
    if (byType != 0) return byType;

    final byValue = a.value.compareTo(b.value);
    if (byValue != 0) return byValue;

    return a.id.compareTo(b.id);
  }

  bool _areReminderListsEquivalent(
    List<ReminderEntity> currentList,
    List<ReminderEntity> nextList,
  ) {
    final normalizedCurrent = _normalizeReminderList(currentList);
    final normalizedNext = _normalizeReminderList(nextList);

    if (normalizedCurrent.length != normalizedNext.length) {
      return false;
    }

    for (int i = 0; i < normalizedCurrent.length; i++) {
      final current = normalizedCurrent[i];
      final next = normalizedNext[i];

      if (current.id != next.id ||
          current.eventId != next.eventId ||
          current.source != next.source ||
          current.type != next.type ||
          current.value != next.value ||
          current.defaultKey != next.defaultKey ||
          current.alarmId != next.alarmId ||
          current.reminderTime.millisecondsSinceEpoch !=
              next.reminderTime.millisecondsSinceEpoch) {
        return false;
      }
    }

    return true;
  }

  Future<void> _updateEventRemindersSafely({
    required String eventId,
    required List<ReminderEntity> nextList,
  }) async {
    final currentList = List<ReminderEntity>.from(remindersMap[eventId] ?? []);
    final normalizedNext = _normalizeReminderList(nextList);

    if (_areReminderListsEquivalent(currentList, normalizedNext)) {
      return;
    }

    await _replaceEventReminders(
      eventId: eventId,
      currentList: currentList,
      nextList: normalizedNext,
    );
  }

  Future<void> _replaceEventReminders({
    required String eventId,
    required List<ReminderEntity> currentList,
    required List<ReminderEntity> nextList,
  }) async {
    for (final reminder in currentList) {
      await cancelAlarmNative(_normalizeReminder(reminder).alarmId);
    }

    if (nextList.isEmpty) {
      remindersMap.remove(eventId);
      remindersMap.refresh();
      saveScheduledReminders();
      return;
    }

    remindersMap[eventId] = [..._normalizeReminderList(nextList)];
    remindersMap.refresh();
    saveScheduledReminders();

    await _rescheduleEvent(eventId, cancelCurrentAlarms: false);
  }

  Future<void> _rescheduleEvent(
    String eventId, {
    bool cancelCurrentAlarms = true,
  }) async {
    final list = remindersMap[eventId] ?? [];

    list.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));

    for (int i = 0; i < list.length; i++) {
      final old = list[i];

      if (cancelCurrentAlarms) {
        await cancelAlarmNative(old.alarmId);
      }

      final updated = _normalizeReminder(old);

      list[i] = updated;

      await scheduleAlarmNative(updated, isLast: i == list.length - 1);
    }

    remindersMap[eventId] = [...list];
    remindersMap.refresh();
    saveScheduledReminders();
  }

  /// يضمن وجود تذكير عند بداية وقت الحدث (قبل 0 دقيقة) لاطلاق التنبيه عند البدء
  void _ensureAtStartReminder(
    String eventId,
    DateTime eventStart,
    List<ReminderEntity> list,
  ) {
    if (ignoredDefaultReminders[eventId]?.contains('minute_0') == true) return;
    final hasAtStart = list.any(
      (r) => r.type == ReminderType.minute && r.value == 0,
    );
    if (hasAtStart) return;
    final atStartId = 'at_start_$eventId';
    final safeId = (Object.hash(eventId, atStartId) & 0x7FFFFFFF) == 0
        ? 1
        : (Object.hash(eventId, atStartId) & 0x7FFFFFFF);
    list.add(
      ReminderEntity(
        id: atStartId,
        eventId: eventId,
        source: ReminderSource.default_,
        type: ReminderType.minute,
        value: 0,
        reminderTime: eventStart,
        defaultKey: 'minute_0',
        alarmId: safeId,
      ),
    );
  }

  Future<void> scheduleAlarmNative(
    ReminderEntity reminder, {
    required bool isLast,
  }) async {
    if (reminder.reminderTime.isBefore(DateTime.now())) {
      return;
    }
    final event = _events.firstWhereOrNull(
      (e) => e.id.toString() == reminder.eventId,
    );

    if (event == null || event.startDateTimeSafe == null) {
      return;
    }

    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'time': reminder.reminderTime.millisecondsSinceEpoch,
        'eventId': reminder.eventId,
        'requestCode': _toSafeRequestCode(reminder.alarmId),
        'isLast': isLast,
        'eventStartTime': event.startDateTimeSafe!.millisecondsSinceEpoch,
        'title': event.name,
        'location': event.location,
        'startTime': event.formattedStartTimeSafe,
        'snoozeMinutes': event.snoozeDurationMinutes,
      });
    } on PlatformException catch (_) {}
  }

  Future<void> cancelAlarmNative(int alarmId) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {
        'requestCode': _toSafeRequestCode(alarmId),
      });
    } on MissingPluginException catch (_) {}
  }

  /// طلب اختبار التنبيه: جدولة تنبيه واحد بعد [seconds] ثانية (لا يُحفظ مع التذكيرات)
  static const int testAlarmRequestCode = 0x7FFFFFFE;
  static const int testAlarmDelaySeconds = 10;

  Future<bool> scheduleTestAlarm({int seconds = testAlarmDelaySeconds}) async {
    final list = _events.where((e) => e.startDateTimeSafe != null).toList();
    if (list.isEmpty) return false;
    final event = list.first;

    final reminderTime = DateTime.now().add(Duration(seconds: seconds));
    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'time': reminderTime.millisecondsSinceEpoch,
        'eventId': event.id.toString(),
        'requestCode': testAlarmRequestCode,
        'isLast': true,
        'eventStartTime': event.startDateTimeSafe!.millisecondsSinceEpoch,
        'title': event.name,
        'location': event.location,
        'startTime': event.formattedStartTimeSafe,
        'snoozeMinutes': event.snoozeDurationMinutes,
      });
      return true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  void loadScheduledReminders() {
    final data = userStorage.scheduledReminders;
    if (data == null) return;

    data.forEach((eventId, list) {
      remindersMap[eventId] = (list as List).map((e) {
        final r = ReminderEntity.fromJson(e);
        return r;
      }).toList();
    });
  }

  void saveScheduledReminders() {
    userStorage.saveScheduledReminders(
      remindersMap.map(
        (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
      ),
    );
  }

  void loadIgnoredDefaultReminders() {
    final data = userStorage.ignoredDefaultReminders;
    if (data == null) return;

    ignoredDefaultReminders.value = data.map((k, v) => MapEntry(k, v.toSet()));
  }

  void saveIgnoredDefaultReminders() {
    userStorage.saveIgnoredDefaultReminders(
      ignoredDefaultReminders.map((k, v) => MapEntry(k, v.toList())),
    );
  }

  static final DefaultReminder builtInDefaultReminder = DefaultReminder(
    type: ReminderType.minute,
    value: 15,
  );

  String _defaultReminderKey(DefaultReminder reminder) {
    return '${reminder.type.name}_${reminder.value}';
  }

  List<DefaultReminder> _normalizeDefaultReminderEntries(
    Iterable<DefaultReminder> reminders,
  ) {
    final normalized = <String, DefaultReminder>{};

    for (final reminder in reminders) {
      if (reminder.value <= 0) {
        continue;
      }

      if (ReminderEntity.isReservedAtStartReminder(
        reminder.type,
        reminder.value,
      )) {
        continue;
      }

      normalized[_defaultReminderKey(reminder)] = reminder;
    }

    return normalized.values.toList();
  }

  bool _areDefaultReminderListsEquivalent(
    List<DefaultReminder> current,
    List<DefaultReminder> next,
  ) {
    if (current.length != next.length) {
      return false;
    }

    for (int i = 0; i < current.length; i++) {
      if (_defaultReminderKey(current[i]) != _defaultReminderKey(next[i])) {
        return false;
      }
    }

    return true;
  }

  void _applyLoadedDefaultReminders(
    List<DefaultReminder> reminders, {
    bool persistIfNormalized = false,
  }) {
    final normalized = _normalizeDefaultReminderEntries(reminders);
    final effective = normalized.isEmpty
        ? [builtInDefaultReminder]
        : normalized;

    defaultReminders.assignAll(effective);

    if (persistIfNormalized ||
        !_areDefaultReminderListsEquivalent(reminders, effective)) {
      saveDefaultReminders();
    }
  }

  void loadDefaultReminders() {
    final data = userStorage.defaultReminders;
    if (data != null) {
      _applyLoadedDefaultReminders(
        data.map((e) => DefaultReminder.fromJson(e)).toList(),
      );
      return;
    }

    final legacyData = storage.read<List<dynamic>>(
      StorageKeys.legacyDefaultReminders,
    );
    if (legacyData != null && legacyData.isNotEmpty) {
      _applyLoadedDefaultReminders(
        legacyData.map((e) => DefaultReminder.fromJson(e)).toList(),
        persistIfNormalized: true,
      );
      storage.remove(StorageKeys.legacyDefaultReminders);
    } else {
      defaultReminders.assignAll([builtInDefaultReminder]);
      saveDefaultReminders();
    }
  }

  void saveDefaultReminders() {
    userStorage.saveDefaultReminders(
      defaultReminders.map((e) => e.toJson()).toList(),
    );
  }

  String formatReminderLabel(ReminderEntity r) {
    final value = DateLocalizationHelper.localizeDigits('${r.value}');
    switch (r.type) {
      case ReminderType.day:
        return '${AppTexts.before} $value ${AppTexts.day}';
      case ReminderType.hours:
        return '${AppTexts.before} $value ${AppTexts.hour}';
      case ReminderType.minute:
        if (r.value == 0) return AppTexts.reminderAtEventTime;
        return '${AppTexts.before} $value ${AppTexts.minute}';
    }
  }

  String formatRemainingCountdown(DateTime reminderTime, {DateTime? now}) {
    now ??= DateTime.now();
    if (reminderTime.isBefore(now)) return '⛔ ${AppTexts.finish}';

    final diff = reminderTime.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;

    final parts = <String>[];
    if (h > 0) {
      parts.add('${DateLocalizationHelper.twoDigits(h)} ${AppTexts.hour}');
    }
    if (m > 0 || h > 0) {
      parts.add('${DateLocalizationHelper.twoDigits(m)} ${AppTexts.minute}');
    }
    parts.add('${DateLocalizationHelper.twoDigits(s)} ${AppTexts.second}');

    return '⏳ ${AppTexts.after} ${parts.join(' : ')}';
  }
}

/// عنصر لعرض تنبيه مجدول مع بيانات الحدث
class ScheduledReminderInfo {
  final ReminderEntity reminder;
  final EventModel? event;

  ScheduledReminderInfo({required this.reminder, this.event});
}
