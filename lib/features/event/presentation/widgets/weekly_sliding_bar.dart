import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/core/shared/widgets/empty_state_widget.dart';
import 'package:mow_events/core/shared/widgets/event_day_dots.dart';
import 'package:mow_events/core/shared/widgets/pagination_footer.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_images.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/week_controller.dart';
import 'package:mow_events/features/event/presentation/helpers/event_day_list_helper.dart';
import 'package:mow_events/features/event/presentation/widgets/card_event.dart';
import 'package:mow_events/features/event/presentation/widgets/custom_date_number_widget.dart';

class WeeklyDaySlider extends StatefulWidget {
  final WeekController controller;

  const WeeklyDaySlider({super.key, required this.controller});

  @override
  State<WeeklyDaySlider> createState() => _WeeklyDaySliderState();
}

class _WeeklyDaySliderState extends State<WeeklyDaySlider> {
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 7;
    final isRTL = DateLocalizationHelper.isArabic;
    final homeController = Get.find<HomeController>();
    final isDark = AppThemeHelper.currentBrightness(context) == Brightness.dark;

    return Column(
      children: [
        Obx(() {
          final selectedIndex = controller.selectedIndex.value;
          final alignmentX = controller.calculateAlignmentX(
            selectedIndex,
            isRTL,
          );
          final dragAlignment = controller.calculateDragAlignment(
            alignmentX,
            itemWidth,
            isRTL,
          );

          return GestureDetector(
            onHorizontalDragStart: (_) => setState(() => isDragging = true),
            onHorizontalDragUpdate: (details) =>
                controller.updateDrag(details.primaryDelta ?? 0, isRTL),
            onHorizontalDragEnd: (_) {
              controller.endDrag(itemWidth);
              setState(() => isDragging = false);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedAlign(
                      duration: isDragging
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      alignment: Alignment(dragAlignment, 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: itemWidth,
                        height: 90,
                        decoration: BoxDecoration(
                          // كارد فاتح مخالف للخلفية في الوضعين، والنص فوقه
                          // داكن ويتبع موقعه أثناء السحب ليبقى مقروءاً.
                          // في الليلي أبيض مخفف، وفي النهاري رمادي فاتح ليتميز عن الأبيض
                          color: isDark
                              ? Color.alphaBlend(
                                  AppColors.white.withAlpha(215),
                                  AppColors.darkBottomBar,
                                )
                              : AppColors.grey,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withAlpha(
                                isDark ? 70 : 40,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Obx(() {
                      final weekDaysList = controller.weekDays;
                      controller.groupedEvents.entries.toList(growable: false);
                      // اليوم الواقع تحت الكارد الآن (يتغير أثناء السحب)
                      final highlightedIndex =
                          (controller.selectedIndex.value +
                                  (controller.dragOffset.value / itemWidth)
                                      .round())
                              .clamp(0, weekDaysList.length - 1);
                      return Row(
                        children: List.generate(weekDaysList.length, (index) {
                          final day = weekDaysList[index];
                          final isSelected = index == highlightedIndex;
                          final weekDayName =
                              DateLocalizationHelper.getWeekDaysName()[day
                                      .weekday %
                                  7];

                          return Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => controller.updateSelectedDay(index),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomDateNumberWidget(
                                    date: day,
                                    dayGSize: 12,
                                    dayHSize: 10,
                                    showGregorian: true,
                                    showHijri: true,
                                    hijriDay:
                                        int.tryParse(
                                          DateLocalizationHelper.hDay(day),
                                        ) ??
                                        0,
                                    isInMonth: isSelected,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    weekDayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.black
                                          : AppThemeHelper.whiteBlack(context),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Builder(
                                    builder: (context) {
                                      final formattedDay = DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(day);
                                      final dayEvents =
                                          controller
                                              .groupedEvents[formattedDay] ??
                                          const [];

                                      return AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        opacity: dayEvents.isNotEmpty ? 1 : 0,
                                        child: SizedBox(
                                          height: 16,
                                          child: Center(
                                            child: EventDayDots(
                                              colors:
                                                  EventDayListHelper.dotColorsByStart(
                                                    dayEvents,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        }),

        Expanded(
          child: Obx(() {
            if (controller.currentWeekDays.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final selectedDay =
                controller.weekDays[controller.selectedIndex.value];
            final formattedKey = DateFormat('yyyy-MM-dd').format(selectedDay);
            final events = controller.groupedEvents[formattedKey] ?? [];
            final visibleEvents = controller.selectedDayEvents;
            final shouldShowFooter = events.isNotEmpty;

            return RefreshIndicator(
              onRefresh: () async {
                await homeController.refreshAllEvents();
              },
              child: events.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: EmptyStateWidget(
                            lottieAsset: AppImages.noResult,
                            title: AppTexts.noEventsThisDay,
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      children: [
                        ...visibleEvents.map(
                          (event) => CardEvent(
                            key: ValueKey(event.id),
                            event: event,
                            homeController: homeController,
                            config: EventCardConfig(
                              showMultiDaySpanHint:
                                  EventDayListHelper.spansMultipleCalendarDays(
                                    event,
                                  ),
                            ),
                          ),
                        ),
                        if (shouldShowFooter)
                          PaginationFooter(
                            isLoadingMore:
                                homeController.isLoadingMoreEvents.value,
                            hasMore:
                                controller.canLoadMoreSelectedDayEvents ||
                                homeController.hasMoreEvents.value,
                            actionLabel: AppTexts.viewmore,
                            loadingLabel: AppTexts.loadingMoreEvents,
                            completedLabel: AppTexts.allEventsLoaded,
                            onLoadMore: controller.canLoadMoreSelectedDayEvents
                                ? controller.loadMoreSelectedDayEvents
                                : homeController.loadMoreEvents,
                          ),
                      ],
                    ),
            );
          }),
        ),
      ],
    );
  }
}
