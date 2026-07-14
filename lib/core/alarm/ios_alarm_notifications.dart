import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mow_events/core/alarm/event_alarm_service.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:timezone/timezone.dart' as tz;

/// جدولة منبّهات iOS عبر إشعارات محلية مجدولة (`flutter_local_notifications`).
///
/// لا يستدعي `.initialize()` هنا عمداً: النسخة الوحيدة المُهيَّأة من
/// [FlutterLocalNotificationsPlugin] مملوكة لـ `NotificationsController` كي لا
/// يتضارب استدعاءان مع بعض على نفس الـ callback الأصلي (native singleton).
class IosEventAlarmNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Map<String, dynamic> _payloadFor({
    required int eventId,
    required int requestCode,
    required int eventStartTimeMs,
    required String title,
    required String location,
    required String startTime,
    required int snoozeMinutes,
  }) {
    return {
      'kind': 'event_alarm',
      'eventId': eventId.toString(),
      'requestCode': requestCode,
      'eventStartTime': eventStartTimeMs,
      'title': title,
      'location': location,
      'startTime': startTime,
      'snoozeMinutes': snoozeMinutes,
    };
  }

  static Future<void> _scheduleAt({
    required int requestCode,
    required DateTime at,
    required String title,
    required String location,
    required Map<String, dynamic> payload,
  }) async {
    await _plugin.zonedSchedule(
      requestCode,
      title,
      location.isNotEmpty ? location : null,
      tz.TZDateTime.from(at, tz.local),
      const NotificationDetails(
        // لا يوجد ملف صوت مخصّص (.caf/.wav) مُضاف لمشروع Xcode بعد؛ نعتمد الصوت
        // الافتراضي لنظام iOS حتى تتوفر أداة تحويل الصوت وتضاف عبر Xcode لاحقاً.
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(payload),
    );
    debugPrint(
      '[AlarmSync][iOS] تمت جدولة requestCode=$requestCode title=$title at=$at',
    );
  }

  static Future<void> scheduleForEvent(EventModel e, DateTime at) async {
    final rc = EventAlarmService.requestCodeForEvent(e.id);
    final payload = _payloadFor(
      eventId: e.id,
      requestCode: rc,
      eventStartTimeMs: e.startDateTimeSafe?.millisecondsSinceEpoch ?? 0,
      title: e.name,
      location: e.location,
      startTime: e.formattedStartTimeSafe,
      snoozeMinutes: e.snoozeDurationMinutes,
    );
    await _scheduleAt(
      requestCode: rc,
      at: at,
      title: e.name,
      location: e.location,
      payload: payload,
    );
  }

  static Future<void> scheduleSnooze(
    Map<String, dynamic> payload,
    DateTime at,
  ) async {
    final rc = (payload['requestCode'] as num?)?.toInt();
    if (rc == null) return;
    await _scheduleAt(
      requestCode: rc,
      at: at,
      title: payload['title'] as String? ?? '⏰ تذكير',
      location: payload['location'] as String? ?? '',
      payload: payload,
    );
  }

  static Future<void> cancel(int requestCode) async {
    await _plugin.cancel(requestCode);
    debugPrint('[AlarmCancel][iOS] تم إلغاء requestCode=$requestCode');
  }

  /// يطبع كل الإشعارات المجدولة حالياً على iOS (للتحقق من التزامن).
  static Future<void> logPendingNotifications(String tag) async {
    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('[AlarmSnapshot][iOS][$tag] عدد المجدولة: ${pending.length}');
    for (final p in pending) {
      debugPrint(
        '[AlarmSnapshot][iOS][$tag]  - id=${p.id} title=${p.title} payload=${p.payload}',
      );
    }
  }
}
