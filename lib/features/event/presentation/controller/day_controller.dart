import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/features/event/data/models/event_model.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';

class DayController extends GetxController {
  final HomeController home = Get.find();
  RxList<EventModel> events = <EventModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    ever(home.processedEvents, (_) => _updateEvents());

    if (home.processedEvents.isNotEmpty) {
      _updateEvents();
    }
  }

  void _updateEvents() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    events.assignAll(
      home.processedEvents.where((e) {
        final sd = e.startDateTimeSafe;
        final ed = e.endDateTimeSafe;
        if (sd == null || ed == null) return false;
        return sd.isBefore(end) && ed.isAfter(start);
      }).toList(),
    );
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
}
