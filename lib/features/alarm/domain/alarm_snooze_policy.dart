import 'package:flutter/foundation.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';

/// سياسة التأجيل الذكية: زر/سحب التأجيل يظهر فقط إذا بقي على بداية الحدث
/// مدة لا تقل عن [kSnoozeDuration] (افتراضي 5 دقائق).
@immutable
class AlarmSnoozePolicy {
  const AlarmSnoozePolicy._();

  static const Duration kSnoozeDuration = Duration(minutes: 5);

  /// يُسمح بالتأجيل لمدة [kSnoozeDuration] فقط إذا كان وقت الحدث بعد
  /// `now + kSnoozeDuration`.
  static bool checkIfSnoozeAllowed({
    required DateTime eventStart,
    required DateTime now,
  }) {
    if (!eventStart.isAfter(now)) return false;
    return eventStart.difference(now) >= kSnoozeDuration;
  }
}

/// ربط مع [EventModel] — نفس شرط بداية الحدث [EventModel.startDateTimeSafe].
extension EventModelAlarmSnooze on EventModel {
  bool isSnoozeAllowedAt(DateTime now) {
    final start = startDateTimeSafe;
    if (start == null) return false;
    return AlarmSnoozePolicy.checkIfSnoozeAllowed(eventStart: start, now: now);
  }
}
