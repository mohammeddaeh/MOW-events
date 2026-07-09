import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

class YearController extends GetxController {
  final HomeController home = Get.find();
  RxInt currentYear = DateTime.now().year.obs;
  RxList<EventModel> events = <EventModel>[].obs;

  final RxMap<String, List<EventModel>> eventsByDay =
      <String, List<EventModel>>{}.obs;
  RxInt currentHijriYear = HijriCalendar.now().hYear.obs;
  Worker? _yearWorker;

  @override
  void onInit() {
    super.onInit();
    _yearWorker = everAll(
      [home.processedEvents, currentYear, DateLocalizationHelper.userCalendar],
      (_) {
        if (DateLocalizationHelper.userCalendar.value == 'hijri') {
          final todayHijri = HijriCalendar.now();
          currentHijriYear.value = todayHijri.hYear;
        }
        _loadYearEvents();
      },
    );
    if (home.processedEvents.isNotEmpty) {
      _loadYearEvents();
    }
  }

  @override
  void onClose() {
    _yearWorker?.dispose();
    super.onClose();
  }

  void _loadYearEvents() {
    final yearEvents = home.processedEvents.where((e) {
      final dt = e.startDateTimeSafe;
      if (dt == null) return false;

      if (DateLocalizationHelper.userCalendar.value == 'hijri') {
        return DateLocalizationHelper.toHijri(dt).hYear ==
            currentHijriYear.value;
      }

      return dt.year == currentYear.value;
    }).toList();

    events.assignAll(yearEvents);

    final groupedByDay = <String, List<EventModel>>{};
    for (final e in yearEvents) {
      final dt = e.startDateTimeSafe;
      if (dt == null) continue;
      final key = _dayKey(dt);
      groupedByDay.putIfAbsent(key, () => []).add(e);
    }
    eventsByDay.assignAll(groupedByDay);
  }

  List<EventModel> getEventsForMonth(DateTime month) {
    if (DateLocalizationHelper.userCalendar.value == 'hijri') {
      final selectedHijriMonth = DateLocalizationHelper.toHijri(month);

      return events.where((e) {
        final dt = e.startDateTimeSafe;
        if (dt == null) return false;

        final eventHijriDate = DateLocalizationHelper.toHijri(dt);
        return eventHijriDate.hYear == selectedHijriMonth.hYear &&
            eventHijriDate.hMonth == selectedHijriMonth.hMonth;
      }).toList();
    }

    return events.where((e) {
      final dt = e.startDateTimeSafe;
      if (dt == null) return false;
      return dt.year == month.year && dt.month == month.month;
    }).toList();
  }

  bool hasEventOnDay(DateTime day) {
    return eventsByDay[_dayKey(day)]?.isNotEmpty ?? false;
  }

  int countEventsOnDay(DateTime day) {
    return eventsByDay[_dayKey(day)]?.length ?? 0;
  }

  String _dayKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  void nextYear() {
    if (DateLocalizationHelper.userCalendar.value == 'hijri') {
      if (currentHijriYear.value < 1500) {
        currentHijriYear.value++;
        final gDate = HijriCalendar().hijriToGregorian(
          currentHijriYear.value,
          1,
          1,
        );
        currentYear.value = gDate.year;
      }
    } else {
      currentYear.value++;
    }
  }

  void previousYear() {
    if (DateLocalizationHelper.userCalendar.value == 'hijri') {
      if (currentHijriYear.value > 1356) {
        currentHijriYear.value--;
        final gDate = HijriCalendar().hijriToGregorian(
          currentHijriYear.value,
          1,
          1,
        );
        currentYear.value = gDate.year;
      }
    } else {
      currentYear.value--;
    }
  }

  List<DateTime> get yearMonths {
    if (DateLocalizationHelper.userCalendar.value == 'hijri') {
      final hYear = currentHijriYear.value;
      return List.generate(12, (i) {
        final hMonth = i + 1;
        try {
          return HijriCalendar().hijriToGregorian(hYear, hMonth, 1);
        } catch (_) {
          return DateTime.now();
        }
      });
    } else {
      final year = currentYear.value;
      return List.generate(12, (index) => DateTime(year, index + 1, 1));
    }
  }
}
