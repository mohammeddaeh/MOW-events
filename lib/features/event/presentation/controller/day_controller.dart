import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/helpers/event_day_list_helper.dart';

class DayController extends GetxController {
  static const int pageSize = 10;
  final HomeController home = Get.find();
  RxList<EventModel> events = <EventModel>[].obs;
  final RxInt visibleCount = pageSize.obs;
  Worker? _eventsWorker;

  @override
  void onInit() {
    super.onInit();
    _eventsWorker = ever<List<EventModel>>(home.processedEvents, (_) {
      _updateEvents();
    });

    if (home.processedEvents.isNotEmpty) {
      _updateEvents();
    }
  }

  void _updateEvents() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final previousVisibleCount = visibleCount.value;
    final nextEvents = home.processedEvents
        .where((e) => EventDayListHelper.eventOverlapsDay(e, start, end))
        .toList()
      ..sort(EventDayListHelper.compareForDayList);

    events.assignAll(nextEvents);
    visibleCount.value = nextEvents.isEmpty
        ? pageSize
        : math.min(math.max(previousVisibleCount, pageSize), nextEvents.length);
  }

  List<EventModel> get visibleEvents =>
      events.take(visibleCount.value).toList(growable: false);

  bool get canLoadMore => visibleCount.value < events.length;

  void loadMore() {
    visibleCount.value = math.min(visibleCount.value + pageSize, events.length);
  }

  void scrollToTop(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void onClose() {
    _eventsWorker?.dispose();
    super.onClose();
  }
}
