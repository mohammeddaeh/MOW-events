import 'package:mow_events/features/event/data/models/event_model.dart';

enum EventDayTimeline { ended, upcoming, ongoing }

class EventDayListHelper {
  EventDayListHelper._();

  static bool eventOverlapsDay(
    EventModel e,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    final sd = e.startDateTimeSafe;
    final ed = e.endDateTimeSafe;
    if (sd == null || ed == null) return false;
    return sd.isBefore(dayEnd) && ed.isAfter(dayStart);
  }

  static EventDayTimeline classify(EventModel e) {
    final now = DateTime.now();
    final start = e.startDateTimeSafe;
    final end = e.endDateTimeSafe;
    if (start == null || end == null) return EventDayTimeline.ongoing;
    if (end.isBefore(now)) return EventDayTimeline.ended;
    if (start.isAfter(now)) return EventDayTimeline.upcoming;
    return EventDayTimeline.ongoing;
  }

  static bool spansMultipleCalendarDays(EventModel e) {
    final s = e.startDateTimeSafe;
    final ed = e.endDateTimeSafe;
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
}
