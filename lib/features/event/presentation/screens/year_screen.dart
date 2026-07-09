import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/core/shared/widgets/calendar_grid_view.dart';
import 'package:mow_events/core/shared/widgets/calendar_header.dart';
import 'package:mow_events/core/shared/widgets/month_events_bottom_sheet.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/event/presentation/controller/year_controller.dart';
import 'package:mow_events/features/event/presentation/widgets/card_event.dart';

class YearScreen extends StatelessWidget {
  YearScreen({super.key});

  final YearController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final months = controller.yearMonths;
        controller.eventsByDay.entries.toList(growable: false);
        final isRTL = DateLocalizationHelper.isArabic;

        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            children: [
              _buildYearSelector(controller, context),
              SizedBox(height: 8.h),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1,
                  ),
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final month = controller.yearMonths[index];

                    return UniversalCalendarGrid(
                      month: month,
                      mode: CalendarMode.year,
                      isYearMode: true,
                      showMonthHeader: true,
                      showWeekHeader: true,

                      hasEvents: controller.hasEventOnDay,
                      eventCount: controller.countEventsOnDay,

                      onMonthTap: (selectedMonth) {
                        final monthEvents = controller.getEventsForMonth(
                          selectedMonth,
                        );

                        if (monthEvents.isNotEmpty) {
                          _showMonthEventsBottomSheet(
                            context,
                            selectedMonth,
                            DateLocalizationHelper.display(
                              selectedMonth,
                            ).displayMonth,
                          );
                        } else {
                          if (Get.isSnackbarOpen) return;

                          Get.snackbar(
                            AppTexts.noEvents,
                            AppTexts.noEventsThisMonth,
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildYearSelector(YearController controller, BuildContext context) {
    final isRTL = DateLocalizationHelper.isArabic;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navButton(
              icon: Icons.chevron_left,
              onTap: controller.previousYear,
              context: context,
            ),

            CalendarHeader(
              date: DateTime(controller.currentYear.value, 1, 1),
              userCalendar: DateLocalizationHelper.userCalendar.value,
              scale: 16,
              showYear: true,
              vertical: false,
            ),

            _navButton(
              icon: Icons.chevron_right,
              onTap: controller.nextYear,
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthEventsBottomSheet(
    BuildContext context,
    DateTime month,
    String monthTitle,
  ) {
    if (Get.isBottomSheetOpen ?? false) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => MonthEventsBottomSheet(
        monthTitle: monthTitle,
        month: month,
        onEventTap: (event) {
          CardEvent.showEventDetailsSheet(context, event, controller.home);
        },
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        width: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.buttonDisabled),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppThemeHelper.whiteBlack(context), size: 22),
      ),
    );
  }
}
