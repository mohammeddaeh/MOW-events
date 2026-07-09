import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// يمنع إرسال نفس توكن FCM أكثر من مرة للباكند.
/// يحفظ آخر توكن مُرسَل في التخزين الدائم لتجنب إعادة الإرسال عند إعادة تشغيل التطبيق.
class FcmTokenSyncGuard {
  FcmTokenSyncGuard._();

  static const String _storageKey = 'fcm_last_synced_token';

  static String? _lastSyncedToken;

  static String? get lastSyncedToken =>
      _lastSyncedToken ??= GetStorage().read<String>(_storageKey);

  /// يُسلسل كل محاولات الإرسال لتفادي سباقات async المتزامنة.
  static Future<void> _queue = Future.value();

  static void reset() {
    _lastSyncedToken = null;
    GetStorage().remove(_storageKey);
    _queue = Future.value();
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
      } catch (_) {
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
    await GetStorage().write(_storageKey, token);
    return true;
  }
}
