// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/calendar_grid_view.dart';
import 'package:mow_events/core/shared/widgets/calendar_header.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/monthly_controller.dart';
import 'package:mow_events/features/event/presentation/widgets/card_event.dart';
import 'package:mow_events/features/event/presentation/widgets/day_side_toast.dart';

class MonthScreen extends StatelessWidget {
  MonthScreen({super.key});
  OverlayEntry? _currentToast;
  final ValueNotifier<double> _toastOffsetX = ValueNotifier(0.0);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MonthlyController>();
    final homeController = Get.find<HomeController>();

    return SizedBox.expand(
      child: Column(
        children: [
          Obx(() {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: controller.goToPreviousMonth,
                ),
                Expanded(
                  child: CalendarHeader(
                    showYearWithMonth: true,
                    scale: 12,
                    date: controller.currentMonth.value,
                    userCalendar: DateLocalizationHelper.userCalendar.value,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: controller.goToNextMonth,
                ),
              ],
            );
          }),

          const SizedBox(height: 10),
          Obx(() {
            final month = controller.currentMonth.value;
            final firstDay = DateTime(month.year, month.month, 1);
            final lastDay = DateTime(month.year, month.month + 1, 0);

            final startWeekday = firstDay.weekday % 7;

            final totalCells = startWeekday + lastDay.day;

            final totalWeeks = (totalCells / 7).ceil();

            final dayHeight = 50.0;

            final calendarHeight = totalWeeks * dayHeight + 30;

            return SizedBox(
              height: calendarHeight,
              child: UniversalCalendarGrid(
                month: month,
                selectedDay: controller.selectedDay.value,
                mode: CalendarMode.month,
                showWeekHeader: true,
                hasEvents: controller.hasTasks,
                eventCount: controller.getTasksCount,
                onDayTap: (day) {
                  controller.selectDay(day);

                  final display = DateLocalizationHelper.display(day);

                  showDayToast(context, display);
                },
              ),
            );
          }),

          Expanded(
            flex: 1,
            child: Obx(() {
              if (controller.selectedDayTasks.isEmpty) {
                return Center(child: Text(AppTexts.noEventsThisMonth));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(
                  bottom: 20,
                  right: 6,
                  left: 6,
                  top: 8,
                ),
                itemCount: controller.selectedDayTasks.length,
                itemBuilder: (_, i) {
                  final e = controller.selectedDayTasks[i];
                  return CardEvent(event: e, homeController: homeController);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void showDayToast(BuildContext context, dynamic display) {
    _currentToast?.remove();
    _currentToast = null;
    _toastOffsetX.value = 0;

    final overlay = OverlayEntry(
      builder: (_) {
        final screenWidth = MediaQuery.of(context).size.width;

        return ValueListenableBuilder<double>(
          valueListenable: _toastOffsetX,
          builder: (_, offsetX, __) {
            return Stack(
              children: [
                Positioned.fill(child: IgnorePointer()),

                Positioned(
                  top: MediaQuery.of(context).size.height * 0.12,
                  right: Directionality.of(context) == TextDirection.rtl
                      ? 10
                      : null,
                  left: Directionality.of(context) == TextDirection.ltr
                      ? 10
                      : null,

                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      _toastOffsetX.value += details.delta.dx;
                    },
                    onHorizontalDragEnd: (_) {
                      if (_toastOffsetX.value.abs() > screenWidth * 0.25) {
                        _currentToast?.remove();
                        _currentToast = null;
                      } else {
                        _toastOffsetX.value = 0;
                      }
                    },
                    child: Transform.translate(
                      offset: Offset(offsetX, 0),
                      child: DaySideToast(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTexts.todaySDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${AppTexts.gregorian}: ${display.gDay} ${display.gMonth} ${display.gYear}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              '${AppTexts.hijri}: ${display.hDay} ${display.hMonth} ${display.hYear}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    _currentToast = overlay;
    Overlay.of(context).insert(overlay);

    Future.delayed(const Duration(seconds: 3), () {
      if (_currentToast == overlay) {
        overlay.remove();
        _currentToast = null;
      }
    });
  }
}
