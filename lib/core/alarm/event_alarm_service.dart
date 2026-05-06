import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/alarm/android_alarm_permissions.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

/// جدولة منبّهات ملء الشاشة (أندرويد أصلي) للأحداث — لا تعتمد على Push.
///
/// تستخدم [MethodChannel] `alarm_channel` مع [AlarmScheduler]؛ عند الإطلاق تظهر
/// [AlarmScreen] داخل [FullScreenAlarmActivity] مع قناة `alarm_ringing_channel`.
class EventAlarmService extends GetxService {
  static EventAlarmService get to => Get.find();

  static const MethodChannel _channel = MethodChannel('alarm_channel');

  /// مساحة طلبات مميزة عن تذكيرات [ReminderController] (hash مختلف).
  static int requestCodeForEvent(int eventId) {
    final h = Object.hash(0xEAE10E71, eventId) & 0x7FFFFFFF;
    return h == 0 ? 1 : h;
  }

  final Set<int> _trackedRequestCodes = {};

  bool get _nativeAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// مزامنة كاملة: يلغي المنبّهات غير المطلوبة ويجدول المفعّلة في المستقبل.
  Future<void> syncFromEvents(List<EventModel> events) async {
    if (!_nativeAvailable) return;

    final now = DateTime.now();
    final entries = <Map<String, dynamic>>[];
    final nextCodes = <int>{};

    for (final e in events) {
      if (!e.isAlarmEnabled) continue;
      final at = e.effectiveNativeAlarmTime;
      if (at == null || !at.isAfter(now)) continue;

      final rc = requestCodeForEvent(e.id);
      nextCodes.add(rc);
      final startMs = e.startDateTimeSafe?.millisecondsSinceEpoch ?? 0;

      final map = <String, dynamic>{
        'time': at.millisecondsSinceEpoch,
        'eventId': e.id.toString(),
        'requestCode': rc,
        'eventStartTime': startMs,
        'title': e.name,
        'location': e.location,
        'startTime': e.formattedStartTimeSafe,
        'snoozeMinutes': e.snoozeDurationMinutes,
        'isLast': true,
      };
      entries.add(map);

      try {
        await _channel.invokeMethod<void>('scheduleAlarm', map);
      } catch (err) {
        debugPrint('EventAlarmService.scheduleAlarm: $err');
      }
    }

    for (final old in _trackedRequestCodes.difference(nextCodes)) {
      try {
        await _channel.invokeMethod<void>('cancelAlarm', {'requestCode': old});
      } catch (_) {}
    }
    _trackedRequestCodes
      ..clear()
      ..addAll(nextCodes);

    try {
      await _channel.invokeMethod<void>('setAlarmScheduleSnapshot', {
        'json': jsonEncode(entries),
      });
    } catch (err) {
      debugPrint('EventAlarmService.setAlarmScheduleSnapshot: $err');
    }
  }

  /// دمج الحدث مع قائمة [HomeController] عند توفرها ليبقى لقطة التخزين متسقة.
  Future<void> scheduleEvent(EventModel e) async {
    if (Get.isRegistered<HomeController>()) {
      final hc = Get.find<HomeController>();
      final list = hc.allEvents.map((m) => m.id == e.id ? e : m).toList();
      if (!list.any((m) => m.id == e.id)) {
        list.add(e);
      }
      await syncFromEvents(list);
      return;
    }
    await syncFromEvents([e]);
  }

  Future<void> cancelForEventId(int eventId) async {
    if (!_nativeAvailable) return;
    final rc = requestCodeForEvent(eventId);
    _trackedRequestCodes.remove(rc);
    try {
      await _channel.invokeMethod<void>('cancelAlarm', {'requestCode': rc});
    } catch (_) {}
  }

  /// إعادة جدولة كل الأحداث المحمّلة (مثلاً بعد تغيير المنطقة الزمنية يدوياً).
  Future<void> rescheduleAll(List<EventModel> events) async {
    await syncFromEvents(events);
  }

  // --- وقت التشغيل: صلاحيات المنبّه (أندرويد) ---

  Future<AlarmRuntimeStatus?> getAlarmRuntimeStatus() async {
    if (!_nativeAvailable) return null;
    return queryAlarmRuntimeStatus();
  }

  Future<bool> canScheduleExactAlarms() async {
    if (!_nativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('canScheduleExactAlarms') ??
          true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> canUseFullScreenIntent() async {
    if (!_nativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('canUseFullScreenIntent') ??
          true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_nativeAvailable) return true;
    try {
      return await _channel.invokeMethod<bool>('areNotificationsEnabled') ??
          true;
    } catch (_) {
      return true;
    }
  }

  Future<void> openExactAlarmSettings() async {
    if (!_nativeAvailable) return;
    await openAndroidExactAlarmSettings();
  }

  Future<void> openFullScreenIntentSettings() async {
    if (!_nativeAvailable) return;
    await openAndroidFullScreenIntentSettings();
  }

  Future<void> openNotificationSettings() async {
    if (!_nativeAvailable) return;
    await openAndroidNotificationSettings();
  }
}
