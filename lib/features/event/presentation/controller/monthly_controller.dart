import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

class MonthlyController extends GetxController {
  final HomeController home = Get.find();
  var currentMonth = DateTime.now().obs;
  var selectedDay = Rxn<DateTime>();
  RxMap<String, List<EventModel>> groupedEvents =
      <String, List<EventModel>>{}.obs;
  RxList<EventModel> selectedDayTasks = <EventModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    everAll([home.processedEvents, currentMonth], (_) => _groupMonthlyEvents());
    if (home.processedEvents.isNotEmpty) {
      _groupMonthlyEvents();
    }
  }

  void _groupMonthlyEvents() {
    final start = DateTime(
      currentMonth.value.year,
      currentMonth.value.month,
      1,
    );
    final end = DateTime(
      currentMonth.value.year,
      currentMonth.value.month + 1,
      1,
    );

    final monthEvents = home.processedEvents.where((e) {
      final dt = e.startDateTimeSafe;
      if (dt == null) return false;
      return dt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    final map = <String, List<EventModel>>{};
    for (var e in monthEvents) {
      final key = DateFormat('yyyy-MM-dd').format(e.startDateTimeSafe!);
      map.putIfAbsent(key, () => []).add(e);
    }
    groupedEvents.assignAll(map);
    if (selectedDay.value != null) {
      selectDay(selectedDay.value!);
    } else if (groupedEvents.isNotEmpty) {
      final firstKey = groupedEvents.keys.first;
      selectDay(DateFormat('yyyy-MM-dd').parse(firstKey));
    } else {
      selectedDayTasks.clear();
    }
  }

  void selectDay(DateTime day) {
    selectedDay.value = day;
    final key = DateFormat('yyyy-MM-dd').format(day);
    selectedDayTasks.assignAll(groupedEvents[key] ?? []);
  }

  bool hasTasks(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return groupedEvents.containsKey(key) && groupedEvents[key]!.isNotEmpty;
  }

  int getTasksCount(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return groupedEvents[key]?.length ?? 0;
  }

  void goToPreviousMonth() {
    currentMonth.value = DateTime(
      currentMonth.value.year,
      currentMonth.value.month - 1,
    );
    selectedDay.value = null;
    selectedDayTasks.clear();
    _groupMonthlyEvents();
  }

  void goToNextMonth() {
    currentMonth.value = DateTime(
      currentMonth.value.year,
      currentMonth.value.month + 1,
    );
    selectedDay.value = null;
    selectedDayTasks.clear();
    _groupMonthlyEvents();
  }
}
