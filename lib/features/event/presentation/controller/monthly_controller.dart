import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/helpers/event_day_list_helper.dart';

class MonthlyController extends GetxController {
  static const int pageSize = 10;
  final HomeController home = Get.find();
  var currentMonth = DateTime.now().obs;
  var selectedDay = Rxn<DateTime>();
  RxMap<String, List<EventModel>> groupedEvents =
      <String, List<EventModel>>{}.obs;
  RxList<EventModel> selectedDayTasks = <EventModel>[].obs;
  final RxInt visibleCount = pageSize.obs;
  final RxDouble toastHorizontalOffset = 0.0.obs;

  OverlayEntry? _toastOverlayEntry;
  Timer? _toastDismissTimer;
  int _toastVersion = 0;
  Worker? _eventsWorker;

  @override
  void onInit() {
    super.onInit();
    _eventsWorker = everAll([home.processedEvents, currentMonth], (_) {
      _groupMonthlyEvents();
    });
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
      selectDay(selectedDay.value!, preserveVisibleCount: true);
    } else if (groupedEvents.isNotEmpty) {
      final firstKey = groupedEvents.keys.first;
      selectDay(DateFormat('yyyy-MM-dd').parse(firstKey));
    } else {
      selectedDayTasks.clear();
      visibleCount.value = pageSize;
    }
  }

  void selectDay(DateTime day, {bool preserveVisibleCount = false}) {
    final previousVisibleCount = visibleCount.value;
    selectedDay.value = day;
    final key = DateFormat('yyyy-MM-dd').format(day);
    final list = List<EventModel>.from(groupedEvents[key] ?? [])
      ..sort(EventDayListHelper.compareForDayList);
    selectedDayTasks.assignAll(list);
    if (!preserveVisibleCount) {
      visibleCount.value = pageSize;
      return;
    }

    visibleCount.value = selectedDayTasks.isEmpty
        ? pageSize
        : math.min(
            math.max(previousVisibleCount, pageSize),
            selectedDayTasks.length,
          );
  }

  List<EventModel> get visibleSelectedDayTasks =>
      selectedDayTasks.take(visibleCount.value).toList(growable: false);

  bool get canLoadMoreSelectedDayTasks =>
      visibleCount.value < selectedDayTasks.length;

  void loadMoreSelectedDayTasks() {
    visibleCount.value = math.min(
      visibleCount.value + pageSize,
      selectedDayTasks.length,
    );
  }

  bool hasTasks(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return groupedEvents.containsKey(key) && groupedEvents[key]!.isNotEmpty;
  }

  int getTasksCount(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return groupedEvents[key]?.length ?? 0;
  }

  List<EventModel> eventsOnDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return groupedEvents[key] ?? const [];
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

  void showSideToast({
    required WidgetBuilder toastBuilder,
    Duration duration = const Duration(seconds: 3),
    double topFactor = 0.12,
  }) {
    final overlayContext = Get.overlayContext;
    if (overlayContext == null) return;

    final overlay = Overlay.maybeOf(overlayContext, rootOverlay: true);
    if (overlay == null) return;

    dismissToast();
    toastHorizontalOffset.value = 0;
    final toastVersion = ++_toastVersion;

    _toastOverlayEntry = OverlayEntry(
      builder: (_) {
        final mediaQuery = MediaQuery.of(overlayContext);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final textDirection = Directionality.of(overlayContext);

        return Obx(() {
          return Stack(
            children: [
              const Positioned.fill(child: IgnorePointer()),
              Positioned(
                top: screenHeight * topFactor,
                right: textDirection == ui.TextDirection.rtl ? 10 : null,
                left: textDirection == ui.TextDirection.ltr ? 10 : null,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    toastHorizontalOffset.value += details.delta.dx;
                  },
                  onHorizontalDragEnd: (_) {
                    if (toastHorizontalOffset.value.abs() >
                        screenWidth * 0.25) {
                      if (_toastVersion == toastVersion) {
                        dismissToast();
                      }
                    } else {
                      toastHorizontalOffset.value = 0;
                    }
                  },
                  child: Transform.translate(
                    offset: Offset(toastHorizontalOffset.value, 0),
                    child: Builder(builder: toastBuilder),
                  ),
                ),
              ),
            ],
          );
        });
      },
    );

    overlay.insert(_toastOverlayEntry!);

    _toastDismissTimer = Timer(duration, () {
      if (_toastVersion == toastVersion) {
        dismissToast();
      }
    });
  }

  void dismissToast() {
    _toastDismissTimer?.cancel();
    _toastDismissTimer = null;

    _toastOverlayEntry?.remove();
    _toastOverlayEntry = null;

    toastHorizontalOffset.value = 0;
  }

  @override
  void onClose() {
    _eventsWorker?.dispose();
    dismissToast();
    super.onClose();
  }
}
