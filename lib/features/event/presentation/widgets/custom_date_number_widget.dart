import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';

class CustomDateNumberWidget extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isInMonth;
  final double dayGSize;
  final double dayHSize;
  final bool showGregorian;
  final bool showHijri;
  final int? hijriDay;

  const CustomDateNumberWidget({
    super.key,
    required this.date,
    this.isToday = false,
    this.isInMonth = true,
    this.dayGSize = 14,
    this.dayHSize = 10,
    this.showGregorian = true,
    this.showHijri = false,
    this.hijriDay,
  });

  @override
  Widget build(BuildContext context) {
    final type = DateLocalizationHelper.userCalendar.value;
    final model = DateLocalizationHelper.display(date);

    final gregorianColor = isInMonth
        ? Colors.black
        : AppThemeHelper.whiteBlack(context);

    final hijriColor = isInMonth
        ? AppThemeHelper.gold(context)
        : AppThemeHelper.grey(context);

    Widget dayWidget;

    switch (type) {
      case 'both':
        dayWidget = Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  model.hDay,
                  style: TextStyle(
                    fontSize: dayHSize,
                    fontWeight: FontWeight.w600,
                    color: hijriColor,
                  ),
                ),
                SizedBox(width: 6),
              ],
            ),
            Text(
              model.gDay,
              style: TextStyle(
                fontSize: dayGSize,
                fontWeight: FontWeight.w600,
                color: gregorianColor,
              ),
            ),
          ],
        );
        break;

      case 'hijri':
        dayWidget = Text(
          model.hDay,
          style: TextStyle(
            fontSize: dayHSize,
            fontWeight: FontWeight.w800,
            color: hijriColor,
          ),
        );
        break;

      default:
        dayWidget = Text(
          model.gDay,
          style: TextStyle(
            fontSize: dayGSize,
            fontWeight: FontWeight.w800,
            color: gregorianColor,
          ),
        );
    }

    return dayWidget;
  }
}
