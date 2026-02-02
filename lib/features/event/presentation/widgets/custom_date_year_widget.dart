import 'package:flutter/material.dart';
import 'package:mow_events/core/utils/constants/app_colors.dart';
import 'package:mow_events/core/utils/constants/app_size.dart';
import 'package:mow_events/core/utils/helpers/app_theme_helper.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';

class CustomDateYear extends StatelessWidget {
  final DateTime date;
  final bool vertical;

  const CustomDateYear({required this.date, this.vertical = false, super.key});

  @override
  Widget build(BuildContext context) {
    final type = DateLocalizationHelper.userCalendar.value;

    if (vertical) {
      final parts = DateLocalizationHelper.verticalMonthYear(date);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            parts[0],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.whiteBlack(context),
            ),
          ),
          Text(
            parts[1],
            style: TextStyle(fontSize: 14, color: AppColors.textGray),
          ),
        ],
      );
    } else {
      List<Widget> columns = [];

      if (type != 'hijri') {
        columns.add(
          Column(
            children: [
              Text(
                '${DateLocalizationHelper.gYear(date)} م',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppThemeHelper.whiteBlack(context),
                ),
              ),
            ],
          ),
        );
      }

      if (type == 'both') columns.add(SizedBox(width: 16.w));

      if (type != 'gregorian') {
        columns.add(
          Column(
            children: [
              Text(
                '${DateLocalizationHelper.hYear(date)} هـ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppThemeHelper.whiteBlack(context),
                ),
              ),
            ],
          ),
        );
      }

      return Row(children: columns);
    }
  }
}
