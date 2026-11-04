import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

  /// AlarmKit (iOS 26+) في ios/Runner/EventAlarmKit.swift.
  static const MethodChannel _alarmKit = MethodChannel('ios_alarmkit');

  /// يحاول جدولة منبّه نظام حقيقي عبر AlarmKit. يُرجع false على iOS < 26 أو
  /// إذا رفض المستخدم الإذن، فنرجع للإشعار المحلي.
  static Future<bool> _tryAlarmKit({
    required int requestCode,
    required DateTime at,
    required String title,
    required String location,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final ok = await _alarmKit.invokeMethod<bool>('schedule', {
        'requestCode': requestCode,
        'time': at.millisecondsSinceEpoch,
        'title': title,
        'location': location,
        'eventStartTime': payload['eventStartTime'] ?? 0,
      });
      return ok ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[AlarmSync][iOS] AlarmKit فشل: $e');
      return false;
    }
  }

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
    if (await _tryAlarmKit(
      requestCode: requestCode,
      at: at,
      title: title,
      location: location,
      payload: payload,
    )) {
      // نلغي أي إشعار قديم لنفس المنبّه كي لا يرنّ مرتين.
      await _cancelChain(requestCode);
      debugPrint(
        '[AlarmSync][iOS][AlarmKit] تمت جدولة requestCode=$requestCode title=$title at=$at',
      );
      return;
    }
    await _scheduleNotificationChain(
      requestCode: requestCode,
      at: at,
      title: title,
      location: location,
      payload: payload,
    );
  }

  // ---------------------------------------------------------------------------
  // iOS < 26: إشعار واحد بنغمة المنبّه (~28 ثانية، حد iOS 30).
  //
  // الضغط عليه أو فتح التطبيق أثناءه يفتح شاشة المنبّه التي تكمل الرنين داخل
  // التطبيق. وإن وصل والتطبيق مفتوح، تُفتح الشاشة مباشرة (AppDelegate.willPresent).
  // ---------------------------------------------------------------------------

  /// كم يبقى المنبّه "يرنّ" بعد وقته لأغراض فتح الشاشة عند رجوع التطبيق.
  static const Duration _ringWindow = Duration(minutes: 5);

  /// نسخة تجريبية سابقة كانت تجدول 8 إشعارات متتالية؛ نُبقي معرّفاتها فقط
  /// للتنظيف كي لا يبقى منها شيء على أجهزة الاختبار.
  static const int _legacyChainLength = 8;
  static int _chainId(int requestCode, int index) =>
      index == 0 ? requestCode : ((requestCode * 31 + index) & 0x7FFFFFFF);

  static Future<void> _scheduleNotificationChain({
    required int requestCode,
    required DateTime at,
    required String title,
    required String location,
    required Map<String, dynamic> payload,
  }) async {
    await _cancelChain(requestCode);

    await _plugin.zonedSchedule(
      requestCode,
      title,
      location.isNotEmpty ? location : null,
      tz.TZDateTime.from(at, tz.local),
      NotificationDetails(
        // ios/Runner/event_alarm.caf: نغمة منبّه مميزة خاصة بالتطبيق.
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'event_alarm.caf',
          interruptionLevel: InterruptionLevel.timeSensitive,
          threadIdentifier: 'event_alarm_$requestCode',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode({...payload, 'fireAt': at.millisecondsSinceEpoch}),
    );
    debugPrint(
      '[AlarmSync][iOS] تمت جدولة requestCode=$requestCode title=$title at=$at',
    );
  }

  /// يلغي إشعار المنبّه (المجدول والمعروض في مركز الإشعارات).
  static Future<void> _cancelChain(int requestCode) async {
    for (var i = 0; i < _legacyChainLength; i++) {
      await _plugin.cancel(_chainId(requestCode, i));
    }
  }

  /// يزيل إشعار المنبّه من مركز الإشعارات: يُستدعى عند فتح شاشة المنبّه.
  static Future<void> stopRinging(int requestCode) async {
    if (requestCode == 0) return;
    await _cancelChain(requestCode);
    debugPrint('[AlarmRing][iOS] أُزيل إشعار requestCode=$requestCode');
  }

  /// يجد منبّهاً وصل خلال آخر [_ringWindow] ولم يُتعامل معه، يزيل إشعاره ويُرجع
  /// حمولته كي تُفتح شاشة المنبّه (التي تكمل الرنين داخل التطبيق).
  static Future<Map<String, dynamic>?> stopStartedChains() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final started = <int, Map<String, dynamic>>{};

    void collect(String? raw) {
      if (raw == null || raw.isEmpty) return;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['kind'] != 'event_alarm') return;
        final fireAt = (data['fireAt'] as num?)?.toInt();
        final rc = (data['requestCode'] as num?)?.toInt();
        if (fireAt != null &&
            rc != null &&
            fireAt <= now &&
            now - fireAt <= _ringWindow.inMilliseconds) {
          started[rc] = data;
        }
      } catch (_) {}
    }

    for (final p in await _plugin.pendingNotificationRequests()) {
      collect(p.payload);
    }
    try {
      for (final a in await _plugin.getActiveNotifications()) {
        collect(a.payload);
      }
    } catch (_) {}

    Map<String, dynamic>? latest;
    for (final entry in started.entries) {
      await stopRinging(entry.key);
      final fireAt = (entry.value['fireAt'] as num).toInt();
      if (latest == null || fireAt > (latest['fireAt'] as num).toInt()) {
        latest = entry.value;
      }
    }
    return latest;
  }

  static AppLifecycleListener? _lifecycleListener;

  /// عند رجوع التطبيق للواجهة (حتى بدون الضغط على الإشعار)، أو وصول المنبّه
  /// والتطبيق مفتوح: يمرّر حمولة المنبّه لـ [onAlarmStarted] لفتح شاشة المنبّه.
  static void attachLifecycle(
    void Function(Map<String, dynamic> payload) onAlarmStarted,
  ) {
    if (_lifecycleListener != null) return;
    Future<void> check() async {
      final payload = await stopStartedChains();
      if (payload != null) onAlarmStarted(payload);
    }

    _lifecycleListener = AppLifecycleListener(onResume: check);
    // AppDelegate يرسل `alarmPresented` حين يصل إشعار منبّه والتطبيق في الواجهة.
    _alarmKit.setMethodCallHandler((call) async {
      if (call.method != 'alarmPresented') return;
      final raw = call.arguments as String?;
      if (raw == null) return;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['kind'] != 'event_alarm') return;
        await stopRinging((data['requestCode'] as num?)?.toInt() ?? 0);
        onAlarmStarted(data);
      } catch (_) {}
    });
    check();
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

  /// يستقبل نفس خريطة `scheduleAlarm` التي تُرسل لقناة أندرويد الأصلية.
  static Future<void> scheduleFromNativeMap(Map<String, dynamic> map) async {
    final rc = (map['requestCode'] as num?)?.toInt();
    final timeMs = (map['time'] as num?)?.toInt();
    if (rc == null || timeMs == null) return;
    final title = map['title'] as String? ?? '⏰ تذكير';
    final location = map['location'] as String? ?? '';
    await _scheduleAt(
      requestCode: rc,
      at: DateTime.fromMillisecondsSinceEpoch(timeMs),
      title: title,
      location: location,
      payload: _payloadFor(
        eventId: int.tryParse(map['eventId']?.toString() ?? '') ?? 0,
        requestCode: rc,
        eventStartTimeMs: (map['eventStartTime'] as num?)?.toInt() ?? 0,
        title: title,
        location: location,
        startTime: map['startTime'] as String? ?? '',
        snoozeMinutes: (map['snoozeMinutes'] as num?)?.toInt() ?? 0,
      ),
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
    try {
      await _alarmKit.invokeMethod<void>('cancel', {'requestCode': requestCode});
    } catch (_) {}
    await _cancelChain(requestCode);
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
