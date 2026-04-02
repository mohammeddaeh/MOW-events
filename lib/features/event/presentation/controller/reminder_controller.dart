import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/local_storage/UserStorage/user_storage.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
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

  List<ReminderEntity> getReminders(String eventId) =>
      remindersMap[eventId]?.toList() ?? [];

  /// كل التنبيهات المجدولة لجميع الأحداث مرتبة حسب وقت التنبيه (لعرضها في الشاشة اليومية)
  List<ScheduledReminderInfo> getAllScheduledRemindersSorted() {
    final List<ScheduledReminderInfo> result = [];
    for (final entry in remindersMap.entries) {
      final eventId = entry.key;
      final event = _events.firstWhereOrNull(
        (e) => e.id.toString() == eventId,
      );
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
    final list = remindersMap.putIfAbsent(eventId, () => []);
    switch (action) {
      case ReminderAction.add:
        if (reminder == null) return;
        final safeId =
            (Object.hash(reminder.eventId, reminder.id) & 0x7FFFFFFF);
        final safeReminder = reminder.copyWith(
          alarmId: safeId == 0 ? 1 : safeId,
        );
        list.add(safeReminder);
        await scheduleAlarmNative(safeReminder, isLast: false);

        break;

      case ReminderAction.update:
        if (reminder == null) return;
        final index = list.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          final oldReminder = list[index];
          await cancelAlarmNative(oldReminder.alarmId);
          final safeId =
              (Object.hash(reminder.eventId, reminder.id) & 0x7FFFFFFF);
          final safeReminder = reminder.copyWith(
            alarmId: safeId == 0 ? 1 : safeId,
          );
          list[index] = safeReminder;
          await scheduleAlarmNative(safeReminder, isLast: false);
        }

        break;

      case ReminderAction.remove:
        if (reminder == null) return;
        list.removeWhere((r) => r.id == reminder.id);
        await cancelAlarmNative(reminder.alarmId);
        break;
    }

    remindersMap[eventId] = [...list];
    remindersMap.refresh();
    saveScheduledReminders();
  }

  /// إضافة تذكير افتراضي. إذا [applyToAllEvents] = true يُحمَّل كل الأحداث من السيرفر ثم يُطبَّق على الجميع.
  /// إذا [applyToAllEvents] = false يُطبَّق على الأحداث المستقبلية فقط (التي لم تبدأ بعد).
  Future<void> addDefaultReminder(
    DefaultReminder reminder, {
    bool applyToAllEvents = false,
  }) async {
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
      final list = remindersMap[eventId] ?? [];

      if (oldKey != null) {
        final toRemove = list
            .where(
              (r) =>
                  r.source == ReminderSource.default_ &&
                  r.defaultKey == oldKey,
            )
            .toList();
        for (final r in toRemove) await cancelAlarmNative(r.alarmId);
        list.removeWhere(
          (r) => r.source == ReminderSource.default_ && r.defaultKey == oldKey,
        );
        ignoredDefaultReminders[eventId]?.remove(oldKey);
      }

      if (ignoredDefaultReminders[eventId]?.contains(key) == true) continue;

      final exists = list.any(
        (r) => r.source == ReminderSource.default_ && r.defaultKey == key,
      );

      if (!exists) {
        list.add(def.toReminderEntity(eventId, start));
        remindersMap[eventId] = [...list];
        remindersMap.refresh();
        await _rescheduleEvent(eventId);
      }
    }

    saveScheduledReminders();
  }

  void updateDefaultReminder(
    int index,
    ReminderType type,
    int value, {
    required bool applyToAllEvents,
  }) async {
    if (index < 0 || index >= defaultReminders.length) return;

    final old = defaultReminders[index];
    final updated = old.copyWith(type: type, value: value);
    final keyOld = '${old.type.name}_${old.value}';

    defaultReminders[index] = updated;
    saveDefaultReminders();

    final now = DateTime.now();

    for (final event in _events) {
      final start = event.startDateTimeSafe;
      if (start == null) continue;
      final eventId = event.id.toString();
      final list = remindersMap[eventId] ?? [];

      if (applyToAllEvents) {
        final toUpdate = list
            .where(
              (r) =>
                  r.source == ReminderSource.default_ &&
                  r.defaultKey == keyOld &&
                  ignoredDefaultReminders[eventId]?.contains(keyOld) != true,
            )
            .toList();

        for (final r in toUpdate) await cancelAlarmNative(r.alarmId);
        for (final r in toUpdate) {
          list.remove(r);
          list.add(updated.toReminderEntity(eventId, start));
        }

        if (toUpdate.isNotEmpty) {
          await _rescheduleEvent(eventId);
          saveScheduledReminders();
        }
      } else {
        if (start.isAfter(now)) {
          final hasOld = list.any(
            (r) =>
                r.source == ReminderSource.default_ &&
                r.defaultKey == keyOld &&
                ignoredDefaultReminders[eventId]?.contains(keyOld) != true,
          );
          if (hasOld) {
            final toUpdateSingle = list
                .where(
                  (r) =>
                      r.source == ReminderSource.default_ &&
                      r.defaultKey == keyOld &&
                      ignoredDefaultReminders[eventId]?.contains(keyOld) != true,
                )
                .toList();
            for (final r in toUpdateSingle) await cancelAlarmNative(r.alarmId);
            for (final r in toUpdateSingle) list.remove(r);
            list.add(updated.toReminderEntity(eventId, start));
            await _rescheduleEvent(eventId);
          } else {
            final exists = list.any(
              (r) =>
                  r.source == ReminderSource.default_ &&
                  r.defaultKey == '${updated.type.name}_${updated.value}',
            );
            if (!exists) {
              list.add(updated.toReminderEntity(eventId, start));
              await _rescheduleEvent(eventId);
            }
          }
        }
      }

      remindersMap[eventId] = [...list];
    }

    remindersMap.refresh();
    saveScheduledReminders();
  }

  void removeDefaultReminder(int index, {bool applyToAllEvents = false}) async {
    if (index < 0 || index >= defaultReminders.length) return;

    final removed = defaultReminders.removeAt(index);
    final key = '${removed.type.name}_${removed.value}';

    saveDefaultReminders();

    final now = DateTime.now();

    for (final entry in remindersMap.entries) {
      final eventId = entry.key;
      final list = entry.value;

      final event = _events.firstWhereOrNull((e) => e.id.toString() == eventId);

      if (event == null || event.startDateTimeSafe == null) {
        continue;
      }

      final eventStart = event.startDateTimeSafe!;

      if (applyToAllEvents || eventStart.isAfter(now)) {
        ignoredDefaultReminders.putIfAbsent(eventId, () => {}).add(key);

        final toRemoveCount = list
            .where(
              (r) => r.source == ReminderSource.default_ && r.defaultKey == key,
            )
            .length;

        for (final r in list.where(
          (r) => r.source == ReminderSource.default_ && r.defaultKey == key,
        )) {
          await cancelAlarmNative(r.alarmId);
        }

        list.removeWhere(
          (r) => r.source == ReminderSource.default_ && r.defaultKey == key,
        );

        if (toRemoveCount > 0) {}

        remindersMap[eventId] = [...list];
      }
    }

    remindersMap.refresh();
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
      if (event.startDateTimeSafe == null) continue;
      final eventId = event.id.toString();

      if (remindersMap.containsKey(eventId)) continue;

      final List<ReminderEntity> initial = [];

      for (final r in event.reminders) {
        initial.add(
          r.copyWith(
            id: UniqueKey().toString(),
            source: ReminderSource.backend,
          ),
        );
      }

      for (final def in defaultReminders) {
        final key = '${def.type.name}_${def.value}';
        if (ignoredDefaultReminders[eventId]?.contains(key) == true) continue;

        initial.add(def.toReminderEntity(eventId, event.startDateTimeSafe!));
      }

      _ensureAtStartReminder(eventId, event.startDateTimeSafe!, initial);
      remindersMap[eventId] = initial;
      await _rescheduleEvent(eventId);
      if (initial.isNotEmpty) anyScheduled = true;
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
    if (event.startDateTimeSafe == null) return;
    final eventId = event.id.toString();

    final List<ReminderEntity> initial = [];

    for (final def in defaultReminders) {
      final key = '${def.type.name}_${def.value}';
      if (ignoredDefaultReminders[eventId]?.contains(key) == true) continue;

      initial.add(def.toReminderEntity(eventId, event.startDateTimeSafe!));
    }

    for (final r in event.reminders) {
      initial.add(
        r.copyWith(id: UniqueKey().toString(), source: ReminderSource.backend),
      );
    }

    _ensureAtStartReminder(eventId, event.startDateTimeSafe!, initial);
    remindersMap[eventId] = initial;
    saveScheduledReminders();
    await _rescheduleEvent(eventId);
  }

  void ignoreDefaultReminder(String eventId, ReminderEntity reminder) async {
    ignoredDefaultReminders
        .putIfAbsent(eventId, () => {})
        .add(reminder.defaultKey!);

    await cancelAlarmNative(reminder.alarmId);

    remindersMap[eventId]?.removeWhere((r) => r.id == reminder.id);

    remindersMap.refresh();
    saveIgnoredDefaultReminders();
    saveScheduledReminders();
  }

  Future<void> onEventUpdated(EventModel event) async {
    final newStart = event.startDateTimeSafe;
    if (newStart == null) {
      await onEventDeleted(event.id.toString());
      return;
    }
    final eventId = event.id.toString();

    final list = List<ReminderEntity>.from(remindersMap[eventId] ?? []);

    for (final r in event.reminders) {
      final exists = list.any(
        (e) =>
            e.type == r.type &&
            e.value == r.value &&
            e.source == ReminderSource.backend,
      );
      if (!exists) {
        final safeId = (Object.hash(eventId, r.id) & 0x7FFFFFFF) == 0
            ? 1
            : (Object.hash(eventId, r.id) & 0x7FFFFFFF);
        list.add(
          ReminderEntity(
            id: UniqueKey().toString(),
            eventId: eventId,
            source: ReminderSource.backend,
            type: r.type,
            value: r.value,
            reminderTime: ReminderEntity.calculateTime(
              newStart,
              r.type,
              r.value,
            ),
            defaultKey: r.defaultKey,
            alarmId: safeId,
          ),
        );
      }
    }

    for (int i = 0; i < list.length; i++) {
      final r = list[i];
      list[i] = r.copyWith(
        reminderTime: ReminderEntity.calculateTime(newStart, r.type, r.value),
      );
    }
    for (final def in defaultReminders) {
      final key = '${def.type.name}_${def.value}';

      if (ignoredDefaultReminders[eventId]?.contains(key) == true) continue;

      final exists = list.any(
        (r) => r.source == ReminderSource.default_ && r.defaultKey == key,
      );

      if (!exists) {
        list.add(def.toReminderEntity(eventId, newStart));
      }
    }

    _ensureAtStartReminder(eventId, newStart, list);
    remindersMap[eventId] = [...list];
    remindersMap.refresh();
    saveScheduledReminders();

    await _rescheduleEvent(eventId);
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

  Future<void> _rescheduleEvent(String eventId) async {
    final list = remindersMap[eventId] ?? [];

    list.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));

    for (int i = 0; i < list.length; i++) {
      final old = list[i];

      await cancelAlarmNative(old.alarmId);

      final uniqueAlarmId = (Object.hash(old.eventId, old.id) & 0x7FFFFFFF);
      final safeAlarmId = uniqueAlarmId == 0 ? 1 : uniqueAlarmId;
      final updated = old.copyWith(alarmId: safeAlarmId);

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
    final list =
        _events.where((e) => e.startDateTimeSafe != null).toList();
    if (list.isEmpty) return false;
    final event = list.first;

    final reminderTime =
        DateTime.now().add(Duration(seconds: seconds));
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

  void loadDefaultReminders() {
    final data = storage.read<List<dynamic>>('default_reminders');
    if (data != null && data.isNotEmpty) {
      defaultReminders.assignAll(
        data.map((e) => DefaultReminder.fromJson(e)).toList(),
      );
    } else {
      defaultReminders.assignAll([builtInDefaultReminder]);
      saveDefaultReminders();
    }
  }

  void saveDefaultReminders() {
    storage.write(
      'default_reminders',
      defaultReminders.map((e) => e.toJson()).toList(),
    );
  }

  String formatReminderLabel(ReminderEntity r) {
    switch (r.type) {
      case ReminderType.day:
        return '${AppTexts.before} ${r.value} ${AppTexts.day}';
      case ReminderType.hour:
        return '${AppTexts.before} ${r.value} ${AppTexts.hour}';
      case ReminderType.minute:
        return '${AppTexts.before} ${r.value} ${AppTexts.minute}';
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
    if (h > 0) parts.add('${h.toString().padLeft(2, '0')} ${AppTexts.hour}');
    if (m > 0 || h > 0) {
      parts.add('${m.toString().padLeft(2, '0')} ${AppTexts.minute}');
    }
    parts.add('${s.toString().padLeft(2, '0')} ${AppTexts.second}');

    return '⏳ ${AppTexts.after} ${parts.join(' : ')}';
  }
}

/// عنصر لعرض تنبيه مجدول مع بيانات الحدث
class ScheduledReminderInfo {
  final ReminderEntity reminder;
  final EventModel? event;

  ScheduledReminderInfo({required this.reminder, this.event});
}
