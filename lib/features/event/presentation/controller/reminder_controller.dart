import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/utils/local_storage/UserStorage/user_storage.dart';
import 'package:mow_events/core/utils/local_storage/app_local_storage.dart';
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
        list.add(reminder);
        await scheduleAlarmNative(reminder, isLast: false);

        break;

      case ReminderAction.update:
        if (reminder == null) return;
        final index = list.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          final oldReminder = list[index];
          list[index] = reminder;
          await cancelAlarmNative(oldReminder.alarmId);
          await scheduleAlarmNative(reminder, isLast: false);
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

  void addDefaultReminder(
    DefaultReminder reminder, {
    bool applyToAllEvents = false,
  }) {
    defaultReminders.add(reminder);
    saveDefaultReminders();

    if (applyToAllEvents) {
      applySingleDefaultToAllEvents(reminder);
    }
  }

  Future<void> applySingleDefaultToAllEvents(
    DefaultReminder def, {
    String? oldKey,
  }) async {
    final key = '${def.type.name}_${def.value}';

    for (final event in _events) {
      final eventId = event.id.toString();
      final list = remindersMap[eventId] ?? [];

      if (oldKey != null) {
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
        list.add(def.toReminderEntity(eventId, event.startDateTimeSafe!));
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
      final eventId = event.id.toString();
      final start = event.startDateTimeSafe!;
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

        for (final r in toUpdate) {
          list.remove(r);
          list.add(updated.toReminderEntity(eventId, start));
        }

        if (toUpdate.isNotEmpty) {
          await _rescheduleEvent(eventId);
        }
      } else {
        if (start.isAfter(now)) {
          final exists = list.any(
            (r) =>
                r.source == ReminderSource.default_ &&
                r.defaultKey == keyOld &&
                ignoredDefaultReminders[eventId]?.contains(keyOld) != true,
          );
          if (!exists) {
            list.add(updated.toReminderEntity(eventId, start));
            await _rescheduleEvent(eventId);
          }
        } else {}
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
        continue; // 👈 يمنع الكراش
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

  Future<void> onEventsLoaded(List<EventModel> events) async {
    for (final event in events) {
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

      remindersMap[eventId] = initial;
      await _rescheduleEvent(eventId);
    }

    saveScheduledReminders();
  }

  void onEventAdded(EventModel event) async {
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

  void onEventUpdated(EventModel event) async {
    final eventId = event.id.toString();

    final newStart = event.startDateTimeSafe;

    final list = remindersMap[eventId] ?? [];
    for (int i = 0; i < list.length; i++) {
      final r = list[i];
      list[i] = r.copyWith(
        reminderTime: ReminderEntity.calculateTime(newStart!, r.type, r.value),
      );
    }
    for (final def in defaultReminders) {
      final key = '${def.type.name}_${def.value}';

      if (ignoredDefaultReminders[eventId]?.contains(key) == true) continue;

      final exists = list.any(
        (r) => r.source == ReminderSource.default_ && r.defaultKey == key,
      );

      if (!exists) {
        list.add(def.toReminderEntity(eventId, newStart!));
      }
    }
    remindersMap[eventId] = [...list];
    remindersMap.refresh();
    saveScheduledReminders();

    await _rescheduleEvent(eventId);
  }

  void onEventDeleted(String eventId) async {
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

      final updated = old.copyWith(alarmId: UniqueKey().hashCode);

      list[i] = updated;

      await scheduleAlarmNative(updated, isLast: i == list.length - 1);
    }

    remindersMap[eventId] = [...list];
    remindersMap.refresh();
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
      print('Cannot schedule alarm: event start time is null');
      return;
    }

    await _channel.invokeMethod('scheduleAlarm', {
      'time': reminder.reminderTime.millisecondsSinceEpoch,
      'eventId': reminder.eventId,
      'requestCode': reminder.alarmId,
      'isLast': isLast,
      'eventStartTime': event.startDateTimeSafe!.millisecondsSinceEpoch,
      'title': event.name,
      'location': event.location,
      'startTime': event.formattedStartTimeSafe,
    });
  }

  Future<void> cancelAlarmNative(int alarmId) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'requestCode': alarmId});
    } on MissingPluginException catch (_) {}
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

  void loadDefaultReminders() {
    final data = storage.read<List<dynamic>>('default_reminders');
    if (data != null) {
      defaultReminders.assignAll(
        data.map((e) => DefaultReminder.fromJson(e)).toList(),
      );
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
