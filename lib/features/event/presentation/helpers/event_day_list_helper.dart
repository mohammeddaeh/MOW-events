import 'package:flutter/material.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/helpers/event_display_helper.dart';
import 'package:mow_events/features/event/presentation/widgets/card_event.dart';

enum EventDayTimeline { ended, upcoming, ongoing }

class EventDayListHelper {
  EventDayListHelper._();

  static bool eventOverlapsDay(
    EventModel e,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    final sd = e.startDateTimeSafe;
    final ed = EventDisplayHelper.effectiveEndDateTime(e);
    if (sd == null || ed == null) return false;
    return sd.isBefore(dayEnd) && ed.isAfter(dayStart);
  }

  static EventDayTimeline classify(EventModel e) {
    final now = DateTime.now();
    final start = e.startDateTimeSafe;
    final end = EventDisplayHelper.effectiveEndDateTime(e);
    if (start == null || end == null) return EventDayTimeline.ongoing;
    if (end.isBefore(now)) return EventDayTimeline.ended;
    if (start.isAfter(now)) return EventDayTimeline.upcoming;
    return EventDayTimeline.ongoing;
  }

  static bool spansMultipleCalendarDays(EventModel e) {
    final s = e.startDateTimeSafe;
    final ed = EventDisplayHelper.effectiveEndDateTime(e);
    if (s == null || ed == null) return false;
    return s.year != ed.year || s.month != ed.month || s.day != ed.day;
  }

  static int _order(EventDayTimeline t) => switch (t) {
    EventDayTimeline.ongoing => 0,
    EventDayTimeline.upcoming => 1,
    EventDayTimeline.ended => 2,
  };

  static int compareForDayList(EventModel a, EventModel b) {
    final oa = _order(classify(a));
    final ob = _order(classify(b));
    if (oa != ob) return oa.compareTo(ob);
    final sa = a.startDateTimeSafe;
    final sb = b.startDateTimeSafe;
    if (sa == null && sb == null) return 0;
    if (sa == null) return 1;
    if (sb == null) return -1;
    return sa.compareTo(sb);
  }

  /// ترتيب زمني بحت حسب وقت البداية (لنقاط الأحداث في التقويم).
  static int compareByStart(EventModel a, EventModel b) {
    final sa = a.startDateTimeSafe;
    final sb = b.startDateTimeSafe;
    if (sa == null && sb == null) return 0;
    if (sa == null) return 1;
    if (sb == null) return -1;
    return sa.compareTo(sb);
  }

  /// ألوان نقاط أحداث اليوم مرتبة حسب وقت البداية.
  static List<Color> dotColorsByStart(List<EventModel> events) => ([
    ...events,
  ]..sort(compareByStart)).map(CardEvent.categoryColorForEvent).toList();
}
