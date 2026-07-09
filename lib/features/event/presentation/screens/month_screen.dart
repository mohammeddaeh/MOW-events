import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/calendar_grid_view.dart';
import 'package:mow_events/core/shared/widgets/empty_state_widget.dart';
import 'package:mow_events/core/shared/widgets/pagination_footer.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/shared/widgets/calendar_header.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/monthly_controller.dart';
import 'package:mow_events/features/event/presentation/helpers/event_day_list_helper.dart';
import 'package:mow_events/features/event/presentation/widgets/card_event.dart';
import 'package:mow_events/features/event/presentation/widgets/day_side_toast.dart';

class MonthScreen extends StatelessWidget {
  const MonthScreen({super.key});

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
            controller.groupedEvents.entries.toList(growable: false);
            final days = DateLocalizationHelper.generateMonthDays(month);
            final totalCells = days.length;
            final totalWeeks = (totalCells / 7).ceil();
            final width = MediaQuery.sizeOf(context).width;
            DateLocalizationHelper.userCalendar.value;
            final cellSize = (width / 7).clamp(36.0, double.infinity);
            final weekHeaderHeight = cellSize * 0.7;
            final calendarHeight =
                (totalWeeks * cellSize) + weekHeaderHeight + 8;
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
                  controller.showSideToast(
                    toastBuilder: (ctx) => DaySideToast(
                      child: _MonthDayToastContent(display: display),
                    ),
                  );
                },
              ),
            );
          }),

          Expanded(
            flex: 1,
            child: Obx(() {
            if (controller.selectedDayTasks.isEmpty) {
              return EmptyStateWidget(
                lottieAsset: AppImages.noResult,
                title: AppTexts.noEventsThisDay,
              );
            }

            final visibleTasks = controller.visibleSelectedDayTasks;
            final shouldShowFooter = controller.selectedDayTasks.isNotEmpty;

            return ListView(
              padding: const EdgeInsets.only(
                bottom: 20,
                right: 6,
                left: 6,
                top: 8,
              ),
              children: [
                ...visibleTasks.map(
                  (event) => CardEvent(
                    event: event,
                    homeController: homeController,
                    config: EventCardConfig(
                      showMultiDaySpanHint:
                          EventDayListHelper.spansMultipleCalendarDays(event),
                    ),
                  ),
                ),
                if (shouldShowFooter)
                  PaginationFooter(
                    isLoadingMore: homeController.isLoadingMoreEvents.value,
                    hasMore:
                        controller.canLoadMoreSelectedDayTasks ||
                        homeController.hasMoreEvents.value,
                    actionLabel: AppTexts.viewmore,
                    loadingLabel: AppTexts.loadingMoreEvents,
                    completedLabel: AppTexts.allEventsLoaded,
                    onLoadMore: controller.canLoadMoreSelectedDayTasks
                        ? controller.loadMoreSelectedDayTasks
                        : homeController.loadMoreEvents,
                  ),
              ],
            );
          }),
        ),
        ],
      ),
    );
  }
}

class _MonthDayToastContent extends StatelessWidget {
  final DateDisplayModel display;

  const _MonthDayToastContent({required this.display});

  @override
  Widget build(BuildContext context) {
    final textColor = AppThemeHelper.whiteBlack(context);
    final baseStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal,
    );

    return DefaultTextStyle(
      style: baseStyle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTexts.todaySDate,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppTexts.gregorian.tr}: ${display.gDay} ${display.gMonth} ${display.gYear}',
          ),
          Text(
            '${AppTexts.hijri.tr}: ${display.hDay} ${display.hMonth} ${display.hYear}',
          ),
        ],
      ),
    );
  }
}
