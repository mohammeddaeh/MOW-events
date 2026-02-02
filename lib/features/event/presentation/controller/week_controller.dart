import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:table_calendar/table_calendar.dart' as DateUtils;
import 'home_controller.dart';

class WeekController extends GetxController {
  final HomeController home = Get.find();

  RxList<DateTime> weekDays = <DateTime>[].obs;
  RxMap<String, List<EventModel>> groupedEvents =
      <String, List<EventModel>>{}.obs;
  var selectedIndex = 0.obs;
  var currentWeekDays = <DateTime>[].obs;
  var dragOffset = 0.0.obs;
  Timer? _midnightTimer;

  @override
  void onInit() {
    super.onInit();
    _generateWeek();
    _scheduleMidnightUpdate();

    ever(home.processedEvents, (_) => _groupEvents());

    if (home.processedEvents.isNotEmpty) {
      _groupEvents();
    }
  }

  void _generateWeek() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    weekDays.value = List.generate(7, (i) => startOfDay.add(Duration(days: i)));
    currentWeekDays.value = weekDays;
  }

  void _groupEvents() {
    final map = <String, List<EventModel>>{};

    for (final day in weekDays) {
      final dayEvents = home.processedEvents.where((e) {
        final dt = e.startDateTimeSafe;
        if (dt == null) return false;
        return DateUtils.isSameDay(dt, day);
      }).toList();

      map[DateFormat('yyyy-MM-dd').format(day)] = dayEvents;
    }

    groupedEvents.assignAll(map);
  }

  void updateSelectedDay(int index) {
    selectedIndex.value = index;
  }

  void updateDrag(double delta, bool isRTL) {
    dragOffset.value += (isRTL ? -1 : 1) * delta;
  }

  int endDrag(double itemWidth) {
    final movedIndex = (dragOffset.value / itemWidth).round();
    dragOffset.value = 0;
    final newIndex = (selectedIndex.value + movedIndex)
        .clamp(0, currentWeekDays.length - 1)
        .toInt();
    selectedIndex.value = newIndex;
    return newIndex;
  }

  double calculateAlignmentX(int index, bool isRTL) {
    double alignmentX = -1 + (index / 3);
    if (isRTL) alignmentX = 1 - (index / 3);
    return alignmentX;
  }

  double calculateDragAlignment(
    double alignmentX,
    double itemWidth,
    bool isRTL,
  ) {
    final offsetRatio = dragOffset.value / itemWidth / 3;
    double newX = alignmentX + (isRTL ? -offsetRatio : offsetRatio);
    return newX.clamp(-1.0, 1.0);
  }

  void _scheduleMidnightUpdate() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);

    final duration = nextMidnight.difference(now);

    _midnightTimer = Timer(duration, () {
      _generateWeek();
      _groupEvents();
      selectedIndex.value = 0;

      _scheduleMidnightUpdate();
    });
  }

  @override
  void onClose() {
    _midnightTimer?.cancel();
    super.onClose();
  }
}
