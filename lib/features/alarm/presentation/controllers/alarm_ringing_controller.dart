import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
  }

  Future<void> _loadPayload() async {
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
    try {
      await _channel.invokeMethod<void>('stopNativeRinging');
    } catch (_) {}
  }

  Future<void> dismiss() async {
    await stopNativeRinging();
    try {
      await _channel.invokeMethod<void>('dismiss');
    } catch (_) {}
  }

  Future<void> snoozeFiveMinutes() async {
    if (!snoozeAllowed) return;
    await stopNativeRinging();
    try {
      await _channel.invokeMethod<void>('snoozeFiveMinutes');
    } catch (_) {}
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _policyTimer?.cancel();
    super.onClose();
  }
}
