import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:mow_events/core/shared/widgets/calendar_header.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';

enum CalendarMode { month, year }

class UniversalCalendarGrid extends StatelessWidget {
  final DateTime month;
  final bool showMonthHeader;
  final bool showWeekHeader;
  final bool Function(DateTime day)? hasEvents;
  final int Function(DateTime day)? eventCount;
  final DateTime? selectedDay;
  final bool isYearMode;
  final CalendarMode mode;
  final Function(DateTime day)? onDayTap;
  final Function(DateTime month)? onMonthTap;

  const UniversalCalendarGrid({
    super.key,
    required this.month,
    this.showMonthHeader = false,
    this.showWeekHeader = false,
    this.hasEvents,
    this.eventCount,
    this.selectedDay,
    this.isYearMode = false,
    required this.mode,
    this.onDayTap,
    this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    final userCalendar = DateLocalizationHelper.userCalendar.value;

    late List<DateTime> days;

    if (userCalendar == 'hijri') {
      days = DateLocalizationHelper.generateHijriMonthGrid(
        DateLocalizationHelper.toHijri(month).hYear,
        DateLocalizationHelper.toHijri(month).hMonth,
      );
    } else if (userCalendar == 'both') {
      days = DateLocalizationHelper.generateMonthDays(month);
    } else {
      days = DateLocalizationHelper.generateMonthDays(month);
    }

    final weekDays = DateLocalizationHelper.getWeekDaysName();

    final hijriRange =
        DateLocalizationHelper.getHijriMonthsRangeForGregorianMonth(month);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        final scale = isYearMode ? (cellWidth * 0.33) : (cellWidth * 0.45);

        final fontDay = scale * 0.7;
        final fontHijri = scale * 0.35;
        final todayCircle = scale * 1.1;
        final eventDot = scale * 0.2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showMonthHeader)
              GestureDetector(
                onTap: () {
                  if (mode == CalendarMode.year) {
                    onMonthTap?.call(month);
                  }
                },
                child: _buildMonthHeader(hijriRange, scale, userCalendar),
              ),

            if (showWeekHeader)
              Padding(
                padding: EdgeInsets.only(bottom: scale * 0.2),
                child: Row(
                  children: weekDays
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: fontDay * 0.8,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            Flexible(
              fit: FlexFit.tight,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: isYearMode ? 5 : 4,
                  crossAxisSpacing: isYearMode ? 3 : 4,
                  childAspectRatio: isYearMode ? 1.1 : 1,
                ),
                itemCount: days.length,
                itemBuilder: (_, index) {
                  final day = days[index];

                  final isInMonth = DateLocalizationHelper.isInSameMonth(
                    day,
                    month,
                  );

                  if (!isInMonth) {
                    return Container();
                  }

                  return Obx(() {
                    final hasEv = hasEvents?.call(day) ?? false;
                    final evCount = eventCount?.call(day) ?? 0;
                    final today = DateLocalizationHelper.today.value;
                    final isToday = DateUtils.isSameDay(day, today);
                    final isSelected =
                        selectedDay != null &&
                        DateUtils.isSameDay(day, selectedDay);

                    return GestureDetector(
                      onTap: () {
                        if (mode == CalendarMode.month) {
                          onDayTap?.call(day);
                        } else if (mode == CalendarMode.year) {
                          onMonthTap?.call(month);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(scale * 0.35),
                          border: isSelected
                              ? Border.all(color: Colors.amber, width: 1.5)
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isToday)
                              Container(
                                width: todayCircle,
                                height: todayCircle,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    todayCircle / 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.7),
                                      blurRadius: 8,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),

                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildDayDisplay(
                                  day,
                                  fontDay,
                                  fontHijri,
                                  isYearMode,
                                ),

                                if (hasEv)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Wrap(
                                      spacing: 2,
                                      alignment: WrapAlignment.center,
                                      children: List.generate(
                                        min(evCount, 3),
                                        (i) => Container(
                                          width: eventDot,
                                          height: eventDot,
                                          decoration: const BoxDecoration(
                                            color: Colors.amber,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayDisplay(
    DateTime day,
    double fontDay,
    double fontHijri,
    bool isYearMode,
  ) {
    final type = DateLocalizationHelper.userCalendar.value;

    if (type == 'both') {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                DateLocalizationHelper.hDay(day),
                style: TextStyle(
                  fontSize: isYearMode ? 4 : fontHijri,
                  color: Colors.grey,
                ),
              ),
              SizedBox(width: 4),
            ],
          ),
          SizedBox(height: 2),
          Text(
            DateLocalizationHelper.gDay(day),
            style: TextStyle(
              fontSize: isYearMode ? 7 : fontDay,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else if (type == 'hijri') {
      return Text(
        DateLocalizationHelper.hDay(day),
        style: TextStyle(
          fontSize: isYearMode ? 7 : fontDay,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        DateLocalizationHelper.gDay(day),
        style: TextStyle(
          fontSize: isYearMode ? 7 : fontDay,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  Widget _buildMonthHeader(
    List<int> hijriRange,
    double scale,
    String userCalendar,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: CalendarHeader(
        date: month,
        userCalendar: userCalendar,
        scale: scale,
        showYear: false,
        vertical: false,
      ),
    );
  }
}
