import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// يمنع إرسال نفس توكن FCM أكثر من مرة للباكند خلال نفس جلسة التطبيق.
/// التوكن يُعاد إرساله مرة عند كل تشغيل: لو فقده الباك (حذف، تسجيل دخول بنفس
/// الحساب على جهاز آخر...) يرجع الجهاز يستقبل الإشعارات بدل أن يبقى صامتاً للأبد.
class FcmTokenSyncGuard {
  FcmTokenSyncGuard._();

  /// مفتاح قديم كان يحفظ التوكن بشكل دائم — يُمسح فقط عند الخروج.
  static const String _storageKey = 'fcm_last_synced_token';

  static String? _lastSyncedToken;

  static String? get lastSyncedToken => _lastSyncedToken;

  /// يُسلسل كل محاولات الإرسال لتفادي سباقات async المتزامنة.
  static Future<void> _queue = Future.value();

  static void reset() {
    _lastSyncedToken = null;
    GetStorage().remove(_storageKey);
    _queue = Future.value();
  }

  /// توكن الجهاز لإرساله مع طلب الخروج. يُفضَّل المُرسَل في هذه الجلسة لأن
  /// [FirebaseMessaging.getToken] قد يتعلق إذا كانت خوادم Google محجوبة.
  static Future<String?> currentDeviceToken() async {
    if (_lastSyncedToken != null) return _lastSyncedToken;
    try {
      return await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      return null;
    }
  }

  /// عند الخروج: حذف التوكن من Firebase (ليُولَّد توكن جديد للحساب التالي) وتصفير الحالة.
  static Future<void> clearDeviceToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {}
    reset();
  }

  /// يرسل التوكن مرة واحدة لكل قيمة؛ الاستدعاءات المتزامنة تنتظر دورها.
  static Future<bool> pushIfNeeded(
    Future<void> Function(String token) send,
    String token, {
    bool force = false,
    String? debugContext,
  }) {
    final completer = Completer<bool>();

    _queue = _queue.then((_) async {
      try {
        completer.complete(
          await _pushOnce(
            send,
            token,
            force: force,
            debugContext: debugContext,
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[FCM][set-token][error] $debugContext: $e');
        }
        completer.complete(false);
      }
    });

    return completer.future;
  }

  static Future<bool> _pushOnce(
    Future<void> Function(String token) send,
    String token, {
    required bool force,
    String? debugContext,
  }) async {
    if (!force && token == lastSyncedToken) {
      if (kDebugMode && debugContext != null) {
        debugPrint('[FCM][set-token][skip] $debugContext (already synced)');
      }
      return true;
    }

    if (kDebugMode && debugContext != null) {
      debugPrint('[FCM][set-token][send] $debugContext');
    }

    await send(token);
    _lastSyncedToken = token;
    return true;
  }
}
