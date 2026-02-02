import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'date_localization_helper.dart';

class AppDateText extends StatelessWidget {
  final DateTime date;
  final TextStyle? style;
  final bool showMonthName;
  final bool showYearSuffix;
  final bool showTime;
  final bool useArabicNames;

  const AppDateText({
    super.key,
    required this.date,
    this.style,
    this.showMonthName = true,
    this.showYearSuffix = true,
    this.showTime = false,
    this.useArabicNames = true,
  });

  @override
  Widget build(BuildContext context) {
    final display = _buildDisplay(date);
    return Text(display, style: style);
  }

  String _buildDisplay(DateTime date) {
    final type = DateLocalizationHelper.userCalendar.value;
    String day, month, year;

    switch (type) {
      case 'hijri':
        day = DateLocalizationHelper.hDay(date);
        month = showMonthName
            ? (useArabicNames
                  ? DateLocalizationHelper
                        .hijriMonthsAr[DateLocalizationHelper.toHijri(
                          date,
                        ).hMonth -
                        1]
                  : DateLocalizationHelper
                        .hijriMonthsEn[DateLocalizationHelper.toHijri(
                          date,
                        ).hMonth -
                        1])
            : DateLocalizationHelper.toHijri(
                date,
              ).hMonth.toString().padLeft(2, '0');
        year = showYearSuffix
            ? '${DateLocalizationHelper.hYear(date)} ${AppTexts.h}'
            : DateLocalizationHelper.hYear(date);
        break;

      case 'both':
        final gDay = DateLocalizationHelper.gDay(date);
        final gMonth = showMonthName
            ? (useArabicNames
                  ? DateLocalizationHelper.gregorianMonthsAr[date.month - 1]
                  : DateFormat('MMMM').format(date))
            : date.month.toString().padLeft(2, '0');
        final gYear = showYearSuffix
            ? '${DateLocalizationHelper.gYear(date)} م'
            : DateLocalizationHelper.gYear(date);

        final hDay = DateLocalizationHelper.hDay(date);
        final hMonth = showMonthName
            ? (useArabicNames
                  ? DateLocalizationHelper
                        .hijriMonthsAr[DateLocalizationHelper.toHijri(
                          date,
                        ).hMonth -
                        1]
                  : DateLocalizationHelper
                        .hijriMonthsEn[DateLocalizationHelper.toHijri(
                          date,
                        ).hMonth -
                        1])
            : DateLocalizationHelper.toHijri(
                date,
              ).hMonth.toString().padLeft(2, '0');
        final hYear = showYearSuffix
            ? '${DateLocalizationHelper.hYear(date)} هـ'
            : DateLocalizationHelper.hYear(date);

        day = '$gDay / $hDay';
        month = '$gMonth / $hMonth';
        year = '$gYear / $hYear';
        break;

      default:
        day = DateLocalizationHelper.gDay(date);
        month = showMonthName
            ? (useArabicNames
                  ? DateLocalizationHelper.gregorianMonthsAr[date.month - 1]
                  : DateFormat('MMMM').format(date))
            : date.month.toString().padLeft(2, '0');
        year = showYearSuffix
            ? '${DateLocalizationHelper.gYear(date)} ${AppTexts.m}'
            : DateLocalizationHelper.gYear(date);
    }

    final time = showTime ? ' ${DateFormat('HH:mm').format(date)}' : '';
    return '$day / $month / $year$time';
  }
}
