import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/home_controller.dart';
import 'package:mow_events/features/event/presentation/controller/week_controller.dart';
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
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.buttonDisabled.withAlpha(150),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Obx(() {
                      final weekDaysList = controller.weekDays;
                      return Row(
                        children: List.generate(weekDaysList.length, (index) {
                          final day = weekDaysList[index];
                          final isSelected =
                              index == controller.selectedIndex.value;
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
                                          ? AppColors.gold
                                          : AppThemeHelper.whiteBlack(context),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: isSelected ? 1 : 0,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.gold,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
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
                          child: Center(
                            child: Text(
                              AppTexts.noEventsThisMonth,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return CardEvent(
                          key: ValueKey(event.id),
                          event: event,
                          homeController: homeController,
                        );
                      },
                    ),
            );
          }),
        ),
      ],
    );
  }
}
