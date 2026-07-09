import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';

/// سبب إخفاء أو تعطّل جزء من عرض الحدث (للتشخيص ومحاذاة العدّ مع البطاقات).
enum EventDisplayIssue {
  missingName,
  missingDescription,
  missingStartDateTime,
  missingEndDateTime,
}

class EventDisplayHelper {
  EventDisplayHelper._();

  static String displayName(EventModel event) {
    final name = event.name.trim();
    if (name.isNotEmpty) return name;
    return AppTexts.eventUntitled;
  }

  static String displayDescription(EventModel event) {
    final description = event.description.trim();
    if (description.isNotEmpty) return description;
    return AppTexts.eventNoDescription;
  }

  static bool canRenderCard(EventModel event) => true;

  /// البطاقة كانت تُخفى سابقاً عند غياب الاسم أو الوصف ([SizedBox.shrink]).
  static bool wasHiddenByLegacyCardGuard(EventModel event) {
    return event.name.trim().isEmpty || event.description.trim().isEmpty;
  }

  static List<EventDisplayIssue> diagnose(EventModel event) {
    final issues = <EventDisplayIssue>[];
    if (event.name.trim().isEmpty) {
      issues.add(EventDisplayIssue.missingName);
    }
    if (event.startDateTimeSafe == null) {
      issues.add(EventDisplayIssue.missingStartDateTime);
    }
    if (effectiveEndDateTime(event) == null) {
      issues.add(EventDisplayIssue.missingEndDateTime);
    }
    return issues;
  }

  static DateTime? effectiveEndDateTime(EventModel event) {
    final parsed = event.endDateTimeSafe;
    if (parsed != null) return parsed;

    final start = event.startDateTimeSafe;
    if (start == null) return null;

    return DateTime(start.year, start.month, start.day, 23, 59, 59);
  }

  static String issueLabel(EventDisplayIssue issue) {
    switch (issue) {
      case EventDisplayIssue.missingName:
        return AppTexts.eventIssueMissingName;
      case EventDisplayIssue.missingDescription:
        return AppTexts.eventIssueMissingDescription;
      case EventDisplayIssue.missingStartDateTime:
        return AppTexts.eventIssueMissingStartDate;
      case EventDisplayIssue.missingEndDateTime:
        return AppTexts.eventIssueMissingEndDate;
    }
  }

  /// أحداث تُحسب في النقاط/العدّ وتُعرض في القائمة (بعد إصلاح التواريخ).
  static List<EventModel> eventsVisibleInDayList(
    Iterable<EventModel> events,
    bool Function(EventModel e, DateTime dayStart, DateTime dayEnd) overlapsDay,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    return events.where((e) => overlapsDay(e, dayStart, dayEnd)).toList();
  }
}
