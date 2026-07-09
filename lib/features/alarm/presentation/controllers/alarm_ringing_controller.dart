import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/core/alarm/ios_alarm_notifications.dart';
import 'package:mow_events/core/alarm/ios_alarm_sound_player.dart';
import 'package:mow_events/features/alarm/domain/alarm_snooze_policy.dart';

/// حالة منبّه ملء الشاشة — يقرأ الحمولة من الأصلي وينفّذ إغلاق/تأجيل.
class AlarmRingingController extends GetxController {
  static const MethodChannel _channel = MethodChannel('alarm_ringing_channel');

  final Rxn<Map<String, dynamic>> payload = Rxn();
  final RxString clockLabel = ''.obs;

  /// يُحدَّث دورياً لإعادة تقييم [snoozeAllowed] قرب حدود الـ 5 دقائق.
  final RxInt policyTick = 0.obs;

  Timer? _clockTimer;
  Timer? _policyTimer;

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  int get requestCode =>
      (payload.value?['requestCode'] as num?)?.toInt() ?? 0;

  String get title => payload.value?['title'] as String? ?? '⏰ تذكير';
  String get location => payload.value?['location'] as String? ?? '';
  String get startTimeLabel => payload.value?['startTime'] as String? ?? '';

  int get eventStartTimeMs =>
      (payload.value?['eventStartTime'] as num?)?.toInt() ?? 0;

  bool get snoozeAllowed {
    policyTick.value;
    final ms = eventStartTimeMs;
    if (ms <= 0) return false;
    final eventStart = DateTime.fromMillisecondsSinceEpoch(ms);
    return AlarmSnoozePolicy.checkIfSnoozeAllowed(
      eventStart: eventStart,
      now: DateTime.now(),
    );
  }

  @override
  void onInit() {
    super.onInit();
    scheduleMicrotask(_loadPayload);
    _startClock();
    _policyTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      policyTick.value++;
    });
    if (_isIos) {
      IosAlarmSoundPlayer.start();
    }
  }

  Future<void> _loadPayload() async {
    if (_isIos) {
      final args = Get.arguments;
      payload.value = args is Map ? Map<String, dynamic>.from(args) : {};
      return;
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>('getPayload');
      if (raw is Map) {
        payload.value = Map<String, dynamic>.from(raw);
      }
    } catch (_) {
      payload.value = {};
    }
  }

  void _startClock() {
    void tick() {
      final fmt = DateFormat('HH:mm');
      clockLabel.value = fmt.format(DateTime.now());
    }

    tick();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> stopNativeRinging() async {
    if (_isIos) {
      await IosAlarmSoundPlayer.stop();
      return;
    }
    try {
      await _channel.invokeMethod<void>('stopNativeRinging');
    } catch (_) {}
  }

  Future<void> dismiss() async {
    await stopNativeRinging();
    if (_isIos) {
      Get.back();
      return;
    }
    try {
      await _channel.invokeMethod<void>('dismiss');
    } catch (_) {}
  }

  Future<void> snoozeFiveMinutes() async {
    if (!snoozeAllowed) return;
    await stopNativeRinging();
    if (_isIos) {
      final current = payload.value;
      if (current != null) {
        await IosEventAlarmNotifications.scheduleSnooze(
          current,
          DateTime.now().add(const Duration(minutes: 5)),
        );
      }
      Get.back();
      return;
    }
    try {
      await _channel.invokeMethod<void>('snoozeFiveMinutes');
    } catch (_) {}
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _policyTimer?.cancel();
    if (_isIos) {
      IosAlarmSoundPlayer.stop();
    }
    super.onClose();
  }
}
