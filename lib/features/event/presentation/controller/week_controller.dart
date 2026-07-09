import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/helpers/event_day_list_helper.dart';

import 'home_controller.dart';

class WeekController extends GetxController {
  static const int pageSize = 10;
  final HomeController home = Get.find();

  RxList<DateTime> weekDays = <DateTime>[].obs;
  RxMap<String, List<EventModel>> groupedEvents =
      <String, List<EventModel>>{}.obs;
  var selectedIndex = 0.obs;
  var currentWeekDays = <DateTime>[].obs;
  var dragOffset = 0.0.obs;
  final RxInt visibleCount = pageSize.obs;
  Timer? _midnightTimer;
  Worker? _eventsWorker;

  @override
  void onInit() {
    super.onInit();
    _generateWeek();
    _scheduleMidnightUpdate();

    _eventsWorker = ever<List<EventModel>>(home.processedEvents, (_) {
      _groupEvents();
    });

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
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayEvents = home.processedEvents
          .where((e) => EventDayListHelper.eventOverlapsDay(e, dayStart, dayEnd))
          .toList()
        ..sort(EventDayListHelper.compareForDayList);

      map[DateFormat('yyyy-MM-dd').format(day)] = dayEvents;
    }

    groupedEvents.assignAll(map);
    final selectedTotal = _selectedDayTotalCount;
    visibleCount.value = selectedTotal == 0
        ? pageSize
        : math.min(math.max(visibleCount.value, pageSize), selectedTotal);
  }

  void updateSelectedDay(int index) {
    selectedIndex.value = index;
    visibleCount.value = pageSize;
  }

  int get _selectedDayTotalCount {
    if (weekDays.isEmpty) return 0;
    final safeIndex = selectedIndex.value.clamp(0, weekDays.length - 1);
    final day = weekDays[safeIndex];
    final key = DateFormat('yyyy-MM-dd').format(day);
    return groupedEvents[key]?.length ?? 0;
  }

  List<EventModel> get selectedDayEvents {
    if (weekDays.isEmpty) return const <EventModel>[];
    final day = weekDays[selectedIndex.value];
    final key = DateFormat('yyyy-MM-dd').format(day);
    final events = groupedEvents[key] ?? const <EventModel>[];
    return events.take(visibleCount.value).toList(growable: false);
  }

  bool get canLoadMoreSelectedDayEvents {
    if (weekDays.isEmpty) return false;
    final day = weekDays[selectedIndex.value];
    final key = DateFormat('yyyy-MM-dd').format(day);
    return visibleCount.value < (groupedEvents[key]?.length ?? 0);
  }

  void loadMoreSelectedDayEvents() {
    if (weekDays.isEmpty) return;
    final day = weekDays[selectedIndex.value];
    final key = DateFormat('yyyy-MM-dd').format(day);
    final total = groupedEvents[key]?.length ?? 0;
    visibleCount.value = math.min(visibleCount.value + pageSize, total);
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
      visibleCount.value = pageSize;

      _scheduleMidnightUpdate();
    });
  }

  @override
  void onClose() {
    _eventsWorker?.dispose();
    _midnightTimer?.cancel();
    super.onClose();
  }
}
