import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mow_events/core/utils/date_time/date_localization_helper.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

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
    return Text(_buildDisplay(), style: style);
  }

  String _buildDisplay() {
    final type = DateLocalizationHelper.userCalendar.value;
    final hijriDate = DateLocalizationHelper.toHijri(date);

    final gregorianMonth = showMonthName
        ? (useArabicNames
              ? DateLocalizationHelper.gMonth(date)
              : DateFormat('MMMM', 'en').format(date))
        : DateLocalizationHelper.localizeDigits(
            date.month.toString().padLeft(2, '0'),
          );

    final hijriMonth = showMonthName
        ? (useArabicNames
              ? DateLocalizationHelper.hMonth(date)
              : DateLocalizationHelper.hijriMonthsEn[hijriDate.hMonth - 1])
        : DateLocalizationHelper.localizeDigits(
            hijriDate.hMonth.toString().padLeft(2, '0'),
          );

    final gregorianYear = showYearSuffix
        ? '${DateLocalizationHelper.gYear(date)} ${AppTexts.m}'
        : DateLocalizationHelper.gYear(date);
    final hijriYear = showYearSuffix
        ? '${DateLocalizationHelper.hYear(date)} ${AppTexts.h}'
        : DateLocalizationHelper.hYear(date);

    late final String body;
    switch (type) {
      case 'hijri':
        body =
            '${DateLocalizationHelper.hDay(date)} / $hijriMonth / $hijriYear';
        break;
      case 'both':
        body =
            '${DateLocalizationHelper.gDay(date)} / ${DateLocalizationHelper.hDay(date)}'
            ' / $gregorianMonth / $hijriMonth'
            ' / $gregorianYear / $hijriYear';
        break;
      case 'gregorian':
      default:
        body =
            '${DateLocalizationHelper.gDay(date)} / $gregorianMonth / $gregorianYear';
        break;
    }

    if (!showTime) {
      return body;
    }

    return '$body ${DateLocalizationHelper.formatTime(date)}';
  }
}
