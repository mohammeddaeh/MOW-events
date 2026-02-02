import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/features/event/presentation/controller/week_controller.dart';
import 'package:mow_events/features/event/presentation/widgets/weekly_sliding_bar.dart';

class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WeekController>();

    return WeeklyDaySlider(controller: controller);
  }
}
