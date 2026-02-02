import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

class YearController extends GetxController {
  final HomeController home = Get.find();
  RxInt currentYear = DateTime.now().year.obs;
  RxList<EventModel> events = <EventModel>[].obs;
  RxInt currentHijriYear = DateTime.now().year.obs;

  @override
  void onInit() {
    super.onInit();
    everAll([home.processedEvents, currentYear], (_) => _loadYearEvents());
    if (home.processedEvents.isNotEmpty) {
      _loadYearEvents();
    }
  }

  void _loadYearEvents() {
    final start = DateTime(currentYear.value, 1, 1);
    final end = DateTime(currentYear.value + 1, 1, 1);

    final yearEvents = home.processedEvents.where((e) {
      final dt = e.startDateTimeSafe;
      if (dt == null) return false;
      return dt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    events.assignAll(yearEvents);
  }

  List<EventModel> getEventsForMonth(DateTime month) {
    return events.where((e) {
      final dt = e.startDateTimeSafe;
      if (dt == null) return false;
      return dt.year == month.year && dt.month == month.month;
    }).toList();
  }

  bool hasEventOnDay(DateTime day) {
    return events.any((e) {
      final dt = e.startDateTimeSafe;
      if (dt == null) return false;
      return DateUtils.isSameDay(dt, day);
    });
  }

  int countEventsOnDay(DateTime day) {
    return events.where((e) {
      final dt = e.startDateTimeSafe;
      if (dt == null) return false;
      return DateUtils.isSameDay(dt, day);
    }).length;
  }

  void nextYear() => currentYear.value++;
  void previousYear() => currentYear.value--;
  List<DateTime> get yearMonths {
    if (DateLocalizationHelper.userCalendar.value == 'hijri') {
      return List.generate(12, (index) {
        final hMonth = index + 1;
        final firstDayG = HijriCalendar().hijriToGregorian(
          currentHijriYear.value,
          hMonth,
          1,
        );
        return firstDayG;
      });
    } else {
      final year = currentYear.value;
      return List.generate(12, (index) => DateTime(year, index + 1, 1));
    }
  }
}
